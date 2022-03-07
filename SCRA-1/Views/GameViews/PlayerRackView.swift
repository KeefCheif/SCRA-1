//
//  PlayerRackView.swift
//  SCRA-1
//
//  Created by KeefCheif on 3/7/22.
//

import SwiftUI

struct PlayerRackView: View {
    
    var geo: GeometryProxy
    @EnvironmentObject var view_model: GameBoardViewModel
    
    var default_position: CGPoint {
        return CGPoint(x: self.geo.size.width/2, y: self.geo.size.width/2)
    }
    
    var body: some View {
        
        HStack {
            
            ForEach(0..<self.view_model.board_model.player_rack.count) { index in
                
                Image(self.view_model.board_model.player_rack[index].letter)
                    .resizable()
                    .scaledToFit()
                    .offset(self.view_model.board_model.player_rack[index].offset)
                    .frame(width: self.geo.size.width/7 - 9, height: self.geo.size.width/7 - 9)
                
                    .gesture(DragGesture(coordinateSpace: .global).onChanged { drag in
                        self.view_model.board_model.player_rack[index].offset = drag.translation
                    }.onEnded { drag in
                        self.view_model.board_model.player_rack[index].offset = .zero
                        
                        if self.view_model.board_model.board_details.zoom {
                            var _ = self.view_model.dropTile(location: self.zoomDropLocation(location: drag.location), index: index)
                        } else {
                            var _ = self.view_model.dropTile(location: drag.location, index: index)
                        }
                    })
                
            }
            
        }
    }
    
    private func zoomDropLocation(location: CGPoint) -> CGPoint {
        
        guard self.view_model.board_model.board_details.zoom else { return .zero }
        
        // The zoom view on the screen does not match the coordinate system that determines where tiles are dropped
        // First calculate the zoom view's distance from the center of the board (without zoom)
        
        // We want to move the tile based on its off set from the center of the screen
        let coordinate_location: CGPoint = CGPoint(x: location.x - self.default_position.x, y: location.y - self.default_position.y)
        return CGPoint(x: coordinate_location.x/2 + self.view_model.board_model.board_details.coordinate_position.x, y: coordinate_location.y/2 + self.view_model.board_model.board_details.coordinate_position.y + self.view_model.board_model.board_details.dropFrames[0].height)
        
    }
}
