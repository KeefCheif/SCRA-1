//
//  GameError.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/31/22.
//

import Foundation

enum GameError: Error, LocalizedError {
    
    case getGameInfo
    case propogatedError(String)
    
    var errorDescription: String? {
        switch self {
        case .getGameInfo:
            return NSLocalizedString("Could not retrieve game info.", comment: "")
        case .propogatedError(let message):
            return NSLocalizedString(message, comment: "")
        }
    }
}

struct GameErrorType: Identifiable {
    let id = UUID()
    let error: GameError
}
