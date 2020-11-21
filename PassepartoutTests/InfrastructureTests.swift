//
//  InfrastructureTests.swift
//  PassepartoutTests
//
//  Created by Davide De Rosa on 6/11/18.
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

import XCTest
import TunnelKit
@testable import PassepartoutCore

class InfrastructureTests: XCTestCase {
    private var infra: Infrastructure!

    override func setUp() {
        InfrastructureFactory.shared.preload()
        infra = InfrastructureFactory.shared.infrastructure(forName: .pia)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testParsing() {
        print(infra.categories)
        XCTAssertEqual(infra.categories.count, 1)
    }

    func testIdentifier() {
        let id = "italy"
        guard let pool = infra.pool(for: id) else {
            XCTAssert(false)
            return
        }
        print(pool)
        XCTAssertEqual(pool.id, id)
    }
    
    func testStableSort() {
        let original: [EndpointProtocol] = [
            EndpointProtocol(.udp, 1194),
            EndpointProtocol(.udp, 8080),
            EndpointProtocol(.udp, 9201),
            EndpointProtocol(.udp, 53),
            EndpointProtocol(.udp, 1197),
            EndpointProtocol(.udp, 198),
            EndpointProtocol(.tcp, 443),
            EndpointProtocol(.tcp, 110),
            EndpointProtocol(.tcp, 80),
            EndpointProtocol(.tcp, 500),
            EndpointProtocol(.tcp, 501),
            EndpointProtocol(.tcp, 502)
        ]
        var preferredType: SocketType
        
        preferredType = .udp
        let sorted1 = original.stableSorted {
            return ($0.socketType == preferredType) && ($1.socketType != preferredType)
        }
        XCTAssertEqual(sorted1, original)

        preferredType = .tcp
        let sorted2 = original.stableSorted {
            return ($0.socketType == preferredType) && ($1.socketType != preferredType)
        }
        XCTAssertNotEqual(sorted2, original)
    }
    
    func testLastModified() {
        let fmt = DateFormatter()
        fmt.timeZone = TimeZone(abbreviation: "GMT")
        fmt.dateFormat = "EEE, dd LLL yyyy HH:mm:ss zzz"

        let lmString = "Wed, 23 Oct 2019 17:06:54 GMT"

        fmt.locale = Locale(identifier: "en")
        XCTAssertNotNil(fmt.date(from: lmString))
        fmt.locale = Locale(identifier: "fr-FR")
        XCTAssertNil(fmt.date(from: lmString))
    }

    func testProvidersIndex() {
        let ifactory = InfrastructureFactory.shared
        XCTAssertNotNil(ifactory.metadata(forName: "nordvpn"))
        XCTAssertNil(ifactory.metadata(forName: "expressvpn"))

        let update = expectation(description: "updateIndex")
        ifactory.updateIndex { _ in
            update.fulfill()
        }
        waitForExpectations(timeout: 10.0) { _ in
            print(ifactory.allMetadata)
        }
    }
}
