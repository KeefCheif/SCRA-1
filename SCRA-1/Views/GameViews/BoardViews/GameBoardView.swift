//
//  GameBoardView.swift
//  SCRA-1
//
//  Created by KeefCheif on 3/7/22.
//

import SwiftUI

struct GameBoardWrapperView: View {
    
    @EnvironmentObject var view_model: GameBoardViewModel
    
    var body: some View {
        
        GeometryReader { board_geo in
            
            VStack {
                
                GameBoardView(geo: board_geo)
                    .modifier(BoardModifiers(geo: board_geo, board_details: self.$view_model.board_model.board_details))
                    .environmentObject(self.view_model)
                
                PlayerRackView(geo: board_geo)
                    .frame(width: board_geo.size.width, height: board_geo.size.width/6.5)
                    .environmentObject(self.view_model)
                
            }
        }
    }
}

struct GameBoardView: View {
    
    var geo: GeometryProxy
    @EnvironmentObject var view_model: GameBoardViewModel
    
    var body: some View {
        
        VStack(spacing: 2.5) {
            
            ForEach(0..<15) { y in
                
                HStack(spacing: 2.5) {
                    
                    ForEach(0..<15) { x in
                        
                        GeometryReader { square_geo in
                            
                            Image(self.view_model.board_model.board[(y * 15) + x].type)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(3)
                                .frame(width: (self.geo.size.width - 35)/15, height: (self.geo.size.width - 35)/15)
                                .onAppear {
                                    self.view_model.board_model.board_details.dropFrames[(y * 15) + x] = square_geo.frame(in: .global)
                                }
                        }
                        
                    }
                }
            }
        }
        .coordinateSpace(name: "board")
    }
}
