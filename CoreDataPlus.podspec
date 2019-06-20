Pod::Spec.new do |s|
  s.name    = 'CoreDataPlus'
  s.version = '2.1.0'
  s.license = 'MIT'
  s.documentation_url = 'http://www.tinrobots.org/CoreDataPlus'  
  s.summary   = 'CoreData extensions.'
  s.homepage  = 'https://github.com/tinrobots/CoreDataPlus'
  s.authors   = { 'Alessandro Marzoli' => 'me@alessandromarzoli.com' }
  s.source    = { :git => 'https://github.com/tinrobots/CoreDataPlus.git', :tag => s.version }
  s.requires_arc = true
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5.0'}
  s.swift_version = "5.0"
  s.ios.deployment_target     = '11.0'
  s.osx.deployment_target     = '10.13'
  s.tvos.deployment_target    = '11.0'
  s.watchos.deployment_target = '4.0'
  s.source_files =  'Sources/**/*.swift',
                    'Support/**/*.{h,m}'
end
