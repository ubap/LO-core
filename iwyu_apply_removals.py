import re
import sys

if len(sys.argv) < 2:
    print("Usage: python3 only_remove.py <iwyu_log_file>")
    sys.exit(1)

log_path = sys.argv[1]
removals = {}
current_file = None

# 1. Parse the IWYU log to collect files and headers marked for removal
with open(log_path, "r", encoding="utf-8") as f:
    for line in f:
        match = re.match(r"^(.+) should remove these lines:$", line.strip())
        if match:
            current_file = match.group(1)
            removals.setdefault(current_file, set())
            continue

        if current_file and line.startswith("- #include "):
            # Extract the actual code (e.g., "#include <vcl/window.hxx>") and ignore line number comments
            inc_text = line[2:].split("//")[0].strip()

            if "com/sun/star/" in inc_text:
                print(f"SKIPPING UNO HEADER: {inc_text}")
                continue

            removals[current_file].add(inc_text)
        elif not line.startswith("- "):
            current_file = None

for filepath, includes in removals.items():
    if not includes:
        continue

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()

        with open(filepath, "w", encoding="utf-8") as f:
            for line in lines:
                if line.strip() in includes:
                    continue
                f.write(line)

        print(f"Cleaned: {filepath}")
    except FileNotFoundError:
        print(f"Skipped (not found): {filepath}")
