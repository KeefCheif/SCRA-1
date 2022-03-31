//
//  MenuTopNav.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/23/22.
//

import SwiftUI
import FirebaseAuth

struct MenuTopNav: View {
    
    @Binding var menu_view_manager: MenuViewSelector
    @Binding var loggedIn: Bool
    // Eventually add profile picture
    
    var body: some View {
        
        HStack {
            
            Button(action: {
                self.signOut()
            }, label: {
                
                HStack {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .frame(width: 30)
                        .padding(6)
                    Text("Sign Out")
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                        .padding(6)
                }
                .background(Rectangle().foregroundColor(.red).cornerRadius(8))
                
            })
            
            Spacer()
            
            Button(action: {
                self.menu_view_manager = .profile
            }, label: {
                
                Image(systemName: "person.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: 30)
                    .padding(6)
                    .background(Circle().foregroundColor(.blue))
                
            })
            
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
