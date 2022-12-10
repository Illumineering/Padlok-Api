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
                "reason": "help",
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

        let salt = "kLpHPb2zsjo="
        let sealed = "rphyE9rfNKrLwupKCR7bSTTOxlm++joQFqiR8UOYfXKFw2D9oQ/bo1gtFFYwre7El4AUWyA64MatY6KVAhJu9EBErzMyIRM4ezZU76rovsbM27W20FEBRqIlE1msM92MirPTb6/koZhSp2vr1jH62fayfVwt2uckC5iRMLolxrFCylKxToi+qyXzr6KPETJR1Rzf9W5P1JmAC209nkoA6LduKKPYhiYguecmWawYdfJEmtmlnfMPZMTTGWrAgJ4yW/hxqeMqgSaFi5495FficfqlBx6eieH20NtW58BFt0uX4tGKLyHtJU/XVMeayOcV4cBHK87MToZNevRTtjf2zq8Pdk3YxerNOzPBDzeX17NJvq0s6mAGg5brQouwT/1GxYbWkDhUjb/ztJVm706ruGsUtqtk5ohtYW88J2lk/95qW0/GLhlzwaBEXEYXoUBmEp6nDuvDa86KG9JWmYwCaXnGezsEc64Qh1ZfsCtfDL+Xp2W4jqdKMPtgFwnC3jO+10uqr+iOuUktkU0dTC7UHKs1OPala4vY8Y0ZS54z062rrRbgp+gj5EBQh0yejZPfVoxU8ySfQoj6fmB7CFpuVP/dSutCTbIi0F8z8SjAwJgBSFreYyoHQPS7+7628TPcGUa57OGrXAWTa5Xz8+TiYyYek+jxkriaadHIeMj94QiqpbSMFHQ+dCuS1+zLsR3r"

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

            // TODO: .PUT tests for editing a shared info

            // Wrong admin token
            try app.test(.DELETE, "shared/\(output.identifier)/abcdef") { res in
                XCTAssertEqual(res.status, .notFound)
            }
            // Should still be here
            try app.test(.GET, "shared/\(output.identifier)") { res in
                XCTAssertEqual(res.status, .ok)
            }
            // Now we delete it
            try app.test(.DELETE, "shared/\(output.identifier)/\(output.adminToken)") { res in
                XCTAssertEqual(res.status, .ok)
            }
            // And try to fetch it again
            try app.test(.GET, "shared/\(output.identifier)") { res in
                XCTAssertEqual(res.status, .notFound)
            }
        } else {
            XCTFail("Could not get output from previous test")
        }

        // Test with unknown identifier
        try app.test(.GET, "shared/\(try UUID().shortened(using: .base62))") { res in
            XCTAssertEqual(res.status, .notFound)
        }
    }
}
