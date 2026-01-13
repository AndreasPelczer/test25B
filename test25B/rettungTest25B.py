#!/usr/bin/env python3
import os
import re
import sys

# Patterns, die Xcode als "Editor placeholder" interpretiert
PLACEHOLDER_PATTERNS = [
    re.compile(r"<#.*?#>", re.DOTALL),      # <# ... #>
    re.compile(r"<#T##.*?#>"),              # <#T##...#>
    re.compile(r"<#\[#.*?#\]#>", re.DOTALL) # <#[ ... ]#>
]

# Dateitypen, die wir scannen (Swift + ggf. ObjC + config)
EXTS = {".swift", ".m", ".mm", ".h", ".hpp", ".cpp", ".c", ".xcconfig"}

def should_skip_dir(path: str) -> bool:
    # DerivedData/Build/Pods/SourcePackages etc. nicht anfassen
    skip = ["DerivedData", ".build", "Build", "Pods", "Carthage", "SourcePackages", ".git"]
    return any(part in path.split(os.sep) for part in skip)

def scan_file(filepath: str):
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
    except Exception:
        return []

    hits = []
    for pat in PLACEHOLDER_PATTERNS:
        for m in pat.finditer(content):
            start = m.start()
            # Zeilennummer berechnen
            line_no = content.count("\n", 0, start) + 1
            snippet = m.group(0)
            # Snippet kürzen
            snippet_one_line = " ".join(snippet.split())
            if len(snippet_one_line) > 120:
                snippet_one_line = snippet_one_line[:117] + "..."
            hits.append((line_no, snippet_one_line))
    return hits

def main():
    root = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()

    all_hits = []
    for dirpath, dirnames, filenames in os.walk(root):
        if should_skip_dir(dirpath):
            continue
        for name in filenames:
            _, ext = os.path.splitext(name)
            if ext.lower() in EXTS:
                fp = os.path.join(dirpath, name)
                hits = scan_file(fp)
                for line_no, snippet in hits:
                    all_hits.append((fp, line_no, snippet))

    if not all_hits:
        print("✅ Keine Xcode-Placeholders (<#...#>) gefunden.")
        print("Wenn Xcode trotzdem 'Editor placeholder' meldet, ist oft eine generierte Datei (Core Data) kaputt.")
        return 0

    print("❌ GEFUNDENE PLACEHOLDERS (das sind Build-Killer):\n")
    for fp, line_no, snippet in sorted(all_hits):
        print(f"- {fp}:{line_no}\n  {snippet}\n")

    print(f"Summe Treffer: {len(all_hits)}")
    print("\n➡️ Behebe/entferne diese Stellen (oder kommentiere die betroffenen Blöcke) und baue neu.")
    return 1

if __name__ == "__main__":
    raise SystemExit(main())

