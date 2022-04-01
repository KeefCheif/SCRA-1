//
//  GameManagerView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/31/22.
//

import SwiftUI

struct GameManagerView: View {
    
    @StateObject var view_model: GameViewModel
    @Binding var menu_state: MenuViewSelector
    
    var body: some View {
        
        if self.view_model.isLoading {
            GenericLoadingView()
        } else {
            
            VStack {
                
                GameTopNaveView(view_model: self.view_model)
                
                GeometryReader { board_geo in
                    VStack {
                        GameBoardView(view_model: self.view_model)
                            .modifier(BoardModifier(geo: board_geo, board_details: self.$view_model.board_details))
                            .frame(width: board_geo.size.width, height: board_geo.size.width)
                        
                        PlayerRackView(view_model: self.view_model, geo: board_geo)
                            .frame(width: board_geo.size.width, height: board_geo.size.width/6)
                        
                        GameBottomNavView(view_model: self.view_model, geo: board_geo)
                    }
                    .coordinateSpace(name: "board_rack")
                }
            
            }
            .padding(4)
        }
    }
}

struct GameBottomNavView: View {
    
    @ObservedObject var view_model: GameViewModel
    var geo: GeometryProxy
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                
            }, label: {
                Text("Submit")
                    .GameSelectorSubText()
                    .padding(6)
                    .background(Rectangle().foregroundColor(.green).cornerRadius(8).frame(width: self.geo.size.width/4))
            })
            
            Spacer()
            
            Button(action: {
                self.view_model.recallTiles()
            }, label: {
                Text("Recall")
                    .GameSelectorSubText()
                    .padding(6)
                    .background(Rectangle().foregroundColor(.blue).cornerRadius(8).frame(width: self.geo.size.width/4))
            })
            
            Spacer()
            
            Button(action: {
                
            }, label: {
                Text("Trade")
                    .GameSelectorSubText()
                    .padding(6)
                    .background(Rectangle().foregroundColor(.red).cornerRadius(8).frame(width: self.geo.size.width/4))
            })
            
            Spacer()
        }
    }
}
