#!/bin/bash
# Copyright (C) 2023  Daniel Breedeveld
# Please read LICENSE for terms and conditions.

# Run git submodule update to get the latest version of llama.cpp
echo "[AUB.AI] Updating git submodules..."
echo "[AUB.AI] Fetching the latest version of llama.cpp..."

# Navigate to root directory of the project
if [ ! -f "pubspec.yaml" ]; then
    echo "[AUB.AI] Sorry, this script only works when you are in the root directory of the project. Exiting..."
    exit 1
fi

# Update 'llama.cpp' submodule
cd src/llama.cpp || exit
git pull origin master
git checkout master
cd ../..

# Update 'sherpa-onnx' submodule
echo "[AUB.AI] Fetching the latest version of sherpa-onnx..."
cd src/sherpa-onnx || exit
git pull origin master
git checkout master
cd ../..

# Update 'ios-cmake' submodule
echo "[AUB.AI] Fetching the latest version of ios-cmake..."
cd src/ios-cmake || exit
git pull origin main
git checkout main
cd ../..

echo "[AUB.AI] Finished updating git submodules."
