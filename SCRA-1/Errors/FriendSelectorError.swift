//
//  FriendSelectorError.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/25/22.
//

import Foundation

enum FriendSelectorError: Error, LocalizedError {

    case notLoggedIn
    case unknown
    case openDocument
    
    // Send Friend Request Errors
    case selfRequest
    case userNotFound
    case alreadySentRequest
    case alreadyRecievedRequest
    case alreadyFriends
    
    // Respond Friend Request Message (Technically not an error)
    case respondFriendRequest(String)
    
    case propogatedError(String)
    
    var errorDescription: String? {
        switch self {
        case .notLoggedIn:
            return NSLocalizedString("Error: You are no longer logged in. Try signing out and signing back in.", comment: "")
        case .unknown:
            return NSLocalizedString("An unknown error was encountered while retrieving friend info", comment: "")
        case .openDocument:
            return NSLocalizedString("Error: could not access or find user document", comment: "")
        case .selfRequest:
            return NSLocalizedString("You cannot send a friend request to yourself nerd.", comment: "")
        case .userNotFound:
            return NSLocalizedString("A user with that username could not be found. Please try a different username. Capitalization does not matter.", comment: "")
        case .alreadySentRequest:
            return NSLocalizedString("This user already has a friend request from you. You cannot send another one.", comment: "")
        case .alreadyRecievedRequest:
            return NSLocalizedString("You already have a friend request from this user. Accept their friend request instead of sending them one.", comment: "")
        case .alreadyFriends:
            return NSLocalizedString("You are already friends with this user.", comment: "")
        case .respondFriendRequest(let username):
            return NSLocalizedString("Accept friend request from \(username)?", comment: "")
        case .propogatedError(let message):
            return NSLocalizedString(message, comment: "")
        }
    }
}

struct FriendSelectorErrorType: Identifiable {
    let id = UUID()
    let error: FriendSelectorError
}
