#!/bin/bash
# Copyright (C) 2023  Daniel Breedeveld
# Please read LICENSE for terms and conditions.

# Print out system information
echo "[AUB.AI] Your system information:"
echo "[AUB.AI] $(uname -a)"

# Navigate to root directory of the project
echo "[AUB.AI] Navigating to root directory of the project..."
cd ..

# Check if its really the root directory of the project
if [ ! -f "pubspec.yaml" ]; then
    echo "[AUB.AI] Sorry, this script only works when you are in the root directory of the project. Exiting..."
    exit 1
fi

# Detect if OS is macOS, if not, exit the script.
if [ "$(uname)" != "Darwin" ]; then
    echo "[AUB.AI] Sorry, this script only works on macOS. Exiting..."
    exit 1
fi

# Run git submodule update to get the latest version of llama.cpp
echo "[AUB.AI] Updating git submodules..."
git submodule init
git submodule update

# Flutter related
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
cd example || exit
flutter clean
flutter pub get
cd .. || exit

# Generate a native libraries for the C++ code
echo "[AUB.AI] Generating a native libraries for the C++ code..."
cd src || exit
cd llama.cpp || exit
rm -rf build
mkdir build
cd build || exit

# TODO: Remove DLLAMA_METAL arg once this issue is resolved: https://github.com/BrutalCoding/aub.ai/issues/1.
cmake .. -DBUILD_SHARED_LIBS=ON -DLLAMA_METAL=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=OFF -DLLAMA_NATIVE=OFF -DCMAKE_TOOLCHAIN_FILE=../ios-cmake/ios.toolchain.cmake -DPLATFORM=MAC_UNIVERSAL
cmake --build . --config Release

# Tell user that /src/llama.cpp/build/libllama.dylib has been created.
echo "[AUB.AI] '/src/llama.cpp/build/libllama.dylib' has been generated successfully."

# Navigate back to the root directory
echo "[AUB.AI] Navigating back to the root directory..."
cd ../../.. || exit

# Check if its really the root directory of the project
if [ ! -f "pubspec.yaml" ]; then
    echo "[AUB.AI] Sorry, this script only works when you are in the root directory of the project. Exiting..."
    exit 1
fi

# Create a few essential directories if they do not exist
echo "[AUB.AI] Creating a few essential directories if they do not exist..."
mkdir -p macos/Frameworks

# Copy over the compiled libllama.a file to both Debug and Release directories of the Flutter app for macOS/iOS
echo "[AUB.AI] Adding libllama.dylib to the macOS project..."
cp src/llama.cpp/build/libllama.dylib macos/Frameworks/libllama.dylib

# Copy ggml-metal.metal to the macos/Runner directory of the Flutter app
# TODO: See issue https://github.com/BrutalCoding/aub.ai/issues/1.
# echo "[AUB.AI] Adding ggml-metal.metal to the macOS project..."
# cp src/llama.cpp/build/bin/ggml-metal.metal example/macos/Runner/ggml-metal.metal

# Generate all required files
echo "[AUB.AI] Generating Dart files..."
dart run build_runner build --delete-conflicting-outputs # Generate files for riverpod, freezed, and json_serializable etc.
sleep 1 # Wait for 1 second to decrease the chance of the next command failing.
dart run ffigen --config ffigen.yaml # Generate files for ffigen, see ffigen.yaml for more info.

# Notify user that AUB is ready to use.
printf "[AUB.AI] Thanks for flying with AubAI today, the setup took off with success.\n\n"
