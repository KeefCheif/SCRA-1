//
//  MultiplayerSelectionView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import SwiftUI

struct MultiplayerSelectionView: View {
    
    @Binding var gameSelectorState: GameSelectorState
    @State private var invite: String = ""
    
    var body: some View {
        
        ScrollView(.horizontal) {
            
            HStack {
                
                // For Each Friend to invite to a game right here
                
                Button(action: {
                    self.gameSelectorState = .invite
                }, label: {
                    VStack {
                        Image(systemName: "magnifyingglass.circle")
                            .GameSelectorLogo()
                        
                        Text("Search")
                            .GameSelectorSubText()
                    }
                })
                
            }
            
        }
        
        // Should List Friends & have an option to invite via username
        
    }
}
