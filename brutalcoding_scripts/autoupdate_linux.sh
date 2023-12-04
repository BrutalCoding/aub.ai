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

# Run git submodule update to get the latest version of llama.cpp
echo "[AUB.AI] Updating git submodules..."
git submodule update --remote

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
rm -rf build
mkdir -p build
cd build || exit

# We will now compile the binaries for Linux
cmake .. -DLLAMA_NATIVE=OFF -DBUILD_SHARED_LIBS=ON
cmake --build . --config Release

# Navigate back to the root directory
echo "[AUB.AI] Navigating back to the root directory..."
cd ../.. || exit

# Re-check if its really the root directory of the project
if [ ! -f "pubspec.yaml" ]; then
    echo "[AUB.AI] Sorry, this script only works when you are in the root directory of the project. Exiting..."
    exit 1
fi

# Copy over the files to the Linux project
echo "[AUB.AI] Adding llama.cpp to the Linux project..."
mkdir -p linux/x64/lib
cp src/build/llama.cpp/libllama.so linux/x64/lib/libllama.so || exit

# Generate all required files
echo "[AUB.AI] Generating Dart files..."
dart run build_runner build --delete-conflicting-outputs # Generate files for riverpod, freezed, and json_serializable etc.
dart run ffigen --config ffigen.yaml # Generate files for ffigen, see ffigen.yaml for more info.

# Notify user that AUB is ready to use.
printf "[AUB.AI] Thanks for flying with Aub.ai today, the setup took off with success.\n\n"

# Run the example app if the user wants to
printf "[AUB.AI] Do you want to run the example app? (y/n): "
read -r run_example
if [ "$run_example" = "y" ]; then
    printf "[AUB.AI] Running the example app...\n"
    cd example || exit
    flutter run
fi
