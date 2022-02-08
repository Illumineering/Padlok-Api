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
        routes.post("share", use: encodeSharedInfos)
        routes.put("shared", ":identifier", ":adminToken", use: updateSharedInfos)
        routes.delete("shared", ":identifier", ":adminToken", use: deleteSharedInfos)
    }

    private func find(_ shortIdentifier: String, from req: Request) throws -> EventLoopFuture<SealedShare> {
        guard let identifier = try? UUID(shortened: shortIdentifier, using: .base62) else {
            throw Abort(.badRequest, reason: "Unparsable identifier")
        }
        return SealedShare.find(identifier, on: req.db).unwrap(or: Abort(.notFound))
    }

    private func findForAdmin(_ shortIdentifier: String, adminToken: String, from req: Request) throws -> EventLoopFuture<SealedShare> {
        try find(shortIdentifier, from: req)
            .guard({ $0.adminToken == adminToken }, else: Abort(.notFound))
    }

    private func decodeSharedInfos(req: Request) throws -> EventLoopFuture<SealedShare.Infos> {
        guard let shortIdentifier = req.parameters.get("identifier") else {
            throw Abort(.badRequest, reason: "Missing identifier")
        }
        return try find(shortIdentifier, from: req).map {
            req.logger.debug("SealedShare found", metadata: .none)
            return $0.infos
        }
    }

    private func encodeSharedInfos(req: Request) throws -> EventLoopFuture<SealedShare.Output> {
        let infos = try req.content.decode(SealedShare.Infos.self)
        let sealedShare = SealedShare(infos: infos)
        return sealedShare.create(on: req.db).flatMapThrowing { try sealedShare.output() }
    }

    private func updateSharedInfos(req: Request) throws -> EventLoopFuture<Response> {
        guard let shortIdentifier = req.parameters.get("identifier") else {
            throw Abort(.badRequest, reason: "Missing identifier")
        }
        guard let adminToken = req.parameters.get("adminToken") else {
            throw Abort(.badRequest, reason: "Missing adminToken")
        }
        return try findForAdmin(shortIdentifier, adminToken: adminToken, from: req)
            .tryFlatMap({
                $0.infos = try req.content.decode(SealedShare.Infos.self)
                return $0.update(on: req.db).map({
                    return Response(status: .ok)
                })
            })
    }

    private func deleteSharedInfos(req: Request) throws -> EventLoopFuture<Response> {
        guard let shortIdentifier = req.parameters.get("identifier") else {
            throw Abort(.badRequest, reason: "Missing identifier")
        }
        guard let adminToken = req.parameters.get("adminToken") else {
            throw Abort(.badRequest, reason: "Missing adminToken")
        }
        return try findForAdmin(shortIdentifier, adminToken: adminToken, from: req)
            .tryFlatMap({
                return $0.delete(on: req.db).map({
                    return Response(status: .ok)
                })
            })
    }
}

extension Models.Building: Content {}
