//
//  configure.swift
//
//
//  Created by Thomas Durand on 22/01/2022.
//  Copyright © 2022 Padlok. All rights reserved.
//

import Vapor

extension DirectoryConfiguration {
    var dataDirectory: String {
        self.workingDirectory + "Data/"
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

// configures your application
public func configure(_ app: Application) throws {
    // Custom encoder/decoder strategies
    let encoder = JSONEncoder(), decoder = JSONDecoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    // register routes
    try routes(app)
}
