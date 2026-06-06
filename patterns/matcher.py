#!/usr/bin/env python3
"""SysQCLI Pattern Matcher — dopasowuje dane diagnostyczne do wzorców YAML."""
import yaml
import sys
import os
from pathlib import Path

def load_patterns(path):
    with open(path) as f:
        return yaml.safe_load(f)['patterns']

def match_patterns(patterns, failed_services, coredump_exes, errors, signal_info):
    """Score each pattern against collected diagnostic data. Returns best match or None."""
    best = None
    best_score = 0
    
    for p in patterns:
        score = 0
        triggers = p.get('triggers', {})
        
        # Service match (per service)
        for svc in triggers.get('services', []):
            if any(svc in f for f in failed_services):
                score += 5
        
        # Executable match in coredumps (per match)
        for exe in triggers.get('executables', []):
            for c in coredump_exes:
                if exe in c:
                    score += 4
        
        # Signal match
        sig = triggers.get('signal', '')
        if sig and sig in signal_info:
            score += 3
        
        # Error message contains (per match)
        for err in triggers.get('error_contains', []):
            if err.lower() in errors.lower():
                score += 3
        
        if score > best_score:
            best_score = score
            best = p
    
    return best if best_score >= 4 else None  # Min threshold

def format_output(pattern):
    """Output pattern data in bash-friendly KEY:VALUE format."""
    fields = {
        'ID': pattern['id'],
        'SCORE': '',
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
    
    # Flatten multi-line values
    for k, v in fields.items():
        val = ' '.join(v.split()) if v else ''
        print(f'{k}:{val}')

if __name__ == '__main__':
    patterns_path = os.path.expanduser('~/.config/sysqcli/patterns/common.yaml')
    patterns = load_patterns(patterns_path)
    
    # Read diagnostic data from stdin (one item per line, prefixed)
    failed = []
    coredumps = []
    errors = ""
    signal_info = ""
    
    for line in sys.stdin:
        line = line.rstrip('\n')
        if line.startswith('FAILED:'):
            failed.append(line[7:])
        elif line.startswith('CORE:'):
            coredumps.append(line[5:])
        elif line.startswith('ERRORS:'):
            errors = line[7:]
        elif line.startswith('SIGNAL:'):
            signal_info = line[7:]
    
    match = match_patterns(patterns, failed, coredumps, errors, signal_info)
    
    if match:
        format_output(match)
    else:
        print('NO_MATCH')
