//
//  ChallengeAlerts.swift
//  SCRA-1
//
//  Created by peter allgeier on 4/8/22.
//

import Foundation

enum ChallengeAlert: Error, LocalizedError {
    
    // Challenge Alerts
    case cannotChallenge(String)
    case challengeAlert([String])
    case lostChallenge
    case wonChallenge([String])
    
    var errorDescription: String? {
        switch self {
            
        case .cannotChallenge(let reason):
            return NSLocalizedString("You cannot challenge your opponents last turn because \(reason).", comment: "")
            
        case .challengeAlert(let words):
            var string_words: String = ""
            for (index, word) in words.enumerated() {
                string_words += word
                if index != words.count - 1 {
                    string_words += ", "
                }
            }
            return NSLocalizedString("Last turn your opponent played the word(s): \(string_words). Would you like to challenge these words? (If any of them are not real words then your challenge will be successful)", comment: "")
            
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
            let grammar: String = words.count > 1 ? "were" : "was"
            return NSLocalizedString("Congradulations, '\(words)' \(grammar) invalid. Your opponents last turn will now be undone", comment: "")
        }
    }
}

struct ChallengeAlertType: Identifiable {
    let id = UUID()
    let error: ChallengeAlert
}
