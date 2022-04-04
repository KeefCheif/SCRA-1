//
//  GameViewModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/31/22.
//

import Foundation
import Firebase
import FirebaseAuth
import SwiftUI

class GameViewModel: ObservableObject {
    
    @Published var isLoading: Bool = true
    
// - - - - - - - - - - Values from DB - - - - - - - - - - //
    
    @Published var game_settings: GameSettings?
    
    @Published var game_state: GameState?
    
    @Published var  player_component: PlayerComponent?
    
// - - - - - - - - - - Values for the View - - - - - - - - - - //
    
    @Published var board_details: BoardDetails = BoardDetails()
    
    @Published var tile_tracker: TileTracker = TileTracker()
    
    @Published var player_rack: [Letter] = [Letter]()
    
    @Published var isTimer: Bool = false
    
    @Published var error: GameErrorType?
    
    @Published var move_error: IllegalMoveErrorType?
    
    var isPlayer1: Bool = false
    
    var listener: ListenerRegistration?
    
    private var letters_drawn: [String] = [String]()    // For the last turn tracker (only used if they enabled challenges)
    
    private var gameID: String
    
    
    init(gameID: String) {
        
        self.gameID = gameID
        
        self.getGameInfo(gameID: gameID) { [unowned self] (settings, state, component, error) in
            if let error = error {
                self.error = GameErrorType(error: error)
                self.isLoading = false
            } else if let settings = settings, let state = state, let component = component {
                self.game_settings = settings
                self.game_state = state
                self.player_component = component
                self.player_rack = component.letters.map { Letter(value: Globals.letterToPointValue(letter: $0), letter: $0) }
                
                if settings.player1ID == Auth.auth().currentUser!.uid {
                    self.isPlayer1 = true
                }
                self.isTimer = settings.timeRestriction > 0 ? true : false
                
                if state.turnStarted && component.lostTurn {
                    self.error = GameErrorType(error: .lostTurn(component.invalidWords!))
                    self.player_component!.lostTurn = false
                }
                
                self.isLoading = false
            } else {
                self.error = GameErrorType(error: .getGameInfo)
                self.isLoading = false
            }
        }
        
    }
    
    
    func dropTile(location: CGPoint, index: Int) -> Bool {
        
        var crawler: Int = 0
        
        for frame in self.board_details.dropFrames {
            
            if frame.contains(location) && self.boardSquareisEmpty(index: crawler) {
                
                self.tile_tracker.placed_tile.append(PlacedTile(letter: self.player_rack[index], tile_rack_index: index, board_location: crawler, board_type: Globals.Default_Board[crawler]))
                
                self.game_state!.board[crawler] = self.player_rack[index].letter
                
                // Fix this so there is no: Image not found error
                self.player_rack[index].letter = "hidden"
                
                self.calculateProjectedPoints()
                
                return true
            }
            
            crawler += 1
        }
        return false
    }
    
    
    func recallTiles() {
        
        guard self.game_state != nil else { return }
        
        for tile in self.tile_tracker.placed_tile {
            
            self.player_rack[tile.tile_rack_index].letter = tile.letter.letter
            
            self.game_state!.board[tile.board_location] = tile.board_type
        }
        
        self.tile_tracker = TileTracker()
        
    }
    
    
    func isPlayerTurn() -> Bool {
        
        guard self.game_state != nil else { return false }
        
        return (self.isPlayer1 && self.game_state!.player1Turn) || (!self.isPlayer1 && !self.game_state!.player1Turn)
        
    }
    
    
    // This function updates the info in the data base so that the other user's listener will pick it up if they are on the app
    // ~ IMPORTANT ~ The player1Turn flag is what triggers the other user's UI to update, it must be the last thing to update
    func endTurn(force: Bool) {
        
        DispatchQueue.main.async {
            
        // - - - - - Pre End Move Work - - - - - //
            if force {
                do { try self.connected(checkAll: true) } catch {
                    self.recallTiles()                      // Their move is over no matter what so remove their tiles and proceed
                }
            } else {
                guard self.legalMove() else { return }      // Their move is not over so just remove their tiles, inform them of the illegal move made, & do NOT proceed
            }
            
            self.drawTiles()                                // Draw new tiles (does nothing if they already have 7)
            
            self.isLoading = true                           // Now set the loading flag to true so the UI doesn't update as the view model saves and updates itself
            
            let db = Firestore.firestore()
            let docRef = db.collection("games").document(self.gameID)
            
        // - - - - - Player Components - - - - - //
            docRef.updateData([Auth.auth().currentUser!.uid: [
                "freeChallenges": self.player_component!.freeChallenges,
                "letters": self.player_rack.map { $0.letter },
                "lostTurn": false
            ]])
            
        // - - - - - Last Turn (if challenges are enabled) - - - - - //
            if self.game_settings!.enableChallenges && !self.letters_drawn.isEmpty {
                
                let tiles_placed: [String] = self.tile_tracker.placed_tile.map { $0.letter.letter }
                
                docRef.updateData([Auth.auth().currentUser!.uid + ".lastTurn": [
                    "tilesPlaced": tiles_placed,
                    "lettersDrawn": self.letters_drawn,
                    "value": self.tile_tracker.projected_points
                ]])
            }
            
        // - - - - - Game Components - - - - - //
            let player1_score = self.isPlayer1 ? self.tile_tracker.projected_points + self.game_state!.p1Score : self.game_state!.p1Score
            let player2_score = self.isPlayer1 ? self.game_state!.p2Score : self.game_state!.p2Score + self.tile_tracker.projected_points
            
            docRef.updateData(["gameComponents": [
                "board": self.game_state!.board,
                "letterAmounts": self.game_state!.letterAmounts,
                "letterTypes": self.game_state!.letterTypes,
                "player1Turn": !self.isPlayer1,
                "turnStarted": true,
                "p1Score": player1_score,
                "p2Score": player2_score
            ]])
            
            self.refreshGameState()
            return
        }
    }
    
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
    //                                     W O R D    P R O J E C T O R
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
    
    
    private func isUserPlacedTile(location: Int) -> Bool {
        
        guard self.game_state != nil && !self.tile_tracker.placed_tile.isEmpty else { return false }
        
        for tile in self.tile_tracker.placed_tile {
            if tile.board_location == location { return true }
        }
        
        return false
    }
    
    
    private func calculateProjectedPoints() {
        
        guard self.game_state != nil && !self.tile_tracker.placed_tile.isEmpty else { return }
        
        do {
            try self.inLine()
            try self.joint()
        } catch {
            self.tile_tracker.projected_points = 0
            return
        }
        
        let locations: [Int] = self.tile_tracker.placed_tile.map { $0.board_location }
        let sorted_locations: [Int] = locations.sorted()
        let isRow: Bool = locations.first! / 15 == locations.last! / 15
        
        let word_indexes: [[Int]] = getWords(locations: sorted_locations, index: 0, isRow: isRow, words_indexes: [[Int]]())
        
        for word in word_indexes {
            for index in word {
                print(self.game_state!.board[index])
            }
            print()
        }
        
        self.tile_tracker.projected_points = getProjectedPoints(words_indexes: word_indexes)
    }
    
    
    
    private func getProjectedPoints(words_indexes: [[Int]]) -> Int {
        
        guard self.game_state != nil && !self.tile_tracker.placed_tile.isEmpty && !words_indexes.isEmpty else { return 0 }
        
        var total_points: Int = 0
        
        for word in words_indexes {
            
            var word_points: Int = 0
            var word_multiplier: Int = 1
            
            for index in word {
                
                if self.isUserPlacedTile(location: index) {
                    
                    switch Globals.Default_Board[index] {
                    case "tw":
                        word_points += Globals.letterToPointValue(letter: self.game_state!.board[index])
                        word_multiplier = 3
                    case "dw":
                        word_points += Globals.letterToPointValue(letter: self.game_state!.board[index])
                        word_multiplier = word_multiplier >= 2 ? word_multiplier : 2
                    case "center":
                        word_points += Globals.letterToPointValue(letter: self.game_state!.board[index])
                        word_multiplier = word_multiplier >= 2 ? word_multiplier : 2
                    case "tl":
                        word_points += (3 * Globals.letterToPointValue(letter: self.game_state!.board[index]))
                    case "dl":
                        word_points += (2 * Globals.letterToPointValue(letter: self.game_state!.board[index]))
                    default:
                        word_points += Globals.letterToPointValue(letter: self.game_state!.board[index])
                    }
                    
                } else {
                    word_points += Globals.letterToPointValue(letter: self.game_state!.board[index])
                }
            }
            total_points += (word_points * word_multiplier)
        }
        return self.tile_tracker.placed_tile.count == 7 ? total_points + 50 : total_points
    }
    
    
    func getWords(locations: [Int], index: Int, isRow: Bool, words_indexes: [[Int]]) -> [[Int]] {
        
        if index >= locations.count {
            return words_indexes
        } else {
         
            var temp_words: [[Int]] = words_indexes
            
            if index == 0 {
                if let mainWord_indexes = self.getBranchingWord(index: locations[index], isRow: !isRow) {
                    temp_words.append(mainWord_indexes)
                }
            }
            
            if let branchingWord_indexes = self.getBranchingWord(index: locations[index], isRow: isRow) {
                temp_words.append(branchingWord_indexes)
            }
            
            return self.getWords(locations: locations, index: index + 1, isRow: isRow, words_indexes: temp_words)
        }
    }
    
    private func getBranchingWord(index: Int, isRow: Bool) -> [Int]? {
        
        var word_indexes: [Int] = [index]
        
        let inc_dec: Int = isRow ? 15 : 1
        var dec_crawler: Int = index - inc_dec
        var inc_crawler: Int = index + inc_dec
        
        while dec_crawler >= 0 || inc_crawler <= 224 {
            if dec_crawler >= 0 && !self.boardSquareisEmpty(index: dec_crawler) {
                word_indexes.insert(dec_crawler, at: 0)
                dec_crawler -= inc_dec
            } else {
                dec_crawler = -1
            }
            
            if inc_crawler <= 224 && !self.boardSquareisEmpty(index: inc_crawler) {
                word_indexes.append(inc_crawler)
                inc_crawler += inc_dec
            } else {
                inc_crawler = 225
            }
        }
        
        return word_indexes.count > 1 ? word_indexes : nil
    }
    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
    //                                     T U R N    V A L I D A T I O N S
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
    
    
    private func legalMove() -> Bool {
        
        guard !self.tile_tracker.placed_tile.isEmpty else { return true }
        
        do {
            try self.connected(checkAll: true)
            
        } catch IllegalMoveError.notInLine {
            self.move_error = IllegalMoveErrorType(error: .notInLine)
            return false
        } catch IllegalMoveError.disjoint {
            self.move_error = IllegalMoveErrorType(error: .disjoint)
            return false
        } catch IllegalMoveError.disconnected(let firstTurn) {
            self.move_error = IllegalMoveErrorType(error: .disconnected(firstTurn))
            return false
        } catch {
            print("An unknown error was thrown while validating the move")
            return false
        }
        
        return true
        
    }
    
    
    private func connected(checkAll: Bool) throws {
        
        if checkAll {
            do {
                try self.joint()
            } catch IllegalMoveError.notInLine {
                throw IllegalMoveError.notInLine
            } catch {
                throw IllegalMoveError.disjoint
            }
        }
        
        guard !self.tile_tracker.placed_tile.isEmpty else { return }
        
        let locations: [Int] = self.tile_tracker.placed_tile.map { $0.board_location }
        
    // - - - - - Check if Word Touches an Existing Letter - - - - - //
        for loc in locations {
            
            // Check if the word is over the center square and therefore the first move of the game
            if loc == 112 {
                return
            }
            
            // Now check if the word touches another letter
            if loc + 1 < 225 && !locations.contains(loc + 1) && self.game_state!.board[loc + 1] != "blank" {
                return
            }
            
            if loc + 15 < 225 && !locations.contains(loc + 15) && self.game_state!.board[loc + 15] != "blank" {
                return
            }
            
            if loc - 1 >= 0 && !locations.contains(loc - 1) && self.game_state!.board[loc - 1] != "blank" {
                return
            }
            
            if loc - 15 >= 0 && !locations.contains(loc - 15) && self.game_state!.board[loc - 15] != "blank" {
                return
            }
            
        }
        
        // The word is disconnected if the function did not return yet
        throw IllegalMoveError.disconnected(false)
    }
    
    
    private func joint() throws {
        
        // Make sure that the words are in line before checking if they are disjoint
        do { try self.inLine() } catch { throw IllegalMoveError.notInLine }
        
        guard self.tile_tracker.placed_tile.count > 1 else { return }
        
        let locations: [PlacedTile] = self.tile_tracker.placed_tile
        
        let row_flag: Bool = (locations[0].board_location / 15) == (locations[1].board_location / 15)
        
        var max_location: Int = locations[0].board_location
        var min_location: Int = locations[0].board_location
        
        for i in 1..<locations.count {
            
            if locations[i].board_location > max_location {
                max_location = locations[i].board_location
            } else if locations[i].board_location < min_location {
                min_location = locations[i].board_location
            }

        }
        
        let increment: Int = row_flag ? 1 : 15
        
        while min_location < max_location {
            
            if self.game_state!.board[min_location + increment] == "blank" {
                throw IllegalMoveError.disjoint
            }
            
            min_location += increment
        }
        
        return
    }
    
    
    private func inLine() throws {
        
        // If there is only 1 placed tile then it is automatically in line
        guard self.tile_tracker.placed_tile.count > 1 else { return }
        
        let locations: [PlacedTile] = self.tile_tracker.placed_tile
        
        // First get the row and column of the first two placed tiles to see if either the rows or cols match
        let row_A = locations[0].board_location / 15
        let row_B = locations[1].board_location / 15
        
        let col_A = locations[0].board_location % 15
        let col_B = locations[1].board_location % 15
        
        // Keep track of how they are in line if at all
        let row_flag: Bool = row_A == row_B
        let col_flag: Bool = row_flag ? false : col_A == col_B
        
        // Ensure that the first two placed tiles are in line
        guard row_flag || col_flag else { throw IllegalMoveError.notInLine }
        
        // If there are more tiles, then make sure that they are also in line in the same way as the first two
        if locations.count > 2 {
            
            for i in 2..<locations.count {
                
                if row_flag {               // The first two are in a horizontal line, so make sure this one is too
                    
                    let test_row = locations[i].board_location / 15
                    if test_row != row_A { throw IllegalMoveError.notInLine }
                    
                } else if col_flag {        // The first two are in a verticle line, so make sure this one is too
                    
                    let test_col = locations[i].board_location % 15
                    if test_col != col_A { throw IllegalMoveError.notInLine }
                    
                }
            }
        }
        
        return
    }


    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
    //                                 P R I V A T E   H E L P E R   F U N C T I O N S
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
    
    
    
    /*
        This function is used by the initializer to retrieve necessary data from the DB such as the game_settings, game_state, and player info
        The caller of this function must wait until the completion has finished due to the asyncronous nature of the DB read
        
        completion return: game_settings, game_state, player_component
     */
    private func getGameInfo(gameID: String, completion: @escaping (GameSettings?, GameState?, PlayerComponent?, GameError?) -> Void) {
        
        let db = Firestore.firestore()
        let gameDoc = db.collection("games").document(gameID)
        
        gameDoc.getDocument { (docSnap, error) in
            
            if let _ = error {
                completion(nil, nil, nil, .getGameInfo)
            } else if let docSnap = docSnap {
                
                let data = docSnap.data()!
                var last_turn: [String:Any]?
                
                let settings: [String:Any] = data["gameSettings"]! as! [String:Any]
                let state: [String:Any] = data["gameComponents"]! as! [String:Any]
                let component: [String:Any] = data[Auth.auth().currentUser!.uid]! as! [String:Any]
                if let last_turn_optional: [String:Any] = data[Auth.auth().currentUser!.uid + ".lastTurn"] as? [String:Any] {
                    last_turn = last_turn_optional
                }
                
                do {
                    
                    let jsonSettings = try JSONSerialization.data(withJSONObject: settings)
                    let decoder = JSONDecoder()
                    let decodedSettings = try decoder.decode(GameSettings.self, from: jsonSettings)
                    
                    let jsonState = try JSONSerialization.data(withJSONObject: state)
                    let decodedState = try decoder.decode(GameState.self, from: jsonState)
                    
                    let jsonComponent = try JSONSerialization.data(withJSONObject: component)
                    var decodedComponent = try decoder.decode(PlayerComponent.self, from: jsonComponent)
                    
                    if let last_turn = last_turn {
                        let jsonLastTurn = try JSONSerialization.data(withJSONObject: last_turn)
                        let decodedLastTurn = try decoder.decode(LastTurn.self, from: jsonLastTurn)
                        decodedComponent.lastTurn = decodedLastTurn
                    }
                    
                    completion(decodedSettings, decodedState, decodedComponent, nil)
                    
                } catch {
                    print(error.localizedDescription)
                    completion(nil, nil, nil, .getGameInfo)
                }
                
            } else {
                completion(nil, nil, nil, .getGameInfo)
            }
            
        }
        
    }
    
    private func refreshGameState() {
        
        DispatchQueue.main.async {
            
            if !self.isLoading { self.isLoading = true }
            
        // - - - - - Zoom Out Board & Reset Tile Tracker - - - - - //
            self.board_details.zoom = false
            self.board_details.offset = .zero
            
            self.tile_tracker = TileTracker()
            
        // - - - - - Update the View Model - - - - - //
            let db = Firestore.firestore()
            let docRef = db.collection("games").document(self.gameID)
            
            docRef.getDocument { (docSnap, error) in
                
                if let error = error {
                    self.error = GameErrorType(error: .propogatedError(error.localizedDescription))
                } else if let docSnap = docSnap {
                    
                    let data = docSnap.data()!
                    
                    let state: [String:Any] = data["gameComponents"]! as! [String:Any]
                    let component: [String:Any] = data[Auth.auth().currentUser!.uid]! as! [String:Any]
                    
                    do {
                        
                        let jsonState = try JSONSerialization.data(withJSONObject: state)
                        let decoder = JSONDecoder()
                        let decodedState = try decoder.decode(GameState.self, from: jsonState)
                        
                        let jsonComponent = try JSONSerialization.data(withJSONObject: component)
                        let decodedComponent = try decoder.decode(PlayerComponent.self, from: jsonComponent)
                        
                        self.game_state = decodedState
                        self.player_component = decodedComponent
                        self.player_rack = decodedComponent.letters.map { Letter(value: Globals.letterToPointValue(letter: $0), letter: $0) }
                        self.isLoading = false
                        
                    } catch {
                        print(error.localizedDescription)
                        self.error = GameErrorType(error: .getGameInfo)
                        self.isLoading = false
                    }
                } else {
                    print("An unexpected error occured while updating the game data.")
                    self.isLoading = false
                }
            }
        }
    }
    
    
    func attatchListener() {
        
        let db = Firestore.firestore()
        let docRef = db.collection("games").document(self.gameID)
        
        self.listener = docRef.addSnapshotListener(includeMetadataChanges: false) { (docSnap, error) in
            
            if let error = error {
                print(error.localizedDescription)
            } else if let docSnap = docSnap {
                
                let data = docSnap.data()!
                // We only care about how the player1 turn flag has changed because if its not player1's turn then it must be player2's turn
                let components: [String:Any] = data["gameComponents"]! as! [String:Any]
                if let isPlayer1Turn: Bool = components["player1Turn"] as? Bool {
                    // Check to see if this player's turn is over according to the DB
                    if isPlayer1Turn != self.game_state!.player1Turn {
                        self.refreshGameState()
                    }
                }
            }
        }
    }
    
    
    private func prepTimer() -> (Int, Int)? {
        
        guard self.game_settings != nil && self.game_settings!.timeRestriction > 0 else { return nil }
        
        let total_seconds: Int = self.game_settings!.timeRestriction * 60
        let only_seconds: Int = total_seconds%60
        let only_minutes: Int = total_seconds/60
        
        return (only_minutes, only_seconds)
        
    }
    
    
    private func drawTiles() {
        
        self.player_rack.removeAll(where: { $0.letter == "hidden" })
        
        guard self.player_component != nil && self.game_state != nil && self.player_rack.count < 7 else { return }
        
        
        
        let amount_needed: Int = 7 - self.player_rack.count
        var letters: [String] = [String]()
        
        for _ in 0..<amount_needed {
            
            let rand = Int.random(in: 0..<self.game_state!.letterTypes.count)
            let letter = self.game_state!.letterTypes[rand]
            
            self.player_rack.append(Letter(value: Globals.letterToPointValue(letter: letter), letter: letter))
            letters.append(letter)
            
            self.game_state!.letterAmounts[rand] -= 1
            
            if self.game_state!.letterAmounts[rand] == 0 {
                self.game_state!.letterTypes.remove(at: rand)
                self.game_state!.letterAmounts.remove(at: rand)
            }
            
        }
        
        self.letters_drawn = letters
        return
    }
    
    private func boardSquareisEmpty(index: Int) -> Bool {
        
        guard self.game_state != nil else { return false }
        
        if Globals.Letter_Types.contains(self.game_state!.board[index]) {
            return false
        }
        
        return true
    }
    
}


 

struct LastTurn: Codable {
    
    var tilesPlaced: [String]
    
    var lettersDrawn: [String]
    
    var value: Int
    
}


struct PlayerComponent: Codable {
    
    var letters: [String]
    
    var freeChallenges: Int
    
    var lostTurn: Bool
    
    var lastTurn: LastTurn?
    
    var invalidWords: [String]?
}


struct GameSettings: Codable {
    
    var enableChallenges: Bool
    var freeChallenges: Int
    
    var timeRestriction: Int
    
    var player1: String
    var player1ID: String
    
    var player2: String
    var player2ID: String
    
}

struct GameState: Codable {
    
    var board: [String]
    
    var letterAmounts: [Int]
    var letterTypes: [String]
    
    var p1Score: Int
    var p2Score: Int
    
    var player1Turn: Bool
    var turnStarted: Bool
    
}


