#!/bin/bash

# --- KONFIGURACJA ---
MODULE="sw"                         # Moduł, który kompilujesz (dla make)
DIRECTORY="sw/source/core/docnode"     # Katalog, który chcesz wyczyścić
SDK_PATH=$(xcrun --show-sdk-path)       # Ścieżka do SDK na Macu
CLANG_FORMAT="/Users/jtrzebiatowski/Downloads/clang+llvm-5.0.0-x86_64-apple-darwin/bin/clang-format"
GIT_CLANG_FORMAT="python3 /Users/jtrzebiatowski/Downloads/clang+llvm-5.0.0-x86_64-apple-darwin/bin/git-clang-format"
LOG_FAILURES="../iwyu_failures.log"

echo "Rozpoczynam masowe czyszczenie w katalogu: $DIRECTORY"

# Znajdź wszystkie pliki .cxx i przetwarzaj je linijka po linijce
find "$DIRECTORY" -type f -name "*.cxx" | while read -r FILE; do
    echo "=================================================="
    echo "⚙️  Przetwarzanie: $FILE"

    # 1. Generowanie logu IWYU dla pojedynczego pliku
    iwyu_tool.py -p . "$FILE" -- -isysroot "$SDK_PATH" > iwyu.out

    # 2. Uruchomienie naszego "chirurga"
    python3 only_remove.py iwyu.out

    # Sprawdzamy, czy plik faktycznie uległ zmianie w Gicie.
    # Jeśli nie było zmian, szkoda czasu na kompilację, przechodzimy do następnego pliku.
    if git diff --quiet "$FILE"; then
        echo "⏭️  Brak zmian."
        continue
    fi

    # 3. Kompilacja modułu
    echo "🔨 Budowanie modułu $MODULE..."
    make "$MODULE"

    # 4. Sprawdzenie statusu kompilacji
    if [ $? -eq 0 ]; then
        echo "✅ SUKCES: Kompilacja przeszła."
        git add .
        git commit -m "IWYU: clean up includes in $FILE and related headers"
    else
        echo "❌ BŁĄD: Kompilacja nie powiodła się po modyfikacji: $FILE"
        echo "$FILE" >> "$LOG_FAILURES"
        git reset --hard HEAD
        make "$MODULE"
    fi
done

echo "=================================================="
echo "🎉 Zakończono pomyślnie cały katalog!"
