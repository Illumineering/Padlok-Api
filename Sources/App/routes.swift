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

    // Added FAQ
    app.on(.GET, "faq") { req in
        return Options.adapted(for: .from(headers: req.headers)).faq
    }

    // Retreiving feedback from users
    try app.register(collection: FeedbackController())

    // Share & retreive shared data
    try app.register(collection: ShareController())
}
