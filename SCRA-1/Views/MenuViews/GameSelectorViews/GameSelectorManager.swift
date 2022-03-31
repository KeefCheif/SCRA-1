//
//  GameSelectorManager.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import SwiftUI

struct GameSelectorManager: View {
    
    @ObservedObject var view_model: GameSelectorViewModel
    @Binding var friends: [BasicUser]
    
    var body: some View {
        
        switch self.view_model.state {
        case .list:
            GameListView(view_model: self.view_model)
        case .new_game:
            NewGameView(gameSelectorState: self.$view_model.state)
        case .multiplayer:
            MultiplayerSelectionView(state: self.$view_model.state, friends: self.$friends)
        case .singleplayer:
            Text("Singleplayer")
        case .list_friends:
            GameSelectorListFriends(state: self.$view_model.state, friends: self.$friends, invitee: self.$view_model.invitee)
        case .invite:
            Text("Invite")
        case .create_game:
            GameSelectorCreateGame(view_model: self.view_model)
        }
        
    }
}
