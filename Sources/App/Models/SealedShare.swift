//
//  SealedShare.swift
//  
//
//  Created by Thomas Durand on 30/01/2022.
//

import Fluent
import Vapor
import Require
import UUIDShortener

final class SealedShare: Model {
    static let schema = "sealed_shares"

    struct Infos: Content {
        let sealed: String
        let salt: String
        let iterations: Int
    }

    struct Output: Content {
        let identifier: String
        let adminToken: String
    }

    @ID(key: .id)
    var id: UUID?

    @Field(key: "infos")
    var infos: Infos

    @Field(key: "admin_token")
    var adminToken: String?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(id: UUID? = nil, infos: Infos) {
        self.id = id
        self.infos = infos
        self.adminToken = try? UUID().shortened(using: .base62)
    }

    func output() throws -> Output {
        let identifier = try self.requireID()
        return Output(identifier: try identifier.shortened(using: .base62), adminToken: adminToken.require())
    }
}
