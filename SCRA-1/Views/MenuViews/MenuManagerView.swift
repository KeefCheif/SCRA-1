//
//  MenuManagerView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/21/22.
//

import SwiftUI
import FirebaseAuth

struct MenuManagerView: View {
    
    @Binding var loggedIn: Bool
    @StateObject var menu_view_model: MenuManagerViewModel
    
    var body: some View {
        
        switch self.menu_view_model.state {  // Maybe fix location of state manager
        case .menu:
            MenuView(menu_state: self.$menu_view_model.state, gameID: self.$menu_view_model.gameID, loggedIn: self.$loggedIn)
                .environmentObject(FriendSelectorViewModel())
        case .game:
            GameManagerView(view_model: GameViewModel(gameID: self.menu_view_model.gameID), menu_state: self.$menu_view_model.state)
        default:
            Text("default")
        }
        
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            self.loggedIn = false
        } catch {
            print("SIGN OUT FAILED")
        }
    }
}
