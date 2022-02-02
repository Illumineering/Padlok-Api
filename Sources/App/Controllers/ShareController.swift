//
//  ShareController.swift
//  
//
//  Created by Thomas Durand on 30/01/2022.
//

import PadlokShare
import UUIDShortener
import Vapor

struct ShareController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("shared", ":identifier", use: decodeSharedInfos)
        // FIXME: Maybe this will be not necessary, preventing the back-end from ever decrypting the infos is better
        routes.get("shared", ":identifier", ":passphrase", use: decryptSharedInfos)
        routes.post("share", use: encodeSharedInfos)
    }

    private func decodeSharedInfos(req: Request) throws -> EventLoopFuture<SealedShare.Infos> {
        guard let shortIdentifier = req.parameters.get("identifier"),
              let identifier = try? UUID(shortened: shortIdentifier, using: .base62) else {
            throw Abort(.badRequest, reason: "Missing or unparsable identifier")
        }
        return SealedShare.find(identifier, on: req.db)
            .unwrap(or: Abort(.notFound))
            .map {
                req.logger.debug("SealedShare found", metadata: .none)
                return $0.infos
            }
    }

    // FIXME: Maybe this will be not necessary, preventing the back-end from ever decrypting the infos is better
    private func decryptSharedInfos(req: Request) throws -> EventLoopFuture<Models.Building> {
        guard let passphrase = req.parameters.get("passphrase") else {
            throw Abort(.badRequest, reason: "Missing passphrase")
        }
        return try decodeSharedInfos(req: req)
            .flatMapThrowing({ infos throws -> Models.Building in
                do {
                    guard let sealed = Data(base64Encoded: infos.sealed), let key = Data(base64Encoded: infos.key) else {
                        throw Abort(.notFound)
                    }
                    return try Crypto.open(.init(combined: sealed), using: .init(data: key), and: passphrase)
                } catch {
                    throw Abort(.notFound)
                }
            })
    }

    private func encodeSharedInfos(req: Request) throws -> EventLoopFuture<SealedShare.Output> {
        let infos = try req.content.decode(SealedShare.Infos.self)
        let sealedShare = SealedShare(infos: infos)
        return sealedShare.create(on: req.db).flatMapThrowing { try sealedShare.output() }
    }
}

extension Models.Building: Content {}
