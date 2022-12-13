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
        case feedback, feature, bug, help, other
    }

    let language: String
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

    func enrich(using headers: HTTPHeaders) -> ContextualizedFeedback {
        .init(
            feedback: self,
            appVersion: headers["App-Version"].first,
            customer: headers["Customer-Identifier"].first,
            device: headers["Device"].first,
            downloadDate: headers["Download-Date"].first,
            osName: headers["OS-Name"].first,
            osVersion: headers["OS-Version"].first
        )
    }
}

struct ContextualizedFeedback {
    let feedback: Feedback
    let appVersion: String?
    let customer: String?
    let device: String?
    let downloadDate: String?
    let osName: String?
    let osVersion: String?
}

extension ContextualizedFeedback: CustomStringConvertible {
    var description: String {
        return """
App Version: \(appVersion ?? "Unknown")
Customer ID: \(customer ?? "Unknown")
Date: \(Date())
Device: \(device ?? "Unknown")
Download date: \(downloadDate ?? "Unknown")
Language: \(feedback.language)
Mail: \(feedback.email ?? "Unknown")
OS Name: \(osName ?? "Unknown")
OS Version: \(osVersion ?? "Unknown")
----
Reason: \(feedback.reason)
Message: \(feedback.message)
"""
    }
}
