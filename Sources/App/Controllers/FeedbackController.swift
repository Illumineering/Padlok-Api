//
//  FeedbackController.swift
//  
//
//  Created by Thomas Durand on 30/01/2022.
//

import Vapor

struct FeedbackController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("feedback", use: registerFeedback)
    }

    private func registerFeedback(req: Request) throws -> Response {
        let feedback = try req.content.decode(Feedback.self)
        if req.application.environment.shouldWriteFile {
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
