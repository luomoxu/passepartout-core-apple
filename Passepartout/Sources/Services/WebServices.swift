//
//  WebServices.swift
//  Passepartout
//
//  Created by Davide De Rosa on 9/14/18.
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
import Convenience

public class WebServices {
    public static let version = "v3"
    
    public enum Group: String {
        case providers
    }

    public enum Endpoint: Convenience.Endpoint {
        case providerNetwork(Infrastructure.Name)
        
        var pathName: String {
            switch self {
            case .providerNetwork(let name):
                return "\(Group.providers.rawValue)/\(name.rawValue)/net"
            }
        }
        
        var fileType: String {
            return "json"
        }
        
        public func apiURL(relativeTo url: URL) -> URL {
            return url.appendingPathComponent("\(pathName).\(fileType)")
        }

        // MARK: Endpoint

        public var url: URL {
            return AppConstants.Web.apiURL(version: WebServices.version, path: "\(pathName).\(fileType)")
        }

        public func bundleURL(in bundle: Bundle) -> URL? {
            return bundle.url(forResource: "\(AppConstants.Store.apiDirectory)/\(pathName)", withExtension: fileType)
        }
    }

    public static let shared = WebServices()
    
    private let ws: ReadonlyWebServices
    
    private init() {
        ws = ReadonlyWebServices()
        ws.timeout = AppConstants.Web.timeout
    }

    public func providerNetwork(with name: Infrastructure.Name, ifModifiedSince lastModified: Date?, completionHandler: @escaping (Response<Infrastructure>?, Error?) -> Void) {
        var request = ws.get(WebServices.Endpoint.providerNetwork(name))
        if let lastModified = lastModified {
            request.addValue(ResponseParser.lastModifiedString(date: lastModified), forHTTPHeaderField: "If-Modified-Since")
        }
        ws.parse(Infrastructure.self, request: request, completionHandler: completionHandler)
    }
}
