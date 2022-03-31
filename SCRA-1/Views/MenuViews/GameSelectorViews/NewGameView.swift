//
//  NewGameView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import SwiftUI

struct NewGameView: View {
    
    @Binding var gameSelectorState: GameSelectorState
    
    var body: some View {
        
        VStack {
            
            HStack {
                
                Spacer()
                
                // Two Options: Singleplayer & Multiplayer
                Button(action: {
                    self.gameSelectorState = .singleplayer
                }, label: {
                    VStack {
                        Image(systemName: "person.circle")
                            .GameSelectorLogo()
                        
                        Text("Singleplayer")
                            .GameSelectorSubText()
                    }
                })
                
                Spacer()
                
                Button(action: {
                    self.gameSelectorState = .multiplayer
                }, label: {
                    VStack {
                        Image(systemName: "person.2.circle")
                            .GameSelectorLogo()
                        
                        Text("Multiplayer")
                            .GameSelectorSubText()
                    }
                })
                
                Spacer()
                
            }
            .padding(.bottom, 6)
            
            Button(action: {
                self.gameSelectorState = .list
            }, label: {
                HStack {
                    Image(systemName: "chevron.left.circle")
                        .selectorSubButton()
                    Text("Cancel")
                        .GameSelectorSubText()
                }
            })
            
        }
    }
    
}


struct NewGameView_Previews: PreviewProvider {
    static var previews: some View {
        NewGameView(gameSelectorState: Binding.constant(.new_game))
    }
}

