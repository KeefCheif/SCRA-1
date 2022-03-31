//
//  GameSelectorListFriends.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/28/22.
//

import SwiftUI

struct GameSelectorListFriends: View {
    
    @Binding var state: GameSelectorState
    @Binding var friends: [BasicUser]
    @Binding var invitee: BasicUser?
    
    var body: some View {
        
        VStack {
            
            ScrollView(.horizontal) {
                HStack {
                    Spacer()
                    
                    ForEach(self.friends, id: \.self) { friend in
                        
                        Button(action: {
                            self.invitee = friend
                            self.state = .create_game
                        }, label: {
                            VStack {
                                Image(systemName: "person.circle")
                                    .GameSelectorLogo()
                                Text(friend.displayUsename)
                                    .GameSelectorSubText()
                            }
                        })
                        
                    }
                    
                    Spacer()
                }
            }
            .padding(.bottom, 6)
            
            Button(action: {
                self.state = .multiplayer
            }, label: {
                HStack {
                    Image(systemName: "chevron.left.circle")
                        .selectorSubButton()
                    Text("Back")
                        .GameSelectorSubText()
                }
            })
            
        }
    }
}
