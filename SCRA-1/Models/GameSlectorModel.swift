//
//  GameSlectorModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import Foundation

struct GameSelectorModel {
    
    // - - - - - DB info - - - - -//
    var games: [Game] = [Game]()        // A list of game ids (Might need to make it actual game info so an array of a struct)
    
}

struct Game: Hashable {
    
    var gameID: String
    var opponent: String
    var opponentID: String
    
}

struct GameSelectionDisplay: Hashable {
    
    var gameID: String
    var opponent: String
    
}

enum GameSelectorState {
    
    case list
    case new_game
    case multiplayer
    case singleplayer
    case list_friends
    case invite
    case create_game
    
}
