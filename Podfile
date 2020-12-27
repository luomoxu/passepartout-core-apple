source 'https://github.com/cocoapods/specs.git'
use_frameworks!

load 'Podfile.include'

$tunnelkit_name = 'TunnelKit'
$tunnelkit_specs = ['Protocols/OpenVPN', 'Extra/LZO']

def shared_pods
    #pod_version $tunnelkit_name, $tunnelkit_specs, '~> 3.0.0'
    pod_git $tunnelkit_name, $tunnelkit_specs, '304d021'
    #pod_path $tunnelkit_name, $tunnelkit_specs, '..'
    pod 'Convenience/InApp', :git => 'https://github.com/keeshux/convenience', :commit => '7b1c88a'
    pod 'Convenience/Misc', :git => 'https://github.com/keeshux/convenience', :commit => '7b1c88a'
    pod 'Convenience/Persistence', :git => 'https://github.com/keeshux/convenience', :commit => '7b1c88a'
    pod 'Convenience/WebServices', :git => 'https://github.com/keeshux/convenience', :commit => '7b1c88a'
    pod 'Kvitto', :git => 'https://github.com/keeshux/Kvitto', :branch => 'enable-macos-spec'
    pod 'SSZipArchive'
end

target 'PassepartoutCore-iOS' do
    platform :ios, '12.0'
    shared_pods
end
target 'PassepartoutCoreTests-iOS' do
    platform :ios, '12.0'
end
target 'PassepartoutCore-macOS' do
    platform :osx, '10.15'
    shared_pods
end
target 'PassepartoutCoreTests-macOS' do
    platform :osx, '10.15'
end
