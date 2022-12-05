//
//  FeedbackController.swift
//  
//
//  Created by Thomas Durand on 30/01/2022.
//

import SMTPKitten
import Vapor
import VaporSMTPKit

struct FeedbackController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.post("feedback", use: registerFeedback)
    }

    private func registerFeedback(req: Request) async throws -> Response {
        // Always decode first, otherwise error will not throw in tests, because shouldSendMail == false
        var feedback = try req.content.decode(Feedback.self).enrich(using: req.headers)

        // Save a file
        if req.application.environment.shouldWriteFile {
            let path = req.application.directory.dataDirectory + UUID().uuidString + ".txt"
            try feedback.description.write(toFile: path, atomically: true, encoding: .utf8)
        }

        // Send a mail
        if req.application.environment.shouldSendMail {
            guard let smtp = SMTPCredentials.default,
                  let to = Environment.get("SUPPORT_EMAIL") else {
                return Response(status: .internalServerError)
            }
            let mail = Mail(
                from: .init(name: "Padlok Bot", email: "no_reply@padlok.app"),
                to: [.init(stringLiteral: to)],
                subject: "Feedback received!",
                contentType: .plain,
                text: feedback.description
            )
            try await req.application.sendMail(mail, withCredentials: smtp).get()
        }

        // Redirect users when there is one provided ; used by the front
        if let redirect = try? req.query.decode(Feedback.Redirect.self), redirect.redirect.hasPrefix("https://padlok.app/") {
            return Response(status: .found, headers: [
                HTTPHeaders.Name.location.description: redirect.redirect
            ])
        }
        // Otherwise, a simple 200 status will be enough
        return Response(status: .ok)
    }
}
