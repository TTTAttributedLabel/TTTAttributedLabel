Pod::Spec.new do |s|
  s.name = 'TTTAttributedLabel'
  s.version = '1.7.1'
  s.authors = {'Mattt Thompson' => 'm@mattt.me'}
  s.homepage = 'https://github.com/mattt/TTTAttributedLabel/'
  s.summary = 'A drop-in replacement for UILabel that supports attributes, data detectors, links, and more.'
  s.source = {:git => 'https://github.com/mattt/TTTAttributedLabel.git', :tag => '1.7.1'}
  s.license = 'MIT'

  s.platform = :ios
  s.requires_arc = true
  s.frameworks = 'CoreText', 'CoreGraphics'
  s.source_files = 'TTTAttributedLabel'
end
