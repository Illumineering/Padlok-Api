//
//  Language.swift
//  
//
//  Created by Thomas Durand on 23/01/2022.
//  Copyright © 2022 Padlok. All rights reserved.
//

import Vapor

enum Language: String, Content {
    case english = "en"
    case french = "fr"

    static func from(headers: HTTPHeaders, defaultValue: Language = .english) -> Language {
        guard let langHeader = headers.first(name: .acceptLanguage) else {
            return defaultValue
        }
        guard let langcode = langHeader.components(separatedBy: "-").first else {
            return defaultValue
        }
        return Language(rawValue: langcode) ?? defaultValue
    }
}
