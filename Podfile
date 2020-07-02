source 'https://github.com/cocoapods/specs.git'
use_frameworks!

load 'Podfile.include'

$tunnelkit_name = 'TunnelKit'
$tunnelkit_specs = ['Protocols/OpenVPN', 'Manager', 'Extra/LZO']

def shared_pods
    #pod_version $tunnelkit_name, $tunnelkit_specs, '~> 2.0.1'
    pod_git $tunnelkit_name, $tunnelkit_specs, '683617d'
    #pod_path $tunnelkit_name, $tunnelkit_specs, '..'
    pod 'Convenience/Misc', :git => 'https://github.com/keeshux/convenience', :commit => 'cfd2e57'
    pod 'Convenience/Persistence', :git => 'https://github.com/keeshux/convenience', :commit => 'cfd2e57'
    pod 'Convenience/WebServices', :git => 'https://github.com/keeshux/convenience', :commit => 'cfd2e57'
    pod 'SSZipArchive'
end

target 'PassepartoutCore-iOS' do
    platform :ios, '11.0'
    shared_pods
end
target 'PassepartoutCoreTests-iOS' do
    platform :ios, '11.0'
end
target 'PassepartoutCore-macOS' do
    platform :osx, '10.12'
    shared_pods
end
target 'PassepartoutCoreTests-macOS' do
    platform :osx, '10.12'
end
