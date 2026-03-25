require 'yaml'

pubspec = YAML.load_file(File.join('..', 'pubspec.yaml'))
library_version = pubspec['version'].gsub('+', '-')

Pod::Spec.new do |s|
  s.name             = pubspec['name']
  s.version          = library_version
  s.summary          = pubspec['description']
  s.description      = pubspec['description']
  s.homepage         = pubspec['homepage'] || 'https://github.com/user/flutter_wgpu'
  s.license          = { :type => 'MIT' }
  s.authors          = 'wgpu authors'
  s.source           = { :path => '.' }
  s.source_files = 'flutter_wgpu/Sources/flutter_wgpu/**/*.{h,m,swift}'
  s.swift_version = '5.0'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.frameworks = 'IOSurface', 'CoreVideo'

  s.osx.dependency 'FlutterMacOS'
  s.osx.deployment_target = '10.14'

  s.ios.dependency 'Flutter'
  s.ios.deployment_target = '12.0'
end
