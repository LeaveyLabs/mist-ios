//
//  CustomError.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/17/22.
//

import Foundation

enum APIError: Error, Equatable {
    
    case CouldNotConnect
    case ServerError
    case ClientError(String, String)
    case Unauthorized
    case Forbidden
    case NotFound
    case Timeout
    case Throttled
    case NoResponse
    case Unknown
    
    public var errorDescription: String? {
        switch self {
        case .CouldNotConnect:
            return NSLocalizedString("poor internet connection", comment: "")
        case .ServerError:
            return NSLocalizedString("our servers are down", comment: "")
        case .ClientError(let errorDescription, _):
            return NSLocalizedString(errorDescription.lowercased(), comment: "")
        case .Unauthorized:
            return NSLocalizedString("something went wrong", comment: "")
        case .Forbidden:
            return NSLocalizedString("something went wrong", comment: "")
        case .NotFound:
            return NSLocalizedString("something went wrong", comment: "")
        case .Timeout:
            return NSLocalizedString("something went wrong", comment: "")
        case .Throttled:
            return NSLocalizedString("too many requests", comment: "")
        case .NoResponse:
            return NSLocalizedString("something went wrong", comment: "")
        case .Unknown:
            return NSLocalizedString("something went wrong", comment: "")
        }
    }
    
//    public var failureReason: String?
    
    public var recoverySuggestion: String? {
        switch self {
        case .CouldNotConnect:
            return NSLocalizedString("try again later", comment: "")
        case .ServerError:
            return NSLocalizedString("try again later", comment: "")
        case .ClientError(_, let recoverySuggession):
            return NSLocalizedString(recoverySuggession.lowercased(), comment: "")
        case .Unauthorized:
            return NSLocalizedString("try again later", comment: "")
        case .Forbidden:
            return NSLocalizedString("try again later", comment: "")
        case .NotFound:
            return NSLocalizedString("try again later", comment: "")
        case .Timeout:
            return NSLocalizedString("try again later", comment: "")
        case .Throttled:
            return NSLocalizedString("yo chill out", comment: "")
        case .NoResponse:
            return NSLocalizedString("try again later", comment: "")
        case .Unknown:
            return NSLocalizedString("try again later", comment: "")
        }
    }
}
