#
#  Be sure to run `pod spec lint ATParse.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "DynamicLinks"
  s.version      = "1.0"
  s.summary      = "Library for easy DynamicLink generation."
  s.description  = "This library makes it easy to generate DynamicLinks"
  s.homepage     = "http://EXAMPLE/DynamicLink"
  s.license      = "MIT"
  s.author       = { "Nico Landa" => "machukkas@gmail.com" }


  s.platform     = :ios
  s.ios.deployment_target = '11.0'
  s.xcconfig = { 'SWIFT_VERSION' => '4.0' }

  s.source       = { :git => 'https://github.com/machukas/DynamicLinks.git' }

  s.source_files  = "DynamicLinks/**/*.{h,m,swift}"

end
