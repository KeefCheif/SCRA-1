//
//  GameAlert.swift
//  SCRA-1
//
//  Created by peter allgeier on 4/8/22.
//

import Foundation

enum GameAlert: Error, LocalizedError {
    
    case lostLastTurn([String])
    case lostCurrentTurn
    case opponentLostTurn
    case gameOver([(String, Int)])
    case opponentResigned
    case errorGettingGame
    
    var errorDescription: String? {
        switch self {
        case .lostLastTurn(let invalid_words):
            
            var string_words: String = ""
            for (index, word) in invalid_words.enumerated() {
                string_words += word
                if index != invalid_words.count - 1 {
                    string_words += ", "
                }
            }
            let grammar: String = invalid_words.count > 1 ? "were" : "was"
            return NSLocalizedString("Your last turn was undone because your opponent challenged it and \(string_words) \(grammar) invalid.", comment: "")
            
        case .lostCurrentTurn:
            return NSLocalizedString("You have lost your current turn because you left the game during your turn with a time limit enabled.", comment: "")
            
        case .opponentLostTurn:
            return NSLocalizedString("Your opponent lost their turn because they left during their turn withh a timit limit enabled.", comment: "")
            
        case .gameOver(let score):
            return NSLocalizedString("The game is over the final score is \(score[0].0): \(score[0].1) to \(score[1].0): \(score[1].1)", comment: "")
        case .opponentResigned:
            return NSLocalizedString("Your opponent has resigned.", comment: "")
        case .errorGettingGame:
            return NSLocalizedString("An error occured while getting the information for the game.", comment: "")
        }
    }
}

struct GameAlertType: Identifiable {
    let id = UUID()
    let error: GameAlert
}
