//
//  AppTests.swift
//
//
//  Created by Thomas Durand on 22/01/2022.
//  Copyright © 2022 Padlok. All rights reserved.
//

@testable import PadlokShare
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

    func testShareFeature() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        try configure(app)

        let salt = "ZZ9kHI6uEyw="
        let sealed = "hI7vl1On13OSsr+cf7Y/2ue5k4+S3yvNaxdr2n0UAW0P3PpXGF9xytPd8wQ+jXpj0CGSiUqeVIQxYqm3X6JN2GObVHNvs9E88piLEe+Pie6W0ToEm25vzK6tEahpy8dijLbUeDvOVT6N18KBy5UW4I6sxo5EajwV8CrfM37YW4rOt/FTffjVrN1D0F2uJnD7GYn2lddb+bR+ZLDmVhKRklJNXpt9vhPllgq4GDgG7zHMseUGy01cvfcP+jUQYIDeu1yLufKEcZsnPK6HAGhMYQYMNkwS1ynGGbVbLtsRDsfOZTsBzAKsIfB1iePYB28NsBqWPzkUbMXT+jwCJyuEWmEZN9Ka4dCZ9/PEBbTaUbYKM/xUWpLJF/69aYvvKMzeQLKOPKlgKodpAIwkOiNhDiOFM0Ve0SRkaC+c4JO8/IGrmFOJhABBkOpUssVe2L33nymvprCqQo7sVTZgcWTizGPPzMHTiEB2wHF8AcvcCvO3eiyZSmqHCANAZ4D/shuBxlObi4/AUVMScqWI2eZ2Z7fM7EMP92ZsYEMUKk6NX9dpJqmdtrZR+bjqgEAnab2g7THf153YlxNWTVoxQbGjYk/VCl2BDDQRfKecelR/7d5hmpnfQbphZEeIe0vynl78VZlevugmUGkU0cg/ze835z4aZ7zX+zfg"

        // Post a building to be shared
        var output: SealedShare.Output?
        try app.test(.POST, "share", beforeRequest: { req in
            try req.content.encode(SealedShare.Infos(sealed: sealed, salt: salt, iterations: 1000))
        }, afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
            output = try res.content.decode(SealedShare.Output.self)
        })

        // Try to get this building data now
        if let output = output {
            // Test without passphrase
            try app.test(.GET, "shared/\(output.identifier)") { res in
                XCTAssertEqual(res.status, .ok)
                do {
                    let infos = try res.content.decode(SealedShare.Infos.self)
                    XCTAssertEqual(infos.sealed, sealed)
                    XCTAssertEqual(infos.salt, salt)
                    XCTAssertEqual(infos.iterations, 1000)
                } catch {
                    XCTFail("Data should be decoded as SealedShare.Infos.")
                }
            }

            // Test with correct passphrase
            try app.test(.GET, "shared/\(output.identifier)/K2lZHO6q6akZ") { res in
                XCTAssertEqual(res.status, .ok)
                do {
                    let building = try res.content.decode(Models.Building.self)
                    XCTAssertEqual(building.address, "55 de la rue du Faubourg-Saint-Honoré")
                    XCTAssertEqual(building.coordinates.latitude, 48.869978342034287)
                    XCTAssertEqual(building.coordinates.longitude, 2.3165022395478303)
                    XCTAssertEqual(building.building, "Principal")
                    XCTAssertEqual(building.intercom, "M. le Président")
                    XCTAssertEqual(building.staircase, "Principal")
                    XCTAssertEqual(building.floor, 1)
                    XCTAssertEqual(building.doors.count, 4)
                    XCTAssertEqual(building.doors[0].label, .door)
                    XCTAssertEqual(building.doors[1].label, .gate)
                    XCTAssertEqual(building.doors[2].label, .portal)
                    XCTAssertEqual(building.doors[3].label, .custom(string: "Porte Jupiter"))
                    XCTAssertEqual(building.doors[0].code, "AB23C")
                    XCTAssertEqual(building.doors[1].code, "P12BD")
                    XCTAssertEqual(building.doors[2].code, "GUARD")
                    XCTAssertEqual(building.doors[3].code, "19B29B02")
                } catch {
                    XCTFail("Data should be decoded as Models.Building.")
                }
            }

            // Test with incorrect passphrase
            try app.test(.GET, "shared/\(output.identifier)/abcdefghijkl") { res in
                XCTAssertEqual(res.status, .notFound)
            }
        } else {
            XCTFail("Could not get output from previous test")
        }

        // Test with unknown identifier
        try app.test(.GET, "shared/\(try UUID().shortened(using: .base62))") { res in
            XCTAssertEqual(res.status, .notFound)
        }

        // Test with unknown identifier
        try app.test(.GET, "shared/\(try UUID().shortened(using: .base62))/abcdefghijkl") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }
}
