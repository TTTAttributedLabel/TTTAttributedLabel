Pod::Spec.new do |s|
  s.name         = 'TTTAttributedLabel'
  s.version      = '1.13.4'
  s.authors      = { 'Mattt Thompson' => 'm@mattt.me' }
  s.homepage     = 'https://github.com/TTTAttributedLabel/TTTAttributedLabel'
  s.platform     = :ios
  s.summary      = 'A drop-in replacement for UILabel that supports attributes, data detectors, links, and more.'
  s.source       = { :git => 'https://github.com/TTTAttributedLabel/TTTAttributedLabel.git', :tag => s.version.to_s }
  s.license      = 'MIT'
  s.frameworks   = 'UIKit', 'CoreText', 'CoreGraphics', 'QuartzCore'
  s.source_files = 'TTTAttributedLabel'
  s.requires_arc = true
  s.ios.deployment_target = '4.3'
  s.social_media_url = 'https://twitter.com/mattt'
end
