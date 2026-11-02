import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public enum APIError: Error, LocalizedError {
    case parser(Error)
    case requestParameters(Error)
    case body(Error)
    case client(String)
    case createQueryParameter(String)
    case response(String)
    case apiError(String?, statusCode: Int?)
    case unknown
    case unauthorized
    case unauthenticated
    case statusCode
    case certificatePinningFailed(String)
}
