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

        if email != nil && !isEmailValid {
            throw Abort(.badRequest, reason: "Entered email is not a valid email")
        }
    }

    var isEmailValid: Bool {
        guard let email = email?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        guard let dataDetector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return false
        }
        let range = NSMakeRange(0, NSString(string: email).length)
        let allMatches = dataDetector.matches(in: email, options: [], range: range)
        return allMatches.count == 1 && allMatches.first?.url?.absoluteString.contains("mailto:") == true
    }
}

extension Feedback {
    func send() throws {
        // TODO: find a way to deal with mails here
        print(self)
    }
}
