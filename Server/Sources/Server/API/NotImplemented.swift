import PadlokAPIServer

/// An operation output that can answer 501 Not Implemented.
///
/// Every generated `Output` enum has an `undocumented(statusCode:_:)` case, and an enum
/// case can witness a static function requirement, so conforming takes nothing more than
/// an empty extension.
protocol NotImplementedResponse {
    static func undocumented(statusCode: Int, _ payload: UndocumentedPayload) -> Self
}

extension NotImplementedResponse {
    static var notImplemented: Self {
        .undocumented(statusCode: 501, .init())
    }
}

// Remove an operation from this list once it is implemented.
extension Operations.CreateShare.Output: NotImplementedResponse {}
extension Operations.GetShare.Output: NotImplementedResponse {}
extension Operations.UpdateShare.Output: NotImplementedResponse {}
extension Operations.DeleteShare.Output: NotImplementedResponse {}
extension Operations.UpdateShareLegacy.Output: NotImplementedResponse {}
extension Operations.DeleteShareLegacy.Output: NotImplementedResponse {}
