Pod::Spec.new do |s|
  s.name             = "Greycats"
  s.version          = "2.6.5"
  s.summary          = "A set of tools we use to speed up developing in greycats"
  s.description      = <<-DESC
						Currently includes
						* a TableViewData which binds Section to DataSource
						* a Filter which applies regexp search on UISearchBar | UITextField
						* AutolayoutStack
            * Customizable NavigationViewController
                       DESC
  s.homepage         = "http://github.com/greycats/Greycats.swift"
  s.license          = 'MIT'
  s.author           = { "Rex Sheng" => "shengning@gmail.com" }
  s.source           = { :git => "https://github.com/greycats/Greycats.swift.git", :tag => s.version.to_s }
  s.requires_arc     = true
  s.platform         = :ios, "8.0"

  s.default_subspecs = %w[Professional ReactControls Filter Breadcrumb Camera]

  s.subspec "Core" do |s|
    s.source_files = "Greycats/{TextField,Polar,Box,Geocode,UIKit+Swift,_Control,Schedule,Regex,NavigationViewController}.swift"
  end

  s.subspec "JSON" do |s|
    s.source_files = "Greycats/JSON.swift"
  end

  s.subspec "ReactControls" do |s|
    s.source_files = "Greycats/ReactControls.swift"
  end

  s.subspec "Layout" do |s|
    s.source_files = "Greycats/AutolayoutStack.swift"
  end

  s.subspec "TableView" do |s|
    s.source_files = "Greycats/TableViewData.swift"
  end

  s.subspec "Graphics" do |s|
    s.source_files = "Greycats/{ImageOperation,Animation,UIImage+Extention}.swift"
  end

  s.subspec "Camera" do |s|
    s.dependency "Greycats/Core"
    s.dependency "Greycats/Graphics"
    s.source_files = "Greycats/Camera.swift"
  end
  
  s.subspec "Keyboard" do |s|
    s.source_files = "Greycats/Keyboard.swift"
  end

  s.subspec "FormField" do |s|
    s.source_files = "Greycats/FormField.swift"
    s.dependency "Greycats/Core"
  end

  s.subspec "Filter" do |s|
    s.source_files = "Greycats/Filter.swift"
    s.dependency "Greycats/TableView"
  end

  s.subspec "Breadcrumb" do |s|
    s.source_files = "Greycats/Breadcrumb.swift"
  end

  s.subspec "Standard" do |s|
    s.dependency "Greycats/Core"
    s.dependency "Greycats/JSON"
    s.dependency "Greycats/TableView"
    s.dependency "Greycats/Keyboard"
  end

  s.subspec "Professional" do |s|
    s.dependency "Greycats/Standard"
    s.dependency "Greycats/Layout"
    s.dependency "Greycats/Graphics"
    s.dependency "Greycats/FormField"
  end

end
