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

# We will start compiling our own src/CMakelists.txt file with the Android toolchain that must be somewhere on the system.
# We should end up with a .so file that we can use in our Flutter app for Android.
export ANDROID_CMAKE_TOOLCHAIN_FILE=~/Library/Android/sdk/ndk/23.1.7779620/build/cmake/android.toolchain.cmake
cmake .. -DLLAMA_NATIVE=OFF -DBUILD_SHARED_LIBS=ON -DCMAKE_TOOLCHAIN_FILE=$ANDROID_CMAKE_TOOLCHAIN_FILE -DANDROID_ABI=x86_64 -DANDROID_PLATFORM=android-23 -DCMAKE_C_FLAGS=-march=x86-64 ..
cmake --build . --config Release

# Navigate back to the root directory
echo "[AUB.AI] Navigating back to the root directory..."
cd ../.. || exit

# Re-check if its really the root directory of the project
if [ ! -f "pubspec.yaml" ]; then
    echo "[AUB.AI] Sorry, this script only works when you are in the root directory of the project. Exiting..."
    exit 1
fi

# Create a few essential directories if they do not exist
echo "[AUB.AI] Creating a few essential directories if they do not exist..."
mkdir -p android/src/main/jniLibs/x86_64

# Copy over the files to the Android project
echo "[AUB.AI] Adding llama.cpp to the Android project..."
cp src/build/llama.cpp/libllama.so android/src/main/jniLibs/x86_64/libllama.so || exit

# Generate all required files
echo "[AUB.AI] Generating Dart files..."
dart run build_runner build --delete-conflicting-outputs # Generate files for riverpod, freezed, and json_serializable etc.
dart run ffigen --config ffigen.yaml # Generate files for ffigen, see ffigen.yaml for more info.

# Notify user that AUB is ready to use.
printf "[AUB.AI] Thanks for flying with Aub.ai today, the setup took off with success.\n\n"
