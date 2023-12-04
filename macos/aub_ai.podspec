#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint aub_ai.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'aub_ai'
  s.version          = '1.0.0'
  s.summary          = 'AubAI allows you to supercharge apps with on-device AI capabilities.'
  s.description      = <<-DESC
  AubAI allows you to supercharge apps with on-device AI capabilities.
  Offline AI is the next frontier in cross-platform app development, and AubAI makes it easy to add it to your app.
                       DESC
  s.homepage         = 'https://brutalcoding.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Daniel Breedeveld' => 'daniel@brutalcoding.com.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.resources        = 'Resources/**/*'
  s.dependency 'FlutterMacOS'

  s.xcconfig = {
   'OTHER_LDFLAGS' => '-lllama',
   'USER_HEADER_SEARCH_PATHS' => '"${PROJECT_DIR}/.."/',
   "LIBRARY_SEARCH_PATHS" => '"${PROJECT_DIR}/.."/*',
   'MTL_HEADER_SEARCH_PATHS' => '"${PROJECT_DIR}/.."/*',
  }

  # This will add libllama.dylib to the Frameworks directory of the example/ app
  # when it is built for device and simulator.
  s.vendored_libraries = 'Frameworks/libllama.dylib' # If .a doesnt work, use 'Frameworks/libllama.dylib'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
