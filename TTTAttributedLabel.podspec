Pod::Spec.new do |s|
  s.name         = 'TTTAttributedLabel'
  s.version      = '2.0.0'
  s.authors      = { 'Mattt Thompson' => 'm@mattt.me' }
  s.homepage     = 'https://github.com/TTTAttributedLabel/TTTAttributedLabel'
  s.platform     = :ios
  s.summary      = 'A drop-in replacement for UILabel that supports attributes, data detectors, links, and more.'
  s.source       = { :git => 'https://github.com/TTTAttributedLabel/TTTAttributedLabel.git', :tag => s.version.to_s }
  s.license      = 'MIT'
  s.frameworks   = 'UIKit', 'CoreText', 'CoreGraphics', 'QuartzCore'
  s.requires_arc = true
  s.ios.deployment_target = '4.3'
  s.social_media_url = 'https://twitter.com/mattt'

  s.subspec 'Default' do |ss|
    ss.source_files = 'TTTAttributedLabel'
  end

  s.subspec 'NoDesignable' do |ss|
    ss.dependency 'TTTAttributedLabel/Default'
    ss.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'TTT_NO_DESIGNABLE=1' }
  end

  s.default_subspec = 'Default'
end
