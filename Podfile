source 'https://github.com/cocoapods/specs.git'
use_frameworks!

load 'Podfile.include'

$tunnelkit_name = 'TunnelKit'
$tunnelkit_specs = ['Protocols/OpenVPN', 'Extra/LZO']

def shared_pods
    #pod_version $tunnelkit_name, $tunnelkit_specs, '~> 3.0.0'
    pod_git $tunnelkit_name, $tunnelkit_specs, 'cfca8fa'
    #pod_path $tunnelkit_name, $tunnelkit_specs, '..'

    for spec in ['InApp', 'Misc', 'Persistence', 'WebServices'] do
        pod "Convenience/#{spec}", :git => 'https://github.com/keeshux/convenience', :commit => 'b30816a'
    end
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
