Pod::Spec.new do
  name 'TTTAttributedLabel'
  authors 'Mattt Thompson' => 'm@mattt.me'
  version '1.1.0'
  summary 'A drop-in replacement for UILabel that supports NSAttributedStrings '
  source :git => 'git://github.com/mattt/TTTAttributedLabel.git', :tag => '1.1.0'
  
  platforms 'iOS'
  sdk '>= 4.0'
  
  doc_bin 'appledoc'
  doc_options '--project-name' => 'TTTAttributedLabel', '--project-company' => 'Mattt Thompson', '--company-id' => 'com.mattt'
end
