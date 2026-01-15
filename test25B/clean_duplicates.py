import os
import shutil
from collections import defaultdict

# Konfiguration
TARGET_DIR = "." 
BACKUP_DIR = "Project_Backup_Duplicates"

def clean_duplicates():
    if not os.path.exists(BACKUP_DIR):
        os.makedirs(BACKUP_DIR)

    file_registry = defaultdict(list)
    
    for root, dirs, files in os.walk(TARGET_DIR):
        if ".xcodeproj" in root or ".git" in root or BACKUP_DIR in root:
            continue
            
        for filename in files:
            if filename.endswith(".swift") or filename.endswith(".py"):
                full_path = os.path.join(root, filename)
                file_registry[filename].append(full_path)

    print("--- Suche nach Dubletten läuft ---")
    
    found_any = False
    for filename, paths in file_registry.items():
        if len(paths) > 1:
            found_any = True
            print(f"\n⚠️ Dublette gefunden: {filename}")
            
            paths.sort(key=len)
            original = paths[0]
            duplicates = paths[1:]
            
            print(f"  [BEHALTE]: {original}")
            
            for dup in duplicates:
                print(f"  [VERSCHIEBE]: {dup}")
                dest = os.path.join(BACKUP_DIR, os.path.relpath(dup, TARGET_DIR))
                os.makedirs(os.path.dirname(dest), exist_ok=True)
                shutil.move(dup, dest)

    if not found_any:
        print("Keine doppelten Swift- oder Python-Dateien gefunden.")
    else:
        print(f"\n--- Fertig! Dubletten liegen jetzt in: {BACKUP_DIR} ---")

if __name__ == "__main__":
    clean_duplicates()
