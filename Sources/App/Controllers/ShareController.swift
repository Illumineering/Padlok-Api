//
//  ShareController.swift
//  
//
//  Created by Thomas Durand on 30/01/2022.
//

import PadlokShare
import Vapor

struct ShareController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("shared", ":identifier", ":passphrase", use: decodeSharedInfos)
        routes.post("share", use: encodeSharedInfos)
    }

    private func decodeSharedInfos(req: Request) throws -> some ResponseEncodable {
        guard let shortIdentifier = req.parameters.get("identifier"), let identifier = UUID(shortened: shortIdentifier) else {
            throw Abort(.badRequest, reason: "Missing or unparsable identifier")
        }
        guard let passphrase = req.parameters.get("passphrase") else {
            throw Abort(.badRequest, reason: "Missing passphrase")
        }
        return SealedShare.find(identifier, on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMapThrowing({ sealedShare throws -> Models.Building in
                let infos = sealedShare.infos
                do {
                    return try Crypto.open(.init(combined: infos.sealed), using: .init(data: infos.key), and: passphrase)
                } catch {
                    throw Abort(.notFound)
                }
            })
    }

    private func encodeSharedInfos(req: Request) throws -> some ResponseEncodable {
        let infos = try req.content.decode(SealedShare.Infos.self)
        let sealedShare = SealedShare(infos: infos)
        return sealedShare.create(on: req.db).flatMapThrowing { try sealedShare.output() }
    }
}

extension Models.Building: Content {}
