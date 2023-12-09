#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint aub_ai.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'aub_ai'
  s.version          = '1.0.0'
  s.summary          = 'AubAI brings you on-device gen-AI capabilities, including offline text generation and more, directly within your app.'
  s.description      = <<-DESC
  AubAI brings you on-device gen-AI capabilities, including offline text generation and more, directly within your app.
                       DESC
  s.homepage         = 'https://brutalcoding.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Daniel Breedeveld' => 'daniel@brutalcoding.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  # s.resources        = 'Resources/**/*' # ERROR | [iOS] file patterns: The `resources` pattern did not match any file.
  s.dependency 'Flutter'

  s.xcconfig = {
    # 'OTHER_LDFLAGS' => '-lllama', # The OTHER_LDFLAGS is set to -lllama, which is usually used for linking dynamic libraries. Since libllama.a is a static library, this flag might not be necessary. However, it shouldn't cause an issue if left as is.
    'USER_HEADER_SEARCH_PATHS' => '"${PROJECT_DIR}/.."/',
    "LIBRARY_SEARCH_PATHS" => '"${PROJECT_DIR}/.."/*',
    'MTL_HEADER_SEARCH_PATHS' => '"${PROJECT_DIR}/.."/*',
   }

  # Reference the llama.framework framework.
  s.vendored_frameworks = 'Frameworks/libllama.framework'

  # Flutter.framework does not contain a i386 slice.
  s.platform = :ios, '11.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
