//
//  routes.swift
//
//
//  Created by Thomas Durand on 22/01/2022.
//  Copyright © 2022 Padlok. All rights reserved.
//

import Vapor

func routes(_ app: Application) throws {
    // Redirect to marketing website when a simple get is made
    app.get { req in
        return Response(status: .found, headers: [
            HTTPHeaders.Name.location.description: Options.adapted(for: .from(headers: req.headers)).urls.marketing.absoluteString
        ])
    }

    // Sending localized app options and parameters
    app.on(.OPTIONS) { req in
        return Options.adapted(for: .from(headers: req.headers))
    }

    // Retreiving feedback from users
    app.post("feedback") { req throws -> Response in
        let feedback = try req.content.decode(Feedback.self)
        if app.environment.shouldWriteFile {
            let path = req.application.directory.dataDirectory + UUID().uuidString + ".txt"
            try feedback.description.write(toFile: path, atomically: true, encoding: .utf8)
        }
        // Redirect users when there is one provided ; used by the front
        guard let redirect = try? req.query.decode(Feedback.Redirect.self), redirect.redirect.hasPrefix("https://padlok.app/") else {
            // Otherwise, a simple 200 status will be enough
            return Response(status: .ok)
        }
        return Response(status: .found, headers: [
            HTTPHeaders.Name.location.description: redirect.redirect
        ])
    }
}

extension Environment {
    var shouldWriteFile: Bool {
        switch self {
        case .testing:
            return false
        default:
            return true
        }
    }
}
