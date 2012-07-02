Pod::Spec.new do |s|
  s.name = 'TTTAttributedLabel'
  s.version = '1.2.2'
  s.authors = {'Mattt Thompson' => 'm@mattt.me'}
  s.homepage = 'https://github.com/mattt/TTTAttributedLabel/'
  s.summary = 'A drop-in replacement for UILabel that supports NSAttributedStrings.'
  s.source = {:git => 'git://github.com/mattt/TTTAttributedLabel.git', :tag => '1.2.2'}
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  
  s.platform = :ios
  s.frameworks = 'CoreText'
  s.source_files = 'TTTAttributedLabel.{h,m}'
end
