//
//  configure.swift
//
//
//  Created by Thomas Durand on 22/01/2022.
//  Copyright © 2022 Padlok. All rights reserved.
//

import Fluent
import FluentMySQLDriver
import FluentSQLiteDriver
import Vapor

extension DirectoryConfiguration {
    var dataDirectory: String {
        self.workingDirectory + "Data/"
    }
}

extension Environment {
    @available(*, deprecated, message: "File creation should be replaced by a db insert instead")
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
    // register database
    if let username = Environment.get("DATABASE_USERNAME"),
        let password = Environment.get("DATABASE_PASSWORD"),
        let database = Environment.get("DATABASE_NAME") {
        app.databases.use(.mysql(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? MySQLConfiguration.ianaPortNumber,
            username: username,
            password: password,
            database: database
        ), as: .mysql)
    } else {
        // In-memory for testing :)
        app.databases.use(.sqlite(), as: .sqlite)
    }

    // Perform migrations
    app.migrations.add(CreateSealedShare())
    try app.autoMigrate().wait()

    // register routes
    try routes(app)
}
