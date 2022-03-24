//
//  MenuView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/23/22.
//

import SwiftUI

struct MenuView: View {
    
    @Binding var menu_view_manager: MenuViewSelector
    @State var gameSelectorDropDown: Bool = false
    
    var body: some View {
        
        GeometryReader { geo in
            
            VStack {
                
                Button(action: {
                    self.gameSelectorDropDown.toggle()
                }, label: {
                    
                    HStack {
                        Group {
                            Text("Games")
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                            
                            Image(systemName: self.gameSelectorDropDown ? "chevron.down.circle" : "chevron.up.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25)
                                .foregroundColor(.white)
                        }
                    }
                })
                
                if (self.gameSelectorDropDown) {
                    
                    GameSelectorManager(view_model: GameSelectorViewModel())
                    
                }
                
            }
            .padding(6)
            .frame(width: geo.size.width)
            .background(LinearGradient(gradient: .init(colors: [.green, .yellow]), startPoint: .top, endPoint: .bottom))
            .cornerRadius(20)
            
        }
        .padding([.leading, .trailing], 20)
    }
}
