//
//  Issue.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/5/19.
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
import TunnelKit
#if os(iOS)
import MessageUI
#endif

public struct Issue {
    public let debugLog: Bool
    
    public let configurationURL: URL?
    
    public let infrastructure: Infrastructure?
    
    public init(debugLog: Bool, configurationURL: URL?, infrastructure: Infrastructure? = nil) {
        self.debugLog = debugLog
        self.configurationURL = configurationURL
        self.infrastructure = infrastructure
    }
    
    public init(debugLog: Bool, profile: ConnectionProfile?) {
        let url: URL?
        if let profile = profile {
            url = TransientStore.shared.service.configurationURL(for: profile)
        } else {
            url = nil
        }
        let infrastructure = (profile as? ProviderConnectionProfile)?.infrastructure
        self.init(debugLog: debugLog, configurationURL: url, infrastructure: infrastructure)
    }
}
