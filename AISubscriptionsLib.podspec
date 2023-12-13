Pod::Spec.new do |s|
    s.name = "AISubscriptionsLib"
    s.version = "1.0"
    s.summary = "A short description of AISubscriptionsLib."
    s.description = <<-DESC
    A  description of AISubscriptionsLib.
    DESC
    s.homepage = "https://dev.azure.com/aisberg-tech/_git/iOS%20subscription%20library"
    s.license = "MIT"
    s.author = { "Serj" => "park.of.world@gmail.com" }
    # s.platform = :ios, "11.2"
    s.source = { :git => "http://dev.azure.com/AISubscriptionsLib.git", :tag => "#{s.version}" }
    s.source_files  = "Sources/**/*.{swift}"
    
    # s.resource  = "icon.png"
    # s.resources = "Resources/*.png"
    # s.preserve_paths = "FilesToSave", "MoreFilesToSave"
    # s.framework  = "SomeFramework"
    # s.frameworks = "SomeFramework", "AnotherFramework"
    # s.library   = "iconv"
    # s.libraries = "iconv", "xml2"
    # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }

    s.dependency 'SwiftyStoreKit'
    s.dependency "KeychainSwift"

#    s.framework = "XCTest"
  end
  
