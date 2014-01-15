Pod::Spec.new do |s|
  s.name = 'TTTAttributedLabel'
  s.version = '1.8.1'
  s.authors = {'Mattt Thompson' => 'm@mattt.me'}
  s.homepage = 'https://github.com/mattt/TTTAttributedLabel/'
  s.summary = 'A drop-in replacement for UILabel that supports attributes, data detectors, links, and more.'
  s.source = {:git => 'https://github.com/mattt/TTTAttributedLabel.git', :tag => '1.8.1'}
  s.license = 'MIT'

  s.requires_arc = true

  s.platform = :ios
  s.ios.deployment_target = '4.3'

  s.frameworks = 'CoreText', 'CoreGraphics'
  s.source_files = 'TTTAttributedLabel'
end
