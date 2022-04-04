//
//  IllegalMoveError.swift
//  SCRA-1
//
//  Created by peter allgeier on 4/3/22.
//

import Foundation

enum IllegalMoveError: Error, LocalizedError {
    
    case notInLine
    case disjoint
    case disconnected(Bool)
    
    var errorDescription: String? {
        switch self {
        case .notInLine:
            return NSLocalizedString("All placed tiles must be placed in line of one another. For example, you cannot place a word diagonally.", comment: "")
        case .disjoint:
            return NSLocalizedString("All placed tiles must be connected in line by other tiles. Note that the tiles do not need to be connected by tiles you have placed or tiles placed on this turn.", comment: "")
        case .disconnected(let firstTurn):
            return firstTurn ? NSLocalizedString("The first word of the game must touch the center square.", comment: "") : NSLocalizedString("The word you place must be connected to a letter that has already been played.", comment: "")
        }
    }
}

struct IllegalMoveErrorType: Identifiable {
    let id = UUID()
    let error: IllegalMoveError
}
