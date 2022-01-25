//
//  AppTests.swift
//
//
//  Created by Thomas Durand on 22/01/2022.
//  Copyright © 2022 Padlok. All rights reserved.
//

@testable import App
import XCTVapor

final class AppTests: XCTestCase {
    func testRedirection() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        // Default to english
        try app.test(.GET, "", afterResponse: { res in
            XCTAssertEqual(res.status, .found)
            XCTAssertTrue(res.headers.contains(name: .location))
            XCTAssertEqual(res.headers.first(name: .location), "https://padlok.app")
        })

        // When present, we go to the correct language
        for (langcode, expected) in [
            "en-CA": "https://padlok.app",
            "en-UK": "https://padlok.app",
            "en-US": "https://padlok.app",
            "fr-CA": "https://padlok.app/fr",
            "fr-FR": "https://padlok.app/fr",
            // Unsupported locales should default to english
            "zh-Hans": "https://padlok.app",
        ] {
            try app.test(.GET, "", headers: [
                HTTPHeaders.Name.acceptLanguage.description: langcode,
            ], afterResponse: { res in
                XCTAssertEqual(res.status, .found)
                XCTAssertTrue(res.headers.contains(name: .location))
                XCTAssertEqual(res.headers.first(name: .location), expected)
            })
        }
    }

    func testOptionsGetter() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        // Default to english
        try app.test(.OPTIONS, "", afterResponse: { res throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssertTrue(res.headers.contains(name: .contentType))
            XCTAssertEqual(res.headers.first(name: .contentType), "application/json; charset=utf-8")
            let options = try res.content.decode(Options.self)
            XCTAssertEqual(options, Options.adapted(for: .english))
        })

        // When present, we go to the correct language
        for (langcode, language) in [
            "en-CA": Language.english,
            "en-UK": .english,
            "en-US": .english,
            "fr-CA": .french,
            "fr-FR": .french,
            // Unsupported locales should default to english
            "zh-Hans": .english,
        ] {
            try app.test(.OPTIONS, "", headers: [
                HTTPHeaders.Name.acceptLanguage.description: langcode,
            ], afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
                XCTAssertTrue(res.headers.contains(name: .contentType))
                XCTAssertEqual(res.headers.first(name: .contentType), "application/json; charset=utf-8")
                let options = try res.content.decode(Options.self)
                XCTAssertEqual(options, Options.adapted(for: language))
            })
        }
    }
}
