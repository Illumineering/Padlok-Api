//
//  configure.swift
//
//
//  Created by Thomas Durand on 22/01/2022.
//  Copyright © 2022 Padlok. All rights reserved.
//

import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // register routes
    try routes(app)
}
