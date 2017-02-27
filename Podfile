# Uncomment this line to define a global platform for your project
# platform :ios, '6.0'

target 'meet-swift' do 
  pod 'OpenTok'
  pod 'Fabric'
  pod 'Crashlytics'
end

post_install do |installer|
  installer.pods_project.build_configuration_list.build_configurations.each do |configuration|
    configuration.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
  end
end
