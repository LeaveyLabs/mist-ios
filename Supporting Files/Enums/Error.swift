//
//  CustomError.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/17/22.
//

import Foundation

enum APIError: String, LocalizedError {
    
    case CouldNotConnect
    case ServerError
    case InvalidParameters
    case InvalidCredentials
    case NotFound
    case Timeout
    case Throttled
    case NoResponse
    case Unknown
    
    public var errorDescription: String? {
        switch self {
        case .CouldNotConnect:
            return NSLocalizedString("No internet connection.", comment: "")
        case .ServerError:
            return NSLocalizedString("Our servers are down", comment: "")
        case .InvalidParameters:
            return NSLocalizedString("Invalid parameters.", comment: "")
        case .InvalidCredentials:
            return NSLocalizedString("Invalid credentials.", comment: "")
        case .NotFound:
            return NSLocalizedString("Something went wrong.", comment: "")
        case .Timeout:
            return NSLocalizedString("Something went wrong.", comment: "")
        case .Throttled:
            return NSLocalizedString("Too many requests.", comment: "")
        case .NoResponse:
            return NSLocalizedString("Something went wrong.", comment: "")
        case .Unknown:
            return NSLocalizedString("Something went wrong.", comment: "")
        }
    }
    
//    public var failureReason: String?
    
    public var recoverySuggestion: String? {
        switch self {
        case .CouldNotConnect:
            return NSLocalizedString("Check your internet connection.", comment: "")
        case .ServerError:
            return NSLocalizedString("Please try again later.", comment: "")
        case .InvalidParameters:
            return NSLocalizedString("Please try again.", comment: "")
        case .InvalidCredentials:
            return NSLocalizedString("Please try again.", comment: "")
        case .NotFound:
            return NSLocalizedString("Please try again later.", comment: "")
        case .Timeout:
            return NSLocalizedString("Please try again later.", comment: "")
        case .Throttled:
            return NSLocalizedString("Yo chill out.", comment: "")
        case .NoResponse:
            return NSLocalizedString("Please try again later.", comment: "")
        case .Unknown:
            return NSLocalizedString("Please try again later.", comment: "")
        }
    }
}