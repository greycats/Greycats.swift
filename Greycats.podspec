Pod::Spec.new do |s|
  s.name             = "Greycats"
  s.version          = "2.2.4"
  s.summary          = "A set of tools we use to speed up developing in greycats"
  s.description      = <<-DESC
						Currently includes
						* a TableViewData which binds Section to DataSource
						* a Filter which applies regexp search on UISearchBar | UITextField
						* AutolayoutStack
                       DESC
  s.homepage         = "http://github.com/greycats/Greycats.swift"
  s.license          = 'MIT'
  s.author           = { "Rex Sheng" => "shengning@gmail.com" }
  s.source           = { :git => "https://github.com/greycats/Greycats.swift.git", :tag => s.version.to_s }
  s.requires_arc     = true
  s.platform         = :ios, "8.0"
  
  s.source_files = "Greycats/*.swift"

end
