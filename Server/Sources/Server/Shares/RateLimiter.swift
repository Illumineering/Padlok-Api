import Foundation
import HTTPTypes
import PadlokAPIServer

/// Counts events per key over a sliding window: at most `limit` within any `interval`.
///
/// In memory: one process serves the API, and losing the counts on a restart only gives
/// a client a fresh window.
actor RateLimiter {
    let limit: Int
    let interval: TimeInterval
    private let now: @Sendable () -> Date
    private var events: [String: [Date]] = [:]
    private var callsSinceSweep = 0

    init(limit: Int, interval: Duration, now: @escaping @Sendable () -> Date) {
        self.limit = limit
        self.interval = TimeInterval(interval.components.seconds)
        self.now = now
    }

    /// Records an event for `key`, unless it is over the limit: then nothing is recorded,
    /// and the result is how many seconds until it may try again.
    func consume(_ key: String) -> Int? {
        let now = now()
        if let wait = retryAfter(key, at: now) {
            return wait
        }
        events[key, default: []].append(now)
        return nil
    }

    /// How many seconds until `key` may try again, or `nil` when it is not over the limit.
    func retryAfter(_ key: String) -> Int? {
        retryAfter(key, at: now())
    }

    private func retryAfter(_ key: String, at now: Date) -> Int? {
        sweepOccasionally(at: now)
        let recent = (events[key] ?? []).filter { now.timeIntervalSince($0) < interval }
        events[key] = recent.isEmpty ? nil : recent
        guard recent.count >= limit, let oldest = recent.first else {
            return nil
        }
        return max(1, Int((oldest.addingTimeInterval(interval).timeIntervalSince(now)).rounded(.up)))
    }

    /// Forgets the keys that have been quiet for a whole window, so memory follows the
    /// recent clients rather than every client ever seen.
    private func sweepOccasionally(at now: Date) {
        callsSinceSweep += 1
        guard callsSinceSweep >= 1000 else {
            return
        }
        callsSinceSweep = 0
        events = events.filter { _, dates in dates.last.map { now.timeIntervalSince($0) < interval } ?? false }
    }
}

/// The two limits, per client IP, as the Symfony server had them.
struct RateLimits: Sendable {
    /// Creating a share is the only unauthenticated write.
    let shareCreation: RateLimiter
    /// Wrong admin tokens on PUT and DELETE. Successes are not counted, so an app updating
    /// its own share is never limited, and nobody can lock an owner out of their share.
    let adminTokenFailures: RateLimiter

    init(now: @escaping @Sendable () -> Date) {
        shareCreation = RateLimiter(limit: 20, interval: .seconds(3600), now: now)
        adminTokenFailures = RateLimiter(limit: 10, interval: .seconds(3600), now: now)
    }
}

/// Limits share creation per client IP before the body is even read, so refused requests
/// cost nothing. Every attempt counts, valid or not.
struct ShareCreationLimitMiddleware: ServerMiddleware {
    let limiter: RateLimiter

    func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        metadata: ServerRequestMetadata,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, ServerRequestMetadata) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        guard operationID == Operations.CreateShare.id else {
            return try await next(request, body, metadata)
        }
        if let wait = await limiter.consume(RequestInfo.clientIP) {
            return Components.Schemas.Problem.response(
                .tooManyRequests,
                detail: "Too many shares created from this address, retry later.",
                headerFields: [.retryAfter: "\(wait)"]
            )
        }
        return try await next(request, body, metadata)
    }
}
