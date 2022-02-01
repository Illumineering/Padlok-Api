//
//  SealedShare.swift
//  
//
//  Created by Thomas Durand on 30/01/2022.
//

import Fluent
import Vapor
import UUIDShortener

final class SealedShare: Model {
    static let schema = "sealed_shares"

    struct Infos: Content {
        let sealed: Data
        let key: Data
    }

    struct Output: Content {
        let identifier: String
    }

    @ID(key: .id)
    var id: UUID?

    @Field(key: "sealed")
    var sealed: Data

    @Field(key: "key")
    var key: Data

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    var infos: Infos {
        .init(sealed: sealed, key: key)
    }

    init() {}

    init(id: UUID? = nil, infos: Infos) {
        self.id = id
        self.sealed = infos.sealed
        self.key = infos.key
    }

    func output() throws -> Output {
        let identifier = try self.requireID()
        return Output(identifier: try identifier.shortened(using: .base62))
    }
}
