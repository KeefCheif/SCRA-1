//
//  GameSelectorError.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/28/22.
//

import Foundation

enum GameSelectorError: Error, LocalizedError {
    
    case notLoggedIn
    case unknown
    
    // Errors for multiplayer game invite
    case noFriends
    case featureUnavailable(String)
    
    // Invite to game confirmation alert
    case invitePlayer(String)
    
    case propogatedError(String)
    
    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return NSLocalizedString("Error: You are no longer logged in. Try signing out and signing back in.", comment: "")
        case .unknown:
            return NSLocalizedString("An unknown error was encountered while retrieving friend info.", comment: "")
        case .noFriends:
            return NSLocalizedString("You do not have any friends to invite to a game.", comment: "")
        case .featureUnavailable(let feature):
            return NSLocalizedString("Sorry, but \(feature) is not available yet.", comment: "")
        case .invitePlayer(let username):
            return NSLocalizedString("Would you like to invite \(username) to a game?", comment: "")
        case .propogatedError(let message):
            return NSLocalizedString(message, comment: "")
        }
    }
}

struct GameSelectorErrorType: Identifiable {
    let id = UUID()
    let error: GameSelectorError
}
