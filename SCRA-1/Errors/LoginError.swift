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
    case propogatedError(String)
    
    var errorDescription: String? {
        switch self {
        case .failedSignIn:
            return NSLocalizedString("Email or password was incorrect", comment: "")
        case .passwordMismatch:
            return NSLocalizedString("Password does not match the confirmed password", comment: "")
        case .propogatedError(let message):
            return NSLocalizedString(message, comment: "")
        }
    }
}

struct LoginErrorType: Identifiable {
    let id = UUID()
    let error: LoginError
}

