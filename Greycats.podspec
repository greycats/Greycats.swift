#
# Be sure to run `pod lib lint Greycats.swift.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Greycats"
  s.version          = "1.1.0"
  s.summary          = "A set of tools we use to speed up developing in greycats"
  s.description      = <<-DESC
						Currently includes
						* a TableViewData which binds Section to DataSource
						* a Filter which applies regexp search on UISearchBar | UITextField
						* AutolayoutStack
                       DESC
  s.homepage         = "https://github.com/greycats/Greycats.swift"
  s.license          = 'MIT'
  s.author           = { "Rex Sheng" => "shengning@gmail.com" }
  s.source           = { :git => "https://github.com/greycats/Greycats.swift.git", :tag => s.version.to_s }
  s.requires_arc     = true
  s.platform         = :ios, "8.0"
  
  s.source_files = "Greycats/*.swift"

end
