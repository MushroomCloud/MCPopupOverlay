
Pod::Spec.new do |s|

  s.name         = "MCPopupOverlay"
  s.version      = "0.0.1"
  s.summary      = "A generic popup view class."
  s.homepage     = "http://www.mushroomcloud.co.za"
  s.license      = 'Apache License, Version 2.0'
  s.author       = { "Rayman Rosevear" => "ray@mushroomcloud.co.za" }

  s.platform     = :ios, "6.0"

  s.source       = { :git => "https://github.com/MushroomCloud/MCPopupOverlay.git", :tag => "0.0.1" }
  s.source_files = "MCPopupOverlay/*.{h,m}", "MCPopupOverlay/**/*.{h,m}"
  s.public_header_files = "MCPopupOverlay/*.h", "MCPopupOverlay/Framework/*.h"

  s.requires_arc = true

  s.dependency "JRSwizzle", "~> 1.0"

end
