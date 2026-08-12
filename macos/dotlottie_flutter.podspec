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

  s.resource_bundles = { 'dotlottie_flutter_privacy' => ['dotlottie_flutter/Sources/dotlottie_flutter/PrivacyInfo.xcprivacy'] }

  s.dependency 'FlutterMacOS'
  s.dependency 'LottieFiles-dotLottie-iOS', '~> 0.16.8'

  s.platform = :osx, '11.0'
  s.osx.deployment_target  = '11.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
