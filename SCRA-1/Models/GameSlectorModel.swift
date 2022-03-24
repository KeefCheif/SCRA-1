//
//  GameSlectorModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import Foundation

struct GameSelectorModel {
    
    var gameSelectorState: GameSelectorState = .list
    
    // - - - - - DB info - - - - -//
    var games: [String]?                // A list of game ids (Might need to make it actual game info so an array of a struct)
    var friends: [String]?              // A list of friend ids for easy invites to new games
    
}

enum GameSelectorState {
    
    case list
    case new_game
    case multiplayer
    case singleplayer
    case invite
    
}
