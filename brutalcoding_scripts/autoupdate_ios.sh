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
mkdir -p build
cd build || exit

# We will start compiling our own src/CMakelists.txt file with the iOS toolchain found in 'src/ios-cmake' folder.
# We should end up with a .dylib file that we can use in our Flutter app for iOS.
# Please note: This dylib will only work on iOS devices with an arm64 architecture. It is NOT a universal binary.
cmake .. -DBUILD_SHARED_LIBS=ON -DLLAMA_METAL=OFF -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF -DLLAMA_BUILD_SERVER=OFF -DCMAKE_TOOLCHAIN_FILE=../ios-cmake/ios.toolchain.cmake -DPLATFORM=OS64 || exit
cmake --build . --config Release || exit

# Tell user that the libraries have been created.
echo "[AUB.AI] Native libraries have been generated successfully."

# Navigate back to the root directory
echo "[AUB.AI] Navigating back to the root directory..."
cd ../../.. || exit

# Check if its really the root directory of the project
if [ ! -f "pubspec.yaml" ]; then
    echo "[AUB.AI] Sorry, this script only works when you are in the root directory of the project. Exiting..."
    exit 1
fi

# Copy over the dylib file to the iOS project
echo "[AUB.AI] Using lipo to create a framework for llama.cpp..."
lipo -create src/llama.cpp/build/libllama.dylib -output ios/Frameworks/libllama.framework/libllama || exit

echo "[AUB.AI] Running install_name_tool to fix the dylib paths..."
install_name_tool -id @rpath/libllama.framework/libllama ios/Frameworks/libllama.framework/libllama || exit

echo "[AUB.AI] For debugging convenience, running otool -L on the lib..."
otool -L ios/Frameworks/libllama.framework/libllama

# It's important that the outputted 'minos' (13.0 at the time of writing) is the same as
# the minimum iOS version in your iOS project.
# If you don't do this, you will get an error or e-mail from Apple when trying to validate the app for the App Store.
echo "[AUB.AI] For debugging convenience, running vtool -show on the lib..."
vtool -show ios/Frameworks/libllama.framework/libllama

# Generate all required files
echo "[AUB.AI] Generating Dart files..."
dart run build_runner build --delete-conflicting-outputs # Generate files for riverpod, freezed, and json_serializable etc.
dart run ffigen --config ffigen.yaml # Generate files for ffigen, see ffigen.yaml for more info.

# Notify user that AUB is ready to use.
printf "[AUB.AI] Thanks for flying with AubAI today, the setup took off with success.\n\n"
