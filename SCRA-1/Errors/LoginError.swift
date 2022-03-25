//
//  LoginErrors.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/21/22.
//

import Foundation

enum LoginError: Error, LocalizedError {
    
    case failedSignIn
    case passwordMismatch
    case usernameTaken
    case usernameInvalid
    case usernameTooLong
    case usernameTooShort
    case propogatedError(String)
    
    var errorDescription: String? {
        switch self {
        case .failedSignIn:
            return NSLocalizedString("Email or password was incorrect.", comment: "")
        case .passwordMismatch:
            return NSLocalizedString("Password does not match the confirmed password.", comment: "")
        case .usernameTaken:
            return NSLocalizedString("This username is already taken. Please try a different one.", comment: "")
        case .usernameInvalid:
            return NSLocalizedString("This username is incorrectly formatted. Only numbers, letters, and underscores are allowed.", comment: "")
        case .usernameTooLong:
            return NSLocalizedString("Your username is too long. The limit is 20 characters.", comment: "")
        case .usernameTooShort:
            return NSLocalizedString("Your username is too short. It must be at least 2 characters", comment: "")
        case .propogatedError(let message):
            return NSLocalizedString(message, comment: "")
        }
    }
}

struct LoginErrorType: Identifiable {
    let id = UUID()
    let error: LoginError
}

