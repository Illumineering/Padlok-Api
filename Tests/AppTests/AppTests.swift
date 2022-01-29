//
//  AppTests.swift
//
//
//  Created by Thomas Durand on 22/01/2022.
//  Copyright © 2022 Padlok. All rights reserved.
//

@testable import App
import XCTVapor

/// Structure of `ErrorMiddleware` default response.
struct ErrorResponse: Codable, Equatable {
    /// Always `true` to indicate this is a non-typical JSON response.
    let error: Bool

    /// The reason for the error.
    let reason: String
}

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
        try app.test(.OPTIONS, "", afterResponse: { res in
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

    func testFeedbackPost() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        // No body
        try app.test(.POST, "feedback", afterResponse: { res in
            XCTAssertEqual(res.status, .unsupportedMediaType)
        })

        // Bad body
        try app.test(.POST, "feedback", beforeRequest: { req in
            try req.content.encode(["bad": "content"])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
        })

        // Missing required reason key
        try app.test(.POST, "feedback", beforeRequest: { req in
            try req.content.encode([
                "language": "en",
                "email": "test@test.fr",
                "message": "a message",
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(try res.content.decode(ErrorResponse.self), ErrorResponse(error: true, reason: "Value required for key \'reason\'."))
        })

        // Unsupported value for reason key
        try app.test(.POST, "feedback", beforeRequest: { req in
            try req.content.encode([
                "reason": "hello, world!",
                "language": "en",
                "email": "test@test.fr",
                "message": "a message",
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(try res.content.decode(ErrorResponse.self), ErrorResponse(error: true, reason: "Cannot initialize Reason from invalid String value hello, world! for key reason"))
        })

        // Missing required language key
        try app.test(.POST, "feedback", beforeRequest: { req in
            try req.content.encode([
                "reason": "other",
                "email": "test@test.fr",
                "message": "a message",
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(try res.content.decode(ErrorResponse.self), ErrorResponse(error: true, reason: "Value required for key \'language\'."))
        })

        // Unsupported value for language key
        try app.test(.POST, "feedback", beforeRequest: { req in
            try req.content.encode([
                "reason": "other",
                "language": "zh",
                "email": "test@test.fr",
                "message": "a message",
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(try res.content.decode(ErrorResponse.self), ErrorResponse(error: true, reason: "Cannot initialize Language from invalid String value zh for key language"))
        })

        // Missing required message key
        try app.test(.POST, "feedback", beforeRequest: { req in
            try req.content.encode([
                "reason": "bug",
                "language": "en",
                "email": "test@test.fr"
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(try res.content.decode(ErrorResponse.self), ErrorResponse(error: true, reason: "Value required for key \'message\'."))
        })

        // Empty message
        try app.test(.POST, "feedback", beforeRequest: { req in
            try req.content.encode([
                "reason": "feature",
                "language": "fr",
                "email": "test@test.fr",
                "message": ""
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(try res.content.decode(ErrorResponse.self), ErrorResponse(error: true, reason: "Non-empty value required for key \'message\'"))
        })

        // Unvalid email
        try app.test(.POST, "feedback", beforeRequest: { req in
            try req.content.encode([
                "reason": "other",
                "language": "fr",
                "email": "hello, world!",
                "message": "Hi, there!"
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertEqual(try res.content.decode(ErrorResponse.self), ErrorResponse(error: true, reason: "Entered email is not a valid email"))
        })

        // No email - valid
        try app.test(.POST, "feedback", beforeRequest: { req in
            try req.content.encode([
                "reason": "feedback",
                "language": "fr",
                "message": "Hi, there!"
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        // Empty email - valid
        try app.test(.POST, "feedback", beforeRequest: { req in
            try req.content.encode([
                "reason": "feedback",
                "language": "fr",
                "email": "",
                "message": "Hi, there!"
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        // All keys, valid
        try app.test(.POST, "feedback", beforeRequest: { req in
            try req.content.encode([
                "reason": "other",
                "language": "en",
                "email": "test@test.fr",
                "message": "Hi, there!"
            ])
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })
    }
}
