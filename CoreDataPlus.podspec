Pod::Spec.new do |s|
  s.name    = 'CoreDataPlus'
  s.version = '4.0.0'
  s.license = 'MIT'
  s.documentation_url = 'http://www.alessandromarzoli.com/CoreDataPlus'  
  s.summary   = 'CoreData extensions.'
  s.homepage  = 'https://github.com/alemar11/CoreDataPlus'
  s.authors   = { 'Alessandro Marzoli' => 'me@alessandromarzoli.com' }
  s.source    = { :git => 'https://github.com/alemar11/CoreDataPlus.git', :tag => s.version }
  s.requires_arc = true
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.2'}
  s.swift_version = "5.2"
  s.ios.deployment_target     = '12.0'
  s.osx.deployment_target     = '10.14'
  s.tvos.deployment_target    = '12.0'
  s.watchos.deployment_target = '5.0'
  s.source_files =  'Sources/**/*.swift',
                    'Support/**/*.{h,m}'
end
