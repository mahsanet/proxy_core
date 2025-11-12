#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint proxy_core.podspec` to validate before publishing.
#

framework_name = 'libproxy_core.xcframework'
local_zip_name = "#{framework_name}.zip"

# Shell command to unzip the framework
`
cd Frameworks

unzip -o #{local_zip_name}
cd -
`

Pod::Spec.new do |s|
  s.name             = 'proxy_core'
  s.version          = '0.0.1'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = <<-DESC
A new Flutter FFI plugin project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'

  # Use the extracted xcframework
  s.vendored_frameworks = "Frameworks/#{framework_name}"

  # Link libresolv.tbd library
  s.libraries = "resolv"

  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
