//
//  GameBoardModel.swift
//  SCRA-1
//
//  Created by KeefCheif on 3/7/22.
//

import SwiftUI

struct Letter {
    
    var value: Int                  // The point value of the tile
    
    var letter: String              // The letter on the tile
    
    var offset: CGSize = .zero
    
}

struct Square {
    
    var empty: Bool                 // Empty or not empty
    
    var type: String                // The kind of tile (ie: triple word or double letter)
    
}

struct BoardDetails {
    
    var zoom: Bool = false
    
    var view_position: CGPoint = .zero          // Used to keep the zoomed in board frame centered on the view
    
    var coordinate_position: CGPoint = .zero    // Used to keep track of where tiles are with respect to the changing view (zooming in & moving around)
    
    var offset: CGPoint = .zero
    
    var dropFrames: [CGRect] = [CGRect](repeating: CGRect.zero, count: 225)
    
    var zoomDropFrames: [CGRect] = [CGRect](repeating: CGRect.zero, count: 225)
    
}

struct Board {
    
    var player_rack: [Letter] = [Letter](repeating: Letter(value: 0, letter: "blank"), count: 7)
    
    var letter_bag: [Letter] = [Letter](repeating: Letter(value: 0, letter: "blank"), count: 100)
    
    var board: [Square] = [Square](repeating: Square(empty: true, type: "blank"), count: 225)
    
    var board_details: BoardDetails = BoardDetails()
    
}

struct PlacedTile {
    
    var letter: Letter
    
    var tile_rack_index: Int = 0
    
    var board_location: Int = -1
    
    var board_type: String = "blank"    // Keeps track of what kind of square the tile was placed on (tw, dw, blank, ...)
    
}

struct TileTracker {
    
    var placed_tile: [PlacedTile] = [PlacedTile]()
    
    var direction: WordDirection = WordDirection.na
    
    enum WordDirection {
        case horizontal, vertical, na
    }
    
}

