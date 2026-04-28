import re
import sys

if len(sys.argv) < 2:
    print("Użycie: python3 only_remove.py <plik_z_logiem_iwyu>")
    sys.exit(1)

log_path = sys.argv[1]
removals = {}
current_file = None

# 1. Parsowanie logu IWYU, żeby zebrać pliki i nagłówki do usunięcia
with open(log_path, "r", encoding="utf-8") as f:
    for line in f:
        # Szukamy nagłówka dla pliku
        match = re.match(r"^(.+) should remove these lines:$", line.strip())
        if match:
            current_file = match.group(1)
            removals.setdefault(current_file, set())
            continue

        # Jeśli jesteśmy w sekcji usuwania i linia zaczyna się od "- #include"
        if current_file and line.startswith("- #include "):
            # Wycinamy sam kod, np. "#include <vcl/window.hxx>", ignorujemy komentarz z numerem linii
            inc_text = line[2:].split("//")[0].strip()
            removals[current_file].add(inc_text)
        elif not line.startswith("- "):
            # Koniec sekcji usuwania dla tego pliku
            current_file = None

# 2. Chirurgiczne usuwanie linii z plików docelowych
for filepath, includes in removals.items():
    if not includes:
        continue

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()

        with open(filepath, "w", encoding="utf-8") as f:
            for line in lines:
                # Jeśli wyczyszczona z białych znaków linia to nasz include - pomijamy ją (usuwamy)
                if line.strip() in includes:
                    continue
                # W przeciwnym wypadku zapisujemy linię dokładnie tak, jak była (w tym puste linie)
                f.write(line)

        print(f"Wyczyszczono: {filepath}")
    except FileNotFoundError:
        print(f"Pominięto (nie znaleziono): {filepath}")
