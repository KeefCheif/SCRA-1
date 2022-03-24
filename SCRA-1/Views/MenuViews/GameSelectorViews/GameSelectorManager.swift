//
//  GameSelectorManager.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import SwiftUI

struct GameSelectorManager: View {
    
    @StateObject var view_model: GameSelectorViewModel
    
    var body: some View {
        
        switch self.view_model.selector_model.gameSelectorState {
        case .list:
            GameListView(gameSelectorState: self.$view_model.selector_model.gameSelectorState)
        case .new_game:
            NewGameView(gameSelectorState: self.$view_model.selector_model.gameSelectorState)
        case .multiplayer:
            MultiplayerSelectionView(gameSelectorState: self.$view_model.selector_model.gameSelectorState)
        case .singleplayer:
            Text("Singleplayer")
        case .invite:
            Text("Invite")
        }
        
    }
}

struct GameSelectorManager_Previews: PreviewProvider {
    static var previews: some View {
        GameSelectorManager(view_model: GameSelectorViewModel())
    }
}
