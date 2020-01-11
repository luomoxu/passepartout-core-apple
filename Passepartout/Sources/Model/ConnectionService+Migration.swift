//
//  ConnectionService+Migration.swift
//  Passepartout
//
//  Created by Davide De Rosa on 10/25/18.
//  Copyright (c) 2020 Davide De Rosa. All rights reserved.
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

public extension ConnectionService {
    static func migrateJSON(from: URL, to: URL) {
        do {
            let newData = try migrateJSON(at: from)
//            log.verbose(String(data: newData, encoding: .utf8)!)
            try newData.write(to: to)
        } catch let e {
            log.error("Could not migrate service: \(e)")
        }
    }
    
    static func migrateJSON(at url: URL) throws -> Data {
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw ApplicationError.migration
        }

        // put migration logic here
        let _ = json["build"] as? Int ?? 0

        return try JSONSerialization.data(withJSONObject: json, options: [])
    }

    func migrateProvidersToLowercase() {

        // migrate providers to lowercase names
        guard let files = try? FileManager.default.contentsOfDirectory(at: providersURL, includingPropertiesForKeys: nil, options: []) else {
            log.debug("No providers to migrate")
            return
        }
        for entry in files {
            let filename = entry.lastPathComponent

            // old names contain at least an uppercase letter
            guard let _ = filename.rangeOfCharacter(from: .uppercaseLetters) else {
                continue
            }
            
            log.debug("Migrating provider in \(filename) to new name")
            do {
                let data = try Data(contentsOf: entry)
                guard var obj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], let name = obj["name"] as? String else {
                    log.warning("Skipping provider \(filename), not a JSON or no 'name' key found")
                    continue
                }

                // replace name and overwrite
                obj["name"] = name.lowercased()
                let migratedData = try JSONSerialization.data(withJSONObject: obj, options: [])
                try? migratedData.write(to: entry)
                
                // rename file if it makes sense
                let newEntry = entry.deletingLastPathComponent().appendingPathComponent(filename.lowercased())
                try? FileManager.default.moveItem(at: entry, to: newEntry)

                log.debug("Migrated provider: \(name)")
            } catch let e {
                log.warning("Unable to migrate provider \(filename): \(e)")
            }
        }
    }
}
