#
# Podspec file for proxy_core plugin
#

Pod::Spec.new do |s|
  s.name             = 'proxy_core'
  s.version          = '3.0.0'
  s.summary          = 'A new Flutter FFI plugin project.'
  s.description      = 'A new Flutter FFI plugin project.'
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.platform         = :ios, '15.6'

  s.source_files = 'Classes/**/*'
#   s.requires_arc = true

  s.dependency 'Flutter'
  s.ios.deployment_target = '15.6'

  # Link libresolv.tbd library
  s.libraries = "resolv"

  # Enable module definition
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
  }

  s.swift_version = '5.0'
end