#!/usr/bin/env python3
"""
GDScript Manual Syntax Checker - BOMBERMAN GODOT
✅ Validates all GDScript files for common syntax errors
"""

import os
from pathlib import Path
from datetime import datetime

project_path = Path("projects/games/bomberman_godot")
gd_script_path = project_path / "scripts"

def check_gdscript_file(filepath: Path):
    """Check a single GDScript file for syntax issues"""
    issues = []
    warnings = []
    filename = filepath.name
    relative_path = filepath.relative_to(project_path)
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')
    except Exception as e:
        return [{"error": str(e)}], []
    
    if len(content) == 0:
        return [], [{"warning": "Empty file!"}]
    
    # Check 1: Class structure
    if 'extends ' not in content and 'class_name' not in content:
        issues.append("No 'extends' or 'class_name' found")
    
    # Check 2: Stub patterns
    if 'pass stub()' in content.lower():
        warnings.append(f"Found 'pass stub()' - template not implemented!")
    
    # Check 3: onready syntax
    for i, line in enumerate(lines, 1):
        if line.strip().startswith('@onready') and 'var' not in line:
            warnings.append(f"Line {i}: Possible malformed @onready in {filename}")
    
    # Check 4: if/elif/else patterns
    colons = content.count(':')
    if/elif_count = lines.count('if ') + lines.count('elif ') + lines.count('else:')
    if colons < if/elif_count:
        warnings.append("Possible missing colon in conditional")
    
    # Check 5: Common typos
    typos = {
        'hasnode': 'has_node',
        'CenterAligned': 'CenterAlignedLayoutContainer'
    }
    for typo in list(typos.keys()):
        if typo in content and len(typo) < 30:
            warnings.append(f"Possible typo: '{typo}' should be '{typos[typo]}'")
    
    # Check 6: Function patterns
    func_count = content.count('func ')
    var_count = content.count('var ')
    if/elif_count = content.count('if ') + content.count('elif ')
    
    if func_count > 0 and if/elif_count == 0:
        warnings.append("Functions found but no conditionals detected")
    
    # Check 7: Return statements
    if not 'return' in content and func_count > 3:
        warnings.append("Multiple functions without return statements?")
    
    return issues, warnings

def run_syntax_check():
    """Run syntax check on all GDScript files"""
    print("=" * 70)
    print("🔥 GDSCRIPT MANUAL SYNTAX CHECKER - BOMBERMAN GODOT")
    print("=" * 70)
    print(f"📍 Project Path: projects/games/bomberman_godot/")
    print(f"📋 Check Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    # Find all GDScript files
    gd_files = list(gd_script_path.rglob("*.gd"))
    
    if not gd_files:
        print("❌ No GDScript files found!")
        return
    
    print(f"💫 Checking {len(gd_files)} GDScript files...\n")
    
    all_results = []
    for filepath in sorted(gd_files):
        issues, warnings = check_gdscript_file(filepath)
        
        relative = filepath.relative_to(project_path)
        print(f"📄 {relative}")
        
        if issues:
            print("   ❌ ERRORS:")
            for issue in issues:
                print(f"      • {issue}")
            all_results.append({'file': str(relative), 'status': 'ERROR', 'issues': issues})
        else:
            print("   ✓ PASSED")
            all_results.append({'file': str(relative), 'status': 'OK', 'issues': []})
        
        if warnings:
            print("   ⚠️  WARNINGS:")
            for warning in warnings:
                print(f"      • {warning}")
        print()
    
    # Summary
    failed = len([r for r in all_results if r['status'] == 'ERROR'])
    warned = len([r for r in all_results if any('stub' in w.lower() for w in r.get('warnings', []))])
    
    print("=" * 70)
    print("📋 SYNTAX CHECK SUMMARY")
    print("=" * 70)
    print(f"Total files checked: {len(gd_files)}")
    print(f"❌ Files with errors: {failed}")
    print(f"⚠️  Files with warnings: {warned}")
    print(f"✅ Files passed: {len(gd_files) - failed}")
    print()
    
    if failed > 0:
        print("🚨 CRITICAL ERRORS - PLEASE FIX!")
    else:
        print("🎉 ALL FILES PASS SYNTAX CHECK!")
        print("\n✅ SYNTAX CHECK: 100% PASSED!")
    
    # Save report
    report_path = project_path / "SYNTAX_CHECK_REPORT.md"
    with open(report_path, 'w', encoding='utf-8') as f:
        f.write(f"# GDScript Syntax Check Report\n\n")
        f.write(f"**Generated:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
        f.write(f"## Summary\n- Files checked: {len(gd_files)}\n- Errors: {failed}\n- Warnings: {warned}\n\n")
        for result in all_results:
            f.write(f"### {result['file']}\n")
            f.write(f"Status: {result['status']}\n")
            if result['issues']:
                f.write(f"Issues:\n")
                for issue in result['issues']:
                    f.write(f"- {issue}\n")
            f.write("\n")
    
    print(f"📄 Report saved: {report_path}")
    print()
    print("=" * 70)

if __name__ == "__main__":
    run_syntax_check()
