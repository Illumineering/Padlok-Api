//
//  Options.swift
//
//
//  Created by Thomas Durand on 23/01/2022.
//  Copyright © 2022 Padlok. All rights reserved.
//

import Require
import Vapor

struct Options: Content, Equatable {
    struct URLs: Content, Equatable {
        let appstore: URL
        let faq: URL
        let marketing: URL
        let privacy: URL
        let support: URL
        let terms: URL
        let twitter: URL

        static func adapted(for language: Language) -> URLs {
            let twitter: URL = "https://twitter.com/PadlokApp"
            switch language {
            case .english:
                return .init(
                    appstore: "https://apps.apple.com/us/app/padlok/id1546719801",
                    faq: "https://padlok.app/frequently-asked-questions/",
                    marketing: "https://padlok.app",
                    privacy: "https://padlok.app/privacy",
                    support: "https://padlok.app/support",
                    terms: "https://padlok.app/terms",
                    twitter: twitter
                )
            case .french:
                return .init(
                    appstore: "https://apps.apple.com/fr/app/padlok/id1546719801",
                    faq: "https://padlok.app/fr/foire-aux-questions/",
                    marketing: "https://padlok.app/fr",
                    privacy: "https://padlok.app/fr/confidentialite",
                    support: "https://padlok.app/fr/assistance",
                    terms: "https://padlok.app/fr/conditions",
                    twitter: twitter
                )
            }
        }
    }

    /// An arbitrary version number to provide information regarding the API ; like when deprecating stuff
    let apiVersion: String
    /// An array of questions/anwsers for frequently asked questions
    let faq: [FrequentlyAskedQuestion]
    /// Sentry traces sample rate, to increase or decrease the number of events reported to Sentry API
    let eventSampleRate: Double
    /// Sentry traces sample rate, to increase or decrease the number of events reported to Sentry API
    let profilesSampleRate: Double
    /// Sentry traces sample rate, to increase or decrease the number of events reported to Sentry API
    let tracesSampleRate: Double
    /// URLs used by the application for different subset of the application
    let urls: URLs

    static func adapted(for language: Language) -> Options {
        Options(
            apiVersion: "4.0.0",
            faq: .adapted(for: language),
            eventSampleRate: 0.66,
            profilesSampleRate: 0.1,
            tracesSampleRate: 0.66,
            urls: .adapted(for: language)
        )
    }
}

extension URL: ExpressibleByStringLiteral {
    public init(stringLiteral value: StaticString) {
        self = URL(string: "\(value)").require(hint: "Invalid URL string literal: \(value)")
    }
}
