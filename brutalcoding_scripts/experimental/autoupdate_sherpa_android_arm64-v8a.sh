cd ../..
cd src/sherpa-onnx
./build-android-arm64-v8a.sh

# Note: ANDROID_NDK is referred as ANDROID_CMAKE_TOOLCHAIN_FILE in my other scripts. Just an FYI.
export ANDROID_NDK=~/Library/Android/sdk/ndk/23.1.7779620/build/cmake/android.toolchain.cmake

mv build-android-arm64-v8a/install/lib/lib*.so ../../android/src/main/jniLibs/arm64-v8a/
