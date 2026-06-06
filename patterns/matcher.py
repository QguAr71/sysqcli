#!/usr/bin/env python3
"""SysQCLI Pattern Matcher v0.2 — dopasowuje dane diagnostyczne do wzorców YAML.
   v0.2: score w output, bonus za multi-hit, obsługa CONTEXT:"""
import yaml
import sys
import os

def load_patterns(path):
    with open(path) as f:
        return yaml.safe_load(f)['patterns']

def match_patterns(patterns, failed_services, coredump_exes, errors, signal_info):
    """Score each pattern. Returns best match or None. Threshold=4."""
    best = None
    best_score = 0
    
    for p in patterns:
        score = 0
        triggers = p.get('triggers', {})
        
        # Service match (per service)
        svc_count = 0
        for svc in triggers.get('services', []):
            for f in failed_services:
                if svc in f:
                    svc_count += 1
        score += svc_count * 5
        
        # Executable match in coredumps
        exe_count = 0
        for exe in triggers.get('executables', []):
            for c in coredump_exes:
                if exe in c:
                    exe_count += 1
        score += exe_count * 4
        
        # Signal match
        sig = triggers.get('signal', '')
        if sig and sig in signal_info:
            score += 3
        
        # Error message contains
        err_count = 0
        for err in triggers.get('error_contains', []):
            if err.lower() in errors.lower():
                err_count += 1
        score += err_count * 3
        
        # Multi-hit bonus: +2 per extra match type beyond first
        match_types = sum(1 for x in [svc_count, exe_count, 1 if sig and sig in signal_info else 0, err_count] if x > 0)
        if match_types >= 2:
            score += (match_types - 1) * 2
        
        if score > best_score:
            best_score = score
            best = p
            # Attach score for output
            best['_score'] = score
    
    return best if best_score >= 4 else None

def format_output(pattern):
    """Output pattern data in bash-friendly KEY:VALUE format."""
    fields = {
        'ID': pattern['id'],
        'SCORE': str(pattern.get('_score', 0)),
        'NAME': pattern['name'],
        'CATEGORY': pattern.get('category', 'system'),
        'CONFIDENCE': pattern.get('confidence', 'community'),
        'EXPLANATION': pattern['explanation'].strip(),
        'IMPACT': pattern.get('impact', '').strip(),
        'ACTION': pattern['recommended_action'].strip(),
        'RISK': pattern.get('risk', 'low'),
        'ROLLBACK': pattern.get('rollback', '').strip(),
        'ALT': pattern.get('alternative', '').strip(),
    }
    
    for k, v in fields.items():
        val = ' '.join(v.split()) if v else ''
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
        if context:
            print(f'CONTEXT_KERNEL:{context.get("kernel", "?")}')
            print(f'CONTEXT_DESKTOP:{context.get("desktop", "?")}')
            print(f'CONTEXT_SESSION:{context.get("session", "?")}')
            print(f'CONTEXT_GPU:{context.get("gpu", "?")}')
        print('NO_MATCH')
