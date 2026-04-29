#!/bin/bash

# --- CONFIGURATION ---
MODULE="sw"                          # Module to compile
DIRECTORY="sw/qa"                # Directory to process
SDK_PATH=$(xcrun --show-sdk-path)    # xcode sdk path
LOG_FAILURES="../iwyu_failures.log"

echo "Starting removal of unused imports in: $DIRECTORY"

# process .cxx files line by line
find "$DIRECTORY" -type f -name "*.cxx" | while read -r FILE; do
    echo "=================================================="
    echo "⚙️  Processing: $FILE"

    iwyu_tool.py -p . "$FILE" -- -isysroot "$SDK_PATH" > iwyu.out

    python3 iwyu_apply_removals.py iwyu.out

    if git diff --quiet "$FILE"; then
        echo "⏭️  No changes, continue."
        continue
    fi

    echo "🔨 Building $MODULE..."
    make "$MODULE".check gb_CppunitTest_GDBTRACE="true" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "✅ SUCCESS: make succeeded."
        git add .
        git commit --no-verify -m "IWYU: clean up includes in $FILE and related headers"
    else
        echo "❌ ERROR: make failed after changing: $FILE"
        echo "$FILE" >> "$LOG_FAILURES"
        git reset --hard HEAD
        make "$MODULE"
    fi
done

echo "=================================================="
echo "🎉 Finished!"
