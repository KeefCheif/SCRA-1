//
//  MultiplayerSelectionView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import SwiftUI

struct MultiplayerSelectionView: View {
    
    @Binding var state: GameSelectorState
    @Binding var friends: [BasicUser]
    @State private var error: GameSelectorErrorType?
    
    var body: some View {
        
        VStack {
            
            HStack {
                
                Spacer()
                
                Button(action: {
                    self.error = GameSelectorErrorType(error: .featureUnavailable("inviting by username"))
                }, label: {
                    VStack {
                        Image(systemName: "magnifyingglass.circle")
                            .GameSelectorLogo()
                        
                        Text("Invite by Username")
                            .GameSelectorSubText()
                    }
                })
                
                Spacer()
                
                Button(action: {
                    if (self.friends.isEmpty) {
                        self.error = GameSelectorErrorType(error: .noFriends)
                    } else {
                        self.state = .list_friends
                    }
                }, label: {
                    VStack {
                        Image(systemName: "heart.circle")
                            .GameSelectorLogo()
                        Text("Invite a Friend")
                            .GameSelectorSubText()
                    }
                })
                
                Spacer()
                
            }
            .padding(.bottom, 6)
            
            Button(action: {
                self.state = .new_game
            }, label: {
                HStack {
                    Image(systemName: "chevron.left.circle")
                        .selectorSubButton()
                    Text("Back")
                        .GameSelectorSubText()
                }
            })
            
        }
        .alert(item: self.$error) { (error) in
            Alert(title: Text(""), message: Text(error.error.localizedDescription), dismissButton: .default(Text("Okay")) {
                self.error = nil
            })
        }
        
    }
}
