//
//  CreateSealedShare.swift
//  
//
//  Created by Thomas Durand on 31/01/2022.
//

import Fluent
import FluentSQL

struct CreateSealedShare: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("sealed_shares")
            .id()
            .field("infos", .dictionary, .required)
            .field("created_at", .datetime, .required)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema("sealed_shares").delete()
    }
}
