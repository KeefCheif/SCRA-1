//
//  MenuManagerModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/23/22.
//

import Foundation

struct MenuModel {
    
    var view_selector: MenuViewSelector = .menu
    
    var profile: Profile = Profile()
    
}

struct Profile {
    
    var friends: [String]?
    var games: [Game]?
    
}

struct Game {
    
    var opponent: String?
    
    var my_score: Int?
    var their_score: Int?
    
    var game_id: String?
    
}

enum MenuViewSelector {
    
    case menu
    case profile
    case game
    
}
