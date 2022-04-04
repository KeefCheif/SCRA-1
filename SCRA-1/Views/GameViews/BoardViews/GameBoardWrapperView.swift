//
//  GameBoardWrapperView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/31/22.
//

import SwiftUI

struct GameBoardView: View {
    
    @ObservedObject var view_model: GameViewModel
    //var geo: GeometryProxy
    
    var body: some View {
        
        VStack(spacing: 2.5) {
            
            ForEach(0..<15) { y in
                
                HStack(spacing: 2.5) {
                    
                    ForEach(0..<15) { x in
                        
                        GeometryReader { square_geo in
                            
                            Image(self.view_model.game_state!.board[(y * 15) + x])
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(3)
                                .frame(width: square_geo.size.width)
                                .onAppear {
                                    self.view_model.board_details.dropFrames[(y * 15) + x] = square_geo.frame(in: .named("board_rack"))
                                }
                        }
                    }
                }
            }
        }
        .coordinateSpace(name: "board")
    }
}

struct PlayerRackView: View {
    
    @ObservedObject var view_model: GameViewModel
    var geo: GeometryProxy
    
    var default_position: CGPoint {
        return CGPoint(x: self.geo.size.width/2, y: self.geo.size.width/2)
    }
    
    var body: some View {
        
        HStack {
            ForEach(Array(zip(self.view_model.player_rack.indices, self.view_model.player_rack)), id: \.0) { index, item in
            //ForEach(0..<self.view_model.player_rack.count) { index in
                Image(item.letter)
                    .resizable()
                    .scaledToFit()
                    .offset(item.offset)
                    
                    .gesture(DragGesture(coordinateSpace: .named("board_rack")).onChanged { drag in
                        self.view_model.player_rack[index].offset = drag.translation
                    }.onEnded { drag in
                        self.view_model.player_rack[index].offset = .zero
                        
                        if self.view_model.board_details.zoom {
                            var _ = self.view_model.dropTile(location: self.zoomDropLocation(location: drag.location), index: index)
                        } else {
                            var _ = self.view_model.dropTile(location: drag.location, index: index)
                        }
                    })
            }
        }
        .padding(6)
        .background(Rectangle().foregroundColor(.blue).cornerRadius(8).frame(width: geo.size.width))
    }
    
    
    private func zoomDropLocation(location: CGPoint) -> CGPoint {
        
        guard self.view_model.board_details.zoom else { return .zero }
        
        // The zoom view on the screen does not match the coordinate system that determines where tiles are dropped
        // First calculate the zoom view's distance from the center of the board (without zoom)
        
        // We want to move the tile based on its off set from the center of the screen
        let coordinate_location: CGPoint = CGPoint(x: location.x - self.default_position.x, y: location.y - self.default_position.y)
        return CGPoint(x: coordinate_location.x/2 + self.view_model.board_details.coordinate_position.x, y: coordinate_location.y/2 + self.view_model.board_details.coordinate_position.y)
        
    }
}
