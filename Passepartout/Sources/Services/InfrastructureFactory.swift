//
//  InfrastructureFactory.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/2/18.
//  Copyright (c) 2019 Davide De Rosa. All rights reserved.
//
//  https://github.com/passepartoutvpn
//
//  This file is part of Passepartout.
//
//  Passepartout is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Passepartout is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Passepartout.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import SwiftyBeaver

private let log = SwiftyBeaver.self

// TODO: retain max N infrastructures at a time (LRU)

public class InfrastructureFactory {
    public static let shared = InfrastructureFactory()

    private let cachePath: URL
    
    private var bundledMetadata: [Infrastructure.Metadata]

    private var bundledInfrastructures: [Infrastructure.Name: Infrastructure]

    private var cachedInfrastructures: [Infrastructure.Name: Infrastructure]

    private var lastUpdate: [Infrastructure.Name: Date]

    private init() {
        cachePath = GroupConstants.App.cachesURL
        bundledMetadata = []
        bundledInfrastructures = [:]
        cachedInfrastructures = [:]
        lastUpdate = [:]
    }
    
    // MARK: Storage
    
    public func preload() {
        loadMetadata()
        loadInfrastructures()
    }
    
    public func loadMetadata() {
        
        // FIXME: try load index from cache first
        
        // try load index from bundle
        guard let url = InfrastructureFactory.bundledMetadataURL else {
            return
        }
        let decoder = JSONDecoder()
        do {
            let metadataData = try Data(contentsOf: url)
            bundledMetadata = try decoder.decode([Infrastructure.Metadata].self, from: metadataData)
            log.debug("Loaded metadata from bundle: \(bundledMetadata)")
        } catch let e {
            log.error("Unable to load index from bundle: \(e)")
        }

        // load bundled infrastructure for each metadata
        bundledInfrastructures.removeAll()
        bundledMetadata.forEach {
            bundledInfrastructures[$0.name] = InfrastructureFactory.bundledInfrastructure(withName: $0.name)
        }
    }

    public func loadInfrastructures() {
        let apiPath = cachePath.appendingPathComponent(AppConstants.Store.apiDirectory)
        let providersPath = apiPath.appendingPathComponent(WebServices.Group.providers.rawValue)
        
        log.debug("Loading cache from: \(providersPath)")
        let providersEntries: [URL]
        do {
            providersEntries = try FileManager.default.contentsOfDirectory(at: providersPath, includingPropertiesForKeys: nil)
        } catch let e {
            log.warning("Error loading cache or nothing cached: \(e)")
            return
        }

        let decoder = JSONDecoder()
        for entry in providersEntries {
            let name = entry.lastPathComponent
            let infraPath = WebServices.Endpoint.providerNetwork(name).apiURL(relativeTo: apiPath)
            guard let data = try? Data(contentsOf: infraPath) else {
                continue
            }
            let infra: Infrastructure
            do {
                infra = try decoder.decode(Infrastructure.self, from: data)
            } catch let e {
                log.warning("Unable to load infrastructure \(entry.lastPathComponent): \(e)")
                if let json = String(data: data, encoding: .utf8) {
                    log.warning(json)
                }
                continue
            }

            // supersede if older than embedded
            guard InfrastructureFactory.isCachedEntryNewer(at: entry, thanBundledWithName: infra.name) else {
                log.warning("Bundle is newer than cache, superseding cache for \(infra.name)")
                cachedInfrastructures[infra.name] = bundledInfrastructures[infra.name]
                continue
            }

            cachedInfrastructures[infra.name] = infra
            log.debug("Loading cache for \(infra.name)")
        }
    }
    
    public func allMetadata() -> [Infrastructure.Metadata] {
        return bundledMetadata
    }
    
    public func metadata(forName name: Infrastructure.Name) -> Infrastructure.Metadata? {
        return bundledMetadata.first(where: { $0.name == name})
    }

    public func infrastructure(forName name: Infrastructure.Name) -> Infrastructure {
        guard let infra = cachedInfrastructures[name] ?? bundledInfrastructures[name] else {
            fatalError("No infrastructure embedded nor cached for '\(name)'")
        }
        return infra
    }
    
    private static func bundledInfrastructure(withName name: Infrastructure.Name) -> Infrastructure {
        guard let url = name.bundleURL else {
            fatalError("Cannot find JSON for infrastructure '\(name)'")
        }
        do {
            return try Infrastructure.from(url: url)
        } catch let e {
            fatalError("Cannot parse JSON for infrastructure '\(name)': \(e)")
        }
    }
    
    // MARK: Web services

    public func update(_ name: Infrastructure.Name, notBeforeInterval minInterval: TimeInterval?, completionHandler: @escaping ((Infrastructure, Date)?, Error?) -> Void) -> Bool {
        let ifModifiedSince = modificationDate(forName: name)
        
        if let lastInfrastructureUpdate = lastUpdate[name] {
            log.debug("Last update for \(name): \(lastUpdate)")

            if let minInterval = minInterval {
                let elapsed = -lastInfrastructureUpdate.timeIntervalSinceNow
                guard elapsed >= minInterval else {
                    log.warning("Skipping update, only \(elapsed) seconds elapsed (< \(minInterval))")
                    return false
                }
            }
        }
        
        WebServices.shared.providerNetwork(with: name, ifModifiedSince: ifModifiedSince) { (response, error) in
            if error == nil {
                self.lastUpdate[name] = Date()
            }

            guard let response = response else {
                log.error("No response from web service")
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            if response.isCached {
                log.debug("Cache is up to date")
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            guard let infra = response.value, let lastModified = response.lastModified else {
                log.error("No response from web service or missing Last-Modified")
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            let appBuild = GroupConstants.App.buildNumber
            guard appBuild >= infra.build else {
                log.error("Response requires app build >= \(infra.build) (found \(appBuild))")
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }
            
            var isNewer = true
            if let bundleDate = self.bundleModificationDate(forName: name) {
                log.verbose("Bundle date: \(bundleDate)")
                log.verbose("Web date:    \(lastModified)")

                isNewer = lastModified > bundleDate
            }
            guard isNewer else {
                log.warning("Web service infrastructure is older than bundle, discarding")
                DispatchQueue.main.async {
                    completionHandler(nil, error)
                }
                return
            }

            self.save(name, with: infra, lastModified: lastModified)

            DispatchQueue.main.async {
                completionHandler((infra, lastModified), nil)
            }
        }
        return true
    }

    private func save(_ name: Infrastructure.Name, with infrastructure: Infrastructure, lastModified: Date) {
        cachedInfrastructures[name] = infrastructure
        
        let fm = FileManager.default
        let url = cacheURL(forName: name)
        do {
            let parent = url.deletingLastPathComponent()
            try fm.createDirectory(at: parent, withIntermediateDirectories: true, attributes: nil)
            let data = try JSONEncoder().encode(infrastructure)
            try data.write(to: url)
            try fm.setAttributes([.modificationDate: lastModified], ofItemAtPath: url.path)
        } catch let e {
            log.error("Error saving cache: \(e)")
        }
    }

    // MARK: URLs
    
    private func cacheURL(forName name: Infrastructure.Name) -> URL {
        return cachePath.appendingPathComponent(name.bundleRelativePath)
    }
    
    private static var bundledMetadataURL: URL? {
        let bundle = Bundle(for: Infrastructure.self)
        let endpoint = WebServices.Endpoint.providersIndex

        return endpoint.bundleURL(in: bundle)
    }

    // MARK: Modification dates

    public func modificationDate(forName name: Infrastructure.Name) -> Date? {
        let optBundleDate = bundleModificationDate(forName: name)
        guard let cacheDate = cacheModificationDate(forName: name) else {
            return optBundleDate
        }
        guard let bundleDate = optBundleDate else {
            return cacheDate
        }
        return max(cacheDate, bundleDate)
    }
    
    private func cacheModificationDate(forName name: Infrastructure.Name) -> Date? {
        let url = cacheURL(forName: name)
        return FileManager.default.modificationDate(of: url.path)
    }

    private func bundleModificationDate(forName name: Infrastructure.Name) -> Date? {
        guard let url = name.bundleURL else {
            return nil
        }
        return FileManager.default.modificationDate(of: url.path)
    }

    private static func isCachedEntryNewer(at url: URL, thanBundledWithName name: Infrastructure.Name) -> Bool {
        guard let cacheDate = FileManager.default.modificationDate(of: url.path) else {
            return false
        }
        guard let bundleURL = name.bundleURL else {
            return true
        }
        guard let bundleDate = FileManager.default.modificationDate(of: bundleURL.path) else {
            return true
        }
        return cacheDate > bundleDate
    }
}

private extension Infrastructure.Name {
    var bundleRelativePath: String {
        let endpoint = WebServices.Endpoint.providerNetwork(self)
        
        // e.g. "API/v3", PIA="providers/pia/net.json" -> "API/v3/providers/pia/net.json"
        return "\(AppConstants.Store.apiDirectory)/\(endpoint.pathName).\(endpoint.fileType)"
    }

    var bundleURL: URL? {
        let bundle = Bundle(for: InfrastructureFactory.self)
        let endpoint = WebServices.Endpoint.providerNetwork(self)
        
        return endpoint.bundleURL(in: bundle)
    }
}

extension ConnectionService {
    public func currentProviderNames() -> [Infrastructure.Name] {
        return ids(forContext: .provider)
    }

    public func availableProviders() -> [Infrastructure.Metadata] {
        let names = Set(currentProviderNames())
        return InfrastructureFactory.shared.allMetadata().filter { !names.contains($0.name) }
    }
}
