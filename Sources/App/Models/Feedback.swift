//
//  Feedback.swift
//  
//
//  Created by Thomas Durand on 23/01/2022.
//  Copyright © 2022 Padlok. All rights reserved.
//

import Vapor

struct Feedback: Content {
    struct Redirect: Content {
        var redirect: String
    }

    enum Reason: String, Content {
        case feedback, feature, bug, other
    }

    let language: Language
    let reason: Reason
    let email: String?
    let message: String

    func afterDecode() throws {
        if message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Empty message
            throw Abort(.badRequest, reason: "Non-empty value required for key 'message'")
        }

        if let email = email, !email.isEmpty, Validator.internationalEmail.validate(email).isFailure {
            throw Abort(.badRequest, reason: "Entered email is not a valid email")
        }
    }
}

extension Feedback: CustomStringConvertible {
    var description: String {
        return """
Date: \(Date())
Reason: \(reason)
Language: \(language)
Mail: \(email ?? "Unknown")
Message: \(message)
"""
    }
}
