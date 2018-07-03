# Uncomment the next line to define a global platform for your project
source 'https://github.com/CocoaPods/Specs.git'
source 'http://10.11.180.29/mobileDevelopers/YZT-Loan-Pod-Spec.git'

#source 'https://github.com/miaozhang9/ZMSpecccc.git'
platform :ios, '9.0'
use_frameworks!

target 'TestPodLib' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
 
  # Pods for TestPodLib
#pod 'ZMBase','~> 0.1.0'
#pod 'OTBase','~> 0.1.0'
#pod 'Loan_iOS_Custom_Framework'
#pod 'YYStudio_LoanSDK'
pod 'YYStudio_LoanSDK_All'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.1'
            # 解决打包第三方framework签名问题
#            config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
#            config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
#            config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
        end
    end
end



