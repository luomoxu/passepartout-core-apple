//
//  Infrastructure+Name.swift
//  Passepartout
//
//  Created by Davide De Rosa on 11/24/19.
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

extension Infrastructure {
    public typealias Name = String
    
    public struct Metadata: Codable, Hashable, Comparable, CustomStringConvertible {
        public let name: Name
        
        // MARK: CustomStringConvertible

        public let description: String

        // TODO: update index from web
        // TODO: get metadata from index through provider name
        
        public init(_ name: Name, _ description: String) {
            self.name = name
            self.description = description
        }
        
        // MARK: Hashable
        
        public func hash(into hasher: inout Hasher) {
            name.hash(into: &hasher)
        }
        
        public static func ==(lhs: Infrastructure.Metadata, rhs: Infrastructure.Metadata) -> Bool {
            return lhs.name == rhs.name
        }

        // MARK: Comparable

        public static func <(lhs: Infrastructure.Metadata, rhs: Infrastructure.Metadata) -> Bool {
            return lhs.name < rhs.name
        }
    }
}

extension Infrastructure.Name {
    public static let mullvad = "mullvad"

    public static let nordvpn = "nordvpn"

    public static let pia = "pia"

    public static let protonvpn = "protonvpn"

    public static let tunnelbear = "tunnelbear"

    public static let vyprvpn = "vyprvpn"

    public static let windscribe = "windscribe"

    // MARK: Index

    // manually pre-sorted
    public static let all: [Infrastructure.Name] = [
        .mullvad,
        .nordvpn,
        .pia,
        .protonvpn,
        .tunnelbear,
        .vyprvpn,
        .windscribe
    ]
}

extension Infrastructure.Metadata {
    public static let mullvad = Infrastructure.Metadata(.mullvad, "Mullvad")

    public static let nordvpn = Infrastructure.Metadata(.nordvpn, "NordVPN")

    public static let pia = Infrastructure.Metadata(.pia, "PIA")

    public static let protonvpn = Infrastructure.Metadata(.protonvpn, "ProtonVPN")

    public static let tunnelbear = Infrastructure.Metadata(.tunnelbear, "TunnelBear")

    public static let vyprvpn = Infrastructure.Metadata(.vyprvpn, "VyprVPN")

    public static let windscribe = Infrastructure.Metadata(.windscribe, "Windscribe")
}
