//
//  GameError.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/31/22.
//

import Foundation

enum GameError: Error, LocalizedError {
    
    case getGameInfo
    case lostTurn([String])
    case propogatedError(String)
    
    // Challenge Alerts
    case lostChallenge
    case wonChallenge([String])
    
    var errorDescription: String? {
        switch self {
        case .getGameInfo:
            return NSLocalizedString("Could not retrieve game info.", comment: "")
        case .lostTurn(let invalid_word):
            let grammar: (String, String) = invalid_word.count > 1 ? ("words", "were") : ("word" ,"was")
            return NSLocalizedString("Your last move was removed because it was challenged by your opponent and the \(grammar.0): '\(invalid_word)' \(grammar.1) invalid. The letters you drew last turn were put back in the bag and your old letters have been returned to you.", comment: "")
        case .propogatedError(let message):
            return NSLocalizedString(message, comment: "")
            
        case .lostChallenge:
            return NSLocalizedString("Sorry, but all of the words played during your opponent's last turn are valid.", comment: "")
        case .wonChallenge(let invalid_words):
            var words: String = ""
            for (index, word) in invalid_words.enumerated() {
                words += word
                if index != invalid_words.count - 1 {
                    words += ", "
                }
            }
            let grammar: String = words.count > 1 ? "where" : "was"
            return NSLocalizedString("Congradulations, '\(invalid_words)' \(grammar) invalid. Your opponents last turn will now be undone", comment: "")
        }
    }
}

struct GameErrorType: Identifiable {
    let id = UUID()
    let error: GameError
}
