//
//  GameBoardViewModel.swift
//  SCRA-1
//
//  Created by KeefCheif on 3/7/22.
//

import SwiftUI

class GameBoardViewModel: ObservableObject {
    
    @Published var isLoading: Bool = true
    
    @Published var board_model: Board = Board()
    
    @Published var tile_tracker: TileTracker = TileTracker()        // Needs to be published ?
    
    
    init() {
        
        prepareLetters(letters: &self.board_model.letter_bag)
        setupBoard(board: &self.board_model.board)
        setupPlayerRack()
        
        self.isLoading = false
        
    }
    
    
    // Draw x amount of tiles for a player from the tile bag
    func drawTiles(amount: Int) {
        
        guard (amount > 0 && amount <= 7) else { return }
        
        for _ in 0..<amount {
            
            let rand: Int = Int.random(in: 0..<self.board_model.letter_bag.count)
            self.board_model.player_rack.append(Letter(value: self.board_model.letter_bag[rand].value, letter: self.board_model.letter_bag[rand].letter))
            
            // Remove the drawn tile from the bag of remaining tiles
            self.board_model.letter_bag.remove(at: rand)
            
        }
    }
    
    
    func recallTiles() {
        
        guard !self.tile_tracker.placed_tile.isEmpty else { return }
        
        for letter in self.tile_tracker.placed_tile {
            
            self.board_model.player_rack[letter.tile_rack_index] = letter.letter
            
            self.board_model.board[letter.board_location] = Square(empty: true, type: letter.board_type)
        }
        
        self.tile_tracker.placed_tile.removeAll()
    }
    
    
    func dropTile(location: CGPoint, index: Int) -> Bool {
        
        // Search the squares on the board to see if the tile is over any of them... (what is the fastest way to do it?)
        var crawler: Int = 0
        
        for frame in self.board_model.board_details.dropFrames {
            
            if (frame.contains(location) && self.board_model.board[crawler].empty) {
                
                // Add this tile to the turn tracker
                self.tile_tracker.placed_tile.append(PlacedTile(letter: self.board_model.player_rack[index], tile_rack_index: index, board_location: crawler, board_type: self.board_model.board[crawler].type))
                
                // Put the tile in this square
                self.board_model.board[crawler] = Square(empty: false, type: self.board_model.player_rack[index].letter)
                
                // Make the tile that was dropped from the tile rack appear invisible (still want the space to be occupied until they finish their turn in case they recall the letter)
                //self.board_model.player_rack.remove(at: index)
                self.board_model.player_rack[index].letter = "hide"
                
                return true
            }
            
            crawler += 1
        }
        
        return false
    }
    
    func validateTileDrop(location: Int) -> Bool {
        
        // Case 1: First tile placed, can only place on the center square
        // Case 2: Not first tile placed but first tile from a given turn, must be connected to another tile
        // Case 3: Not first tile placed and not the first tile from a given turn
        
        return false
    }
    
    
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
    //                  - - - P R I V A T E   H E L P E R   F U N C T I O N S - - -
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
    
    
    private func prepareLetters(letters: inout [Letter]) {
        
        // How many of each letter are there: 100 total (a-z with blanks at the end)
        let letter_amounts: [Int] = [9, 2, 2, 4, 12, 2, 3, 2, 9, 1, 1, 4, 2, 6, 8, 2, 1, 6, 4, 6, 4, 2, 2, 1, 2, 1, 2]
        // How many points each letter is worth
        let letter_values: [Int] = [1, 3, 3, 2, 1, 4, 2, 4, 1, 8, 5, 1, 3, 1, 1, 3, 10, 1, 1, 1, 1, 4, 4, 8, 4, 10, 0]
        // The actual letters in the game
        let letter_letters: [String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "blank"]
        
        var crawler: Int = 0                // crawler for essential setup data created above
        var letter_crawler: Int = 0         // crawler for actual letter array
        
        for i in letter_amounts {
            for _ in 0..<i {
                
                letters[letter_crawler].letter = letter_letters[crawler]
                letters[letter_crawler].value = letter_values[crawler]
                
                letter_crawler += 1
                
            }
            
            crawler += 1
            
        }
        
    }
    
    private func setupBoard(board: inout [Square]) {
        
        // Standard Scrabble Board
        // The four quearters that can be mirrored are created first
        // The array that stores the board is an array of length 225 (a index for each square on the board)
        // The array counts from 0 to 224 from let to right, top to bottom on the board
        
        let number_sides: Int = 14                                          // There are 14 sides because it is 15 - 1 on a standard scrable board
        let mirror_limit: Int = 7                                           // Do not go past the 7th row and column for the original copy
        
        for i in 0..<mirror_limit {
            
            let location: Int = i * 15                                      // The location/position in the array[225] is (15 * i - 1) because the array starts at 0
            let mirror_down_location: Int = (number_sides - i) * 15         // The bottom mirrored location on the array
            
            switch i {
            case 0:
                // - - Row #1 - -
                board[location].type = "tw"
                board[location + 14].type = "tw"
                board[mirror_down_location].type = "tw"
                board[board.count - 1].type = "tw"
                
                board[location + 3].type = "dl"
                board[location + 11].type = "dl"
                board[mirror_down_location + 3].type = "dl"
                board[mirror_down_location + 11].type = "dl"
        
            case 1:
                // - - Row #2 - -
                board[location + 1].type = "dw"
                board[location + 13].type = "dw"
                board[mirror_down_location + 1].type = "dw"
                board[mirror_down_location + 13].type = "dw"
                
                board[location + 5].type = "tl"
                board[location + 9].type = "tl"
                board[mirror_down_location + 5].type = "tl"
                board[mirror_down_location + 9].type = "tl"
                
            case 2:
                // - - Row #3 - -
                board[location + 2].type = "dw"
                board[location + 12].type = "dw"
                board[mirror_down_location + 2].type = "dw"
                board[mirror_down_location + 12].type = "dw"
                
                board[location + 6].type = "dl"
                board[location + 8].type = "dl"
                board[mirror_down_location + 6].type = "dl"
                board[mirror_down_location + 8].type = "dl"
                
            case 3:
                // - - Row #4 - -
                board[location].type = "dl"
                board[location + 14].type = "dl"
                board[mirror_down_location].type = "dl"
                board[mirror_down_location + 14].type = "dl"
                
                board[location + 3].type = "dw"
                board[location + 11].type = "dw"
                board[mirror_down_location + 3].type = "dw"
                board[mirror_down_location + 11].type = "dw"
            
            case 4:
                // - - Row #5 - -
                board[location + 4].type = "dw"
                board[location + 10].type = "dw"
                board[mirror_down_location + 4].type = "dw"
                board[mirror_down_location + 10].type = "dw"
                
            case 5:
                // - - Row #6 - -
                board[location + 1].type = "tl"
                board[location + 13].type = "tl"
                board[mirror_down_location + 1].type = "tl"
                board[mirror_down_location + 13].type = "tl"
                
                board[location + 5].type = "tl"
                board[location + 9].type = "tl"
                board[mirror_down_location + 5].type = "tl"
                board[mirror_down_location + 9].type = "tl"
            
            case 6:
                // - - Row #7 - -
                board[location + 2].type = "dl"
                board[location + 12].type = "dl"
                board[mirror_down_location + 2].type = "dl"
                board[mirror_down_location + 12].type = "dl"
                
                board[location + 6].type = "dl"
                board[location + 8].type = "dl"
                board[mirror_down_location + 6].type = "dl"
                board[mirror_down_location + 8].type = "dl"
            
            default:
                break
            }
            
        }
        
        // Now the middle row and column of the board
        // The middle rows where not mirrored since they are unique
        
        let middle: Int = number_sides/2
        
        board[middle].type = "tw"
        board[middle * 15].type = "tw"
        board[(middle * 15) + 14].type = "tw"
        board[(14 * 15) + middle].type = "tw"
        
        board[(3 * 15) + middle].type = "dl"
        board[(middle * 15) + 3].type = "dl"
        board[(middle * 15) + 11].type = "dl"
        board[(11 * 15) + middle].type = "dl"
        
        board[(middle * 15) + middle].type = "center"
        
    }
    
    private func setupPlayerRack() {
        
        self.board_model.player_rack.removeAll()
        self.drawTiles(amount: 7)
        
    }
    
}

