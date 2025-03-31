Pod::Spec.new do |s|
    
    s.name             = 'DVNTAlamofireWrapper'
    s.version          = '2.5.5'
    s.summary          = 'An amazing Alamofire wrapper.'
    s.description      = 'A wrapper to use Amalofire easily.'
    s.homepage         = 'https://www.devinet.es'
    s.license          = { :type => 'Copyright (c) 2021 Devinet 2013, S.L.U.', :file => 'LICENSE' }
    s.author           = { 'Raúl Vidal Muiños' => 'contacto@devinet.es' }
    s.social_media_url = 'https://twitter.com/devinet_es'
    
    s.ios.deployment_target = "16.2"
    s.tvos.deployment_target  = "16.0"
    
    s.swift_versions   = ['3.0', '4.0', '4.1', '4.2', '5.0', '5.1', '5.2', '5.3', '5.4', '5.5', '5.6', '5.7', '5.8', '5.9', '5.10']
    s.source           = { :git => 'https://github.com/Devinet-2013-S-L-U/ios-library-dvntalamofirewrapper.git', :tag => s.version.to_s }
    s.frameworks       = 'UIKit'
    s.source_files     = 'Sources/DVNTAlamofireWrapper/Classes/**/*'
    s.exclude_files    = 'Sources/DVNTAlamofireWrapper/**/*.plist'
    
    s.dependency 'Alamofire', '~>5.10.2'
    s.dependency 'SwiftyJSON', '~>5.0.2'
    s.dependency 'ReachabilitySwift', '~>5.2.4'
    
end

