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
            return NSLocalizedString("Poor internet connection", comment: "")
        case .ServerError:
            return NSLocalizedString("Our servers are down", comment: "")
        case .ClientError(let errorDescription, _):
            return NSLocalizedString(errorDescription, comment: "")
        case .Unauthorized:
            return NSLocalizedString("Something went wrong", comment: "")
        case .Forbidden:
            return NSLocalizedString("Something went wrong", comment: "")
        case .NotFound:
            return NSLocalizedString("Something went wrong", comment: "")
        case .Timeout:
            return NSLocalizedString("Something went wrong", comment: "")
        case .Throttled:
            return NSLocalizedString("Too many requests", comment: "")
        case .NoResponse:
            return NSLocalizedString("Something went wrong", comment: "")
        case .Unknown:
            return NSLocalizedString("Something went wrong", comment: "")
        }
    }
    
//    public var failureReason: String?
    
    public var recoverySuggestion: String? {
        switch self {
        case .CouldNotConnect:
            return NSLocalizedString("Try again later", comment: "")
        case .ServerError:
            return NSLocalizedString("Try again later", comment: "")
        case .ClientError(_, let recoverySuggession):
            return NSLocalizedString(recoverySuggession, comment: "")
        case .Unauthorized:
            return NSLocalizedString("Try again later", comment: "")
        case .Forbidden:
            return NSLocalizedString("Try again later", comment: "")
        case .NotFound:
            return NSLocalizedString("Try again later", comment: "")
        case .Timeout:
            return NSLocalizedString("Try again later", comment: "")
        case .Throttled:
            return NSLocalizedString("Yo chill out", comment: "")
        case .NoResponse:
            return NSLocalizedString("Try again later", comment: "")
        case .Unknown:
            return NSLocalizedString("Try again later", comment: "")
        }
    }
}
