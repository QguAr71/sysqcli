#!/usr/bin/env python3
"""SysQCLI Pattern Matcher v1.0 — dopasowuje dane diagnostyczne do wzorców YAML.
   Scoring: service+5, exe+4, signal+3, error+3, multi-hit bonus+2, threshold=4."""
import yaml
import sys
import os
import subprocess

def _has_evidence(triggers):
    """A pattern has honest evidence if it provides either:
       - verify.command (read-only check of current state), or
       - journal_evidence.command (read-only check of a log trace)."""
    verify = triggers.get('verify', {})
    journal = triggers.get('journal_evidence', {})
    return bool(verify.get('command')) or bool(journal.get('command'))


def load_patterns(path):
    with open(path) as f:
        patterns = yaml.safe_load(f)['patterns']
    # Enforce honest 'certified': requires evidence (verify OR journal_evidence)
    # + references. Patterns without evidence are downgraded to 'community'
    # (graceful — never refuses to start, I-18).
    for p in patterns:
        if p.get('confidence') == 'certified':
            triggers = p.get('triggers', {})
            if not (_has_evidence(triggers) and bool(p.get('references'))):
                p['_downgraded'] = True
                p['confidence'] = 'community'
    return patterns

def _run_readonly(cmd, timeout=5):
    """Run a read-only verification command. Returns True on exit code 0.
       Refuses anything that mutates system state. Never raises."""
    # Read-only guard: refuse anything that mutates system state.
    for blacklist in ('sudo', 'rm ', 'mv ', 'cp ', 'dd ', 'mkfs', 'pacman ', 'systemctl restart',
                      'systemctl enable', 'systemctl disable', 'systemctl mask', 'systemctl unmask',
                      '>', '>>'):
        if blacklist in cmd:
            return False
    try:
        return subprocess.run(cmd, shell=True, stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL, timeout=timeout).returncode == 0
    except Exception:
        return False


def verify_pattern(triggers):
    """Run triggers.verify.command (read-only) if present.
       Exit code 0 = hypothesis confirmed (pattern may win).
       Non-zero or any error = hypothesis refuted (pattern rejected).
       No verify field = legacy behavior (always passes, backward-compatible)."""
    verify = triggers.get('verify')
    if not verify:
        return True
    cmd = verify.get('command', '')
    if not cmd:
        return False
    return _run_readonly(cmd)


def verify_journal_evidence(triggers):
    """Run triggers.journal_evidence.command (read-only) if present.
       Used for historical/event patterns (OOM, suspend hang, session freeze)
       where the evidence is a trace in the journal, not a current state.
       Exit code 0 = trace found (hypothesis confirmed).
       Non-zero / no output = trace absent (hypothesis refuted).
       No journal_evidence field = always passes (backward-compatible)."""
    journal = triggers.get('journal_evidence')
    if not journal:
        return True
    cmd = journal.get('command', '')
    if not cmd:
        return False
    return _run_readonly(cmd)

def match_patterns(patterns, failed_services, coredump_exes, errors, signal_info):
    """Score each pattern. Returns best match or None. Threshold=4."""
    best = None
    best_score = 0
    
    for p in patterns:
        triggers = p.get('triggers', {})
        
        # Verify gate: run BEFORE scoring. A refuted hypothesis is hard-rejected,
        # regardless of how well the substring triggers match.
        if not verify_pattern(triggers):
            continue
        if not verify_journal_evidence(triggers):
            continue
        
        score = 0
        
        # Service match (per service)
        svc_count = 0
        matched_svcs = []
        for svc in triggers.get('services', []):
            for f in failed_services:
                if svc in f:
                    svc_count += 1
                    matched_svcs.append(svc)
        score += svc_count * 5
        
        # Executable match in coredumps
        exe_count = 0
        matched_exes = []
        for exe in triggers.get('executables', []):
            for c in coredump_exes:
                if exe in c:
                    exe_count += 1
                    matched_exes.append(exe)
        score += exe_count * 4
        
        # Signal match
        sig = triggers.get('signal', '')
        matched_sig = ''
        if sig and sig in signal_info:
            score += 3
            matched_sig = sig
        
        # Error message contains
        err_count = 0
        matched_errs = []
        for err in triggers.get('error_contains', []):
            if err.lower() in errors.lower():
                err_count += 1
                matched_errs.append(err)
        score += err_count * 3
        
        # Multi-hit bonus: +2 per extra match type beyond first
        match_types = sum(1 for x in [svc_count, exe_count, 1 if sig and sig in signal_info else 0, err_count] if x > 0)
        if match_types >= 2:
            score += (match_types - 1) * 2
        
        if score > best_score:
            best_score = score
            best = p
            # Attach score + evidence for output ("why it won")
            best['_score'] = score
            best['_evidence'] = {
                'services': matched_svcs,
                'executables': matched_exes,
                'signal': matched_sig,
                'error_contains': matched_errs,
            }
    
    return best if best_score >= 4 else None

def format_output(pattern):
    """Output pattern data in bash-friendly KEY:VALUE format."""
    # Build human-readable evidence string ("why it won")
    ev = pattern.get('_evidence', {})
    parts = []
    if ev.get('services'):
        parts.append('services=' + ','.join(ev['services']))
    if ev.get('executables'):
        parts.append('executables=' + ','.join(ev['executables']))
    if ev.get('signal'):
        parts.append('signal=' + ev['signal'])
    if ev.get('error_contains'):
        parts.append('errors=' + ','.join(ev['error_contains']))
    evidence = '; '.join(parts) if parts else '-'

    fields = {

        'ID': pattern['id'],
        'SCORE': str(pattern.get('_score', 0)),
        'NAME': pattern['name'],
        'CATEGORY': pattern.get('category', 'system'),
        'CONFIDENCE': pattern.get('confidence', 'community'),
        'DOWNGRADED': '1' if pattern.get('_downgraded') else '0',
        'MATCHED_TRIGGERS': evidence,
        'EXPLANATION': pattern['explanation'].strip(),
        'IMPACT': pattern.get('impact', '').strip(),
        'ACTION': pattern['recommended_action'].strip(),
        'RISK': pattern.get('risk', 'low'),
        'ROLLBACK': pattern.get('rollback', '').strip(),
        'ALT': pattern.get('alternative', '').strip(),
    }
    
    for k, v in fields.items():
        val = ' '.join(v.split()) if v else '-'
        print(f'{k}:{val}')

if __name__ == '__main__':
    patterns_path = os.path.expanduser('~/.config/sysqcli/patterns/common.yaml')
    patterns = load_patterns(patterns_path)
    
    failed = []
    coredumps = []
    errors = ""
    signal_info = ""
    context = {}
    
    for line in sys.stdin:
        line = line.rstrip('\n')
        if line.startswith('FAILED:'):
            failed.append(line[7:])
        elif line.startswith('CORE:'):
            coredumps.append(line[5:])
        elif line.startswith('SIGNAL:'):
            signal_info += line[7:] + ' '
        elif line.startswith('ERRORS:'):
            errors = line[7:]
        elif line.startswith('CONTEXT:'):
            kv = line[8:].split('=', 1)
            if len(kv) == 2:
                context[kv[0]] = kv[1]
    
    match = match_patterns(patterns, failed, coredumps, errors, signal_info)
    
    if match:
        # Inject context into output (for --report use)
        if context:
            print(f'CONTEXT_KERNEL:{context.get("kernel", "?")}')
            print(f'CONTEXT_DESKTOP:{context.get("desktop", "?")}')
            print(f'CONTEXT_SESSION:{context.get("session", "?")}')
            print(f'CONTEXT_GPU:{context.get("gpu", "?")}')
            print(f'CONTEXT_UPTIME:{context.get("uptime", "?")}')
            print(f'CONTEXT_HOST:{context.get("host", "?")}')
        format_output(match)
    else:
        print('NO_MATCH')
