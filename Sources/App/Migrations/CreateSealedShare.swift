//
//  CreateSealedShare.swift
//  
//
//  Created by Thomas Durand on 31/01/2022.
//

import Fluent

struct CreateSealedShare: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("sealed_shares")
            .id()
            .field("sealed", .data, .required)
            .field("key", .data, .required)
            .field("created_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("sealed_shares").delete()
    }
}
