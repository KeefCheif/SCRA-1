//
//  GameListView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import SwiftUI

struct GameListView: View {
    
    // Will also need a State object to display their games (This will need to access the DB)
    @Binding var gameSelectorState: GameSelectorState
    
    var body: some View {
        
        if (false) {    // is loading
            
        } else {
            ScrollView(.horizontal) {
                
                HStack {
                    Spacer()
                    
                    Button(action: {
                        self.gameSelectorState = .new_game
                    }, label: {
                        
                        VStack {
                            Image(systemName: "plus.circle")
                                .GameSelectorLogo()
                            
                            Text("New Game")
                                .GameSelectorSubText()
                        }
                        
                    })
                    
                    Spacer()
                    
                    // For each game they have right here
                }
                
            }
        }
        
    }
}

struct GameListView_Previews: PreviewProvider {
    static var previews: some View {
        GameListView(gameSelectorState: Binding.constant(.list))
    }
}
