import os
import re

def verify_pbx_paths():
    with open('Leaf.xcodeproj/project.pbxproj', 'r', encoding='utf-8') as f:
        pbx = f.read()

    # Extract PBXGroup section
    group_sec = re.search(r'/\* Begin PBXGroup section \*/(.*?)/\* End PBXGroup section \*/', pbx, re.DOTALL).group(1)
    # Extract PBXFileReference section
    fileref_sec = re.search(r'/\* Begin PBXFileReference section \*/(.*?)/\* End PBXFileReference section \*/', pbx, re.DOTALL).group(1)

    # Parse PBXFileReference entries
    filerefs = {}
    for line in fileref_sec.strip().splitlines():
        line = line.strip()
        if not line: continue
        m = re.match(r'(\d{4})\s*/\*\s*(.*?)\s*\*/\s*=\s*\{(.*)\};', line)
        if m:
            fid = m.group(1)
            fname = m.group(2)
            body = m.group(3)
            pm = re.search(r'path\s*=\s*"?([^";]+)"?;', body)
            fpath = pm.group(1).strip() if pm else fname
            filerefs[fid] = {'name': fname, 'path': fpath}

    # Parse PBXGroup entries
    groups = {}
    # Groups are formatted as:
    # GID /* Name */ = { ... };
    # or GID = { ... };
    group_entries = re.findall(r'(\d{4})(?:\s*/\*\s*(.*?)\s*\*/)?\s*=\s*\{(.*?)\};', group_sec, re.DOTALL)
    for gid, gname, body in group_entries:
        pm = re.search(r'path\s*=\s*"?([^";]+)"?;', body)
        gpath = pm.group(1).strip() if pm else ''
        cm = re.search(r'children\s*=\s*\((.*?)\);', body, re.DOTALL)
        children = []
        if cm:
            children = re.findall(r'(\d{4})', cm.group(1))
        groups[gid] = {'name': gname, 'path': gpath, 'children': children}

    print(f"Parsed {len(groups)} PBXGroups and {len(filerefs)} PBXFileReferences.")

    failures = []
    successes = []

    def trace(gid, current_path):
        g = groups.get(gid)
        if not g:
            return
        p = os.path.normpath(os.path.join(current_path, g['path'])) if g['path'] else current_path
        for cid in g['children']:
            if cid in groups:
                trace(cid, p)
            elif cid in filerefs:
                f = filerefs[cid]
                # Products are built artifacts, not source files
                if f['name'].endswith('.app') or f['name'].endswith('.xctest'):
                    continue
                full = os.path.normpath(os.path.join(p, f['path']))
                if not os.path.exists(full):
                    failures.append((cid, f['name'], full))
                else:
                    successes.append((cid, f['name'], full))

    trace('5001', '.')

    print(f"Verified {len(successes)} source and resource files.")
    for cid, name, full in successes:
        print(f"  ✓ [{cid}] {name} -> {full}")
    if failures:
        print(f"FAILED ({len(failures)} files not found on disk):")
        for cid, name, path in failures:
            print(f"  ✗ [{cid}] {name} -> {path}")
        return False
    else:
        print("✓ 100% of project file references resolved to valid existing files on disk!")
        return True

if __name__ == '__main__':
    verify_pbx_paths()
