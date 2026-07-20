#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint dotlottie_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'dotlottie_flutter'
  s.version          = '0.1.4'
  s.summary          = 'Render dotLottie and Lottie animations in Flutter.'
  s.description      = <<-DESC
Render dotLottie and Lottie animations in Flutter. Supports playback control,
theming and state machines.
                       DESC
  s.homepage         = 'https://lottiefiles.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'LottieFiles' => 'sam@lottiefiles.com' }
  s.source           = { :path => '.' }
  s.source_files = 'dotlottie_flutter/Sources/dotlottie_flutter/**/*.swift'
  s.dependency 'Flutter'
  s.dependency 'LottieFiles-dotLottie-iOS', '~> 0.16.5'
  s.platform = :ios, '13.0'
  

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = { 'dotlottie_flutter_privacy' => ['dotlottie_flutter/Sources/dotlottie_flutter/PrivacyInfo.xcprivacy'] }
end
