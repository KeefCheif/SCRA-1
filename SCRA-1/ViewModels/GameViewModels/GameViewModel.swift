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
                self.player_rack = self.preparePlayerRack()
                
                if settings.player1ID == Auth.auth().currentUser!.uid {
                    self.isPlayer1 = true
                }
                self.isTimer = settings.timeRestriction > 0 ? true : false
                
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
                self.player_rack[index].letter = "hide"
                
                self.calculateProjectPoints()
                
                return true
            }
            
            crawler += 1
        }
        return false
    }
    
    // Adjusts the point projector for the UI
    private func calculateProjectPoints() {
        
        guard self.game_state != nil && !self.tile_tracker.placed_tile.isEmpty else { return }
        
        var total_points: Int = 0
        var multiplier: Int = 1
        
        for tile in self.tile_tracker.placed_tile {
            
            switch tile.board_type {
            case "tw":
                multiplier = 3
                if let value = Globals.Letter_Values[tile.letter.letter] {
                    total_points += value
                } else { total_points += 0 }
            case "dw":
                multiplier = multiplier >= 2 ? multiplier : 2
                if let value = Globals.Letter_Values[tile.letter.letter] {
                    total_points += value
                } else { total_points += 0 }
            case "tl":
                if let value = Globals.Letter_Values[tile.letter.letter] {
                    total_points += 3 * value
                } else { total_points += 0 }
            case "dl":
                if let value = Globals.Letter_Values[tile.letter.letter] {
                    total_points += 2 * value
                } else { total_points += 0 }
            case "center":
                multiplier = multiplier >= 2 ? multiplier : 2
                if let value = Globals.Letter_Values[tile.letter.letter] {
                    total_points += value
                } else { total_points += 0 }
            default:
                if let value = Globals.Letter_Values[tile.letter.letter] {
                    total_points += value
                } else { total_points += 0 }
            }
            
        }
        
        total_points *= multiplier
        
        if self.tile_tracker.placed_tile.count == 7 {
            total_points += 50
        }
        
        self.tile_tracker.projected_points = total_points
    }
    
    
    func legalMove() -> Bool {
        
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
        
        if self.tile_tracker.placed_tile.count == 1 {
            guard self.tile_tracker.placed_tile[0].board_location == 112 else { throw IllegalMoveError.disconnected(true) }
            return
        }
        
        let locations: [Int] = self.tile_tracker.placed_tile.map { $0.board_location }
        
        
        
        for loc in locations {
            
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
    
    
    
    
    func recallTiles() {
        
        guard !self.tile_tracker.placed_tile.isEmpty && self.game_state != nil else { return }
        
        for letter in self.tile_tracker.placed_tile {
            
            self.player_rack[letter.tile_rack_index] = letter.letter
            
            self.game_state!.board[letter.board_location] = letter.board_type
        }
        
        self.tile_tracker.placed_tile.removeAll()
        self.tile_tracker.projected_points = 0
        
    }
    
    func isPlayerTurn() -> Bool {
        
        guard self.game_state != nil else { return false }
        
        if (self.isPlayer1 && self.game_state!.player1Turn) || (!self.isPlayer1 && !self.game_state!.player1Turn)  {
            return true
        }
        return false
    }
    
    func endTurn() {
        // This still needs a lot of work
        
        let db = Firestore.firestore()
        let docRef = db.collection("games").document(self.gameID)
        
        let updateFlag: Bool = self.isPlayer1 ? false : true
        
        docRef.updateData(["gameComponents.player1Turn": updateFlag])
        
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
                
                let settings: [String:Any] = data["gameSettings"]! as! [String:Any]
                let state: [String:Any] = data["gameComponents"]! as! [String:Any]
                let component: [String: Any] = data[Auth.auth().currentUser!.uid]! as! [String:Any]
                
                do {
                    
                    let jsonSettings = try JSONSerialization.data(withJSONObject: settings)
                    let decoder = JSONDecoder()
                    let decodedSettings = try decoder.decode(GameSettings.self, from: jsonSettings)
                    
                    let jsonState = try JSONSerialization.data(withJSONObject: state)
                    let decodedState = try decoder.decode(GameState.self, from: jsonState)
                    
                    let jsonComponent = try JSONSerialization.data(withJSONObject: component)
                    let decodedComponent = try decoder.decode(PlayerComponent.self, from: jsonComponent)
                    
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
        
        self.isLoading = true
        
        let db = Firestore.firestore()
        let docRef = db.collection("games").document(self.gameID)
        
        docRef.getDocument { (docSnap, error) in
            
            if let error = error {
                self.error = GameErrorType(error: .propogatedError(error.localizedDescription))
                self.isLoading = false
            } else if let docSnap = docSnap {
                
                let data = docSnap.data()!
                
                let state: [String:Any] = data["gameComponents"]! as! [String:Any]
                
                do {
                    
                    let jsonState = try JSONSerialization.data(withJSONObject: state)
                    let decoder = JSONDecoder()
                    let decodedState = try decoder.decode(GameState.self, from: jsonState)
                    
                    self.game_state = decodedState
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
                let isPlayer1Turn: Bool = components["player1Turn"]! as! Bool
                
                // Check to see if this player's turn is over according to the DB
                if isPlayer1Turn != self.game_state!.player1Turn {
                    self.tile_tracker = TileTracker()
                    self.refreshGameState()
                }
            }
        }
    }
    
    private func preparePlayerRack() -> [Letter] {
        
        guard self.player_component != nil else { return [Letter]() }
        
        var letters: [Letter] = [Letter]()
        
        for letter in self.player_component!.letters {
            letters.append(Letter(value: letterToPointValue(letter: letter), letter: letter))
        }
        
        return letters
        
    }
    
    private func prepTimer() -> (Int, Int)? {
        
        guard self.game_settings != nil && self.game_settings!.timeRestriction > 0 else { return nil }
        
        let total_seconds: Double = self.game_settings!.timeRestriction * 60
        let only_seconds: Int = Int(total_seconds)%60
        let only_minutes: Int = Int(total_seconds)/60
        
        return (only_minutes, only_seconds)
        
    }
    
    
    private func drawTiles() {
        
        guard self.player_component != nil && self.game_state != nil && self.player_component!.letters.count < 7 else { return }
        
        let amount_needed: Int = 7 - self.player_component!.letters.count
        let amount_remaining: Int = self.game_state!.letterAmounts.reduce(0, +)
        let draw_amount: Int = amount_remaining <= amount_needed ? amount_remaining : amount_needed
        
        for _ in 0..<draw_amount {
            
            let rand = Int.random(in: 0..<self.game_state!.letterAmounts.count)
            
            self.player_component!.letters.append(self.game_state!.letterTypes[rand])
            
            self.game_state!.letterAmounts[rand] -= 1
            
            if self.game_state!.letterAmounts[rand] <= 0 {
                self.game_state!.letterTypes.remove(at: rand)
                self.game_state!.letterAmounts.remove(at: rand)
            }
            
        }
        
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


 







func numberToLetter(number: Int) -> String {
    
    guard number >= 0 && number <= 25 else { return "wild" }
    
    return String(UnicodeScalar(UInt8(number + 97)))
    
}

func letterToPointValue(letter: String) -> Int {
    
    guard Globals.Letter_Types.contains(letter) else { return 0 }
    
    return Globals.Letter_Amounts[Globals.Letter_Types.firstIndex(of: letter)!]
    
}


struct PlayerComponent: Codable {
    
    var letters: [String]
    
    var freeChallenges: Int
    
    var lastTurn: String
}


struct GameSettings: Codable {
    
    var enableChallenges: Bool
    var freeChallenges: Int
    
    var timeRestriction: Double
    
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


