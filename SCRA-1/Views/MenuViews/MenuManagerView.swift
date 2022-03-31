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
        
        switch self.menu_view_model.menu_model.view_selector {
        case .menu:
            MenuView(menu_view_manager: self.$menu_view_model.menu_model.view_selector, loggedIn: self.$loggedIn)
                .environmentObject(FriendSelectorViewModel())
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
