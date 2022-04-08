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
    
    @Published var last_turn: LastTurn?
    
// - - - - - - - - - - Values for the View - - - - - - - - - - //
    
    @Published var board_details: BoardDetails = BoardDetails()
    
    @Published var tile_tracker: TileTracker = TileTracker()
    
    @Published var player_rack: [Letter] = [Letter]()
    
    @Published var isTimer: Bool = false
    
// - - - - - - - - - - Values for Alerts & Errors - - - - - - - - - - - //
    
    @Published var move_error: IllegalMoveErrorType?
    
    @Published var game_alert: GameAlertType?
    
    @Published var challenge_alert: ChallengeAlertType?
    
// - - - - - - - - - - Values for Challenges - - - - - - - - - - //
    
    var challengeWords: [String] = [String]()
    
    private var challenge_result: Bool?                 // Only used upon initialization if the user closed & opened the app after seeing the results of their challenge attempt
    
// - - - - - - - - - - General Values for Game State - - - - - - - - - - //
    
    var isPlayer1: Bool = false
    
    var listener: ListenerRegistration?                 // Initialized upon the view appearing; automatically updates the view when the other player finishes their turn
    
    private var letters_drawn: [String] = [String]()    // For the last turn tracker (only used if they enabled challenges)
    
    private var gameID: String
    
    
    init(gameID: String) {
        
        self.gameID = gameID
        
        self.getGameInfo(gameID: gameID) { [unowned self] (settings, state, component, error) in
            if let error = error {
                self.game_alert = GameAlertType(error: error)
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
                
                // For informing them of their lost turn
                if state.turnStarted && component.lostTurn {
                    //self.error = GameErrorType(error: .lostTurn(component.invalidWords!))
                    //self.player_component!.lostTurn = false
                }
                
                self.handleGameClosedReoponed()
                
                self.isLoading = false
            } else {
                self.game_alert = GameAlertType(error: .errorGettingGame)
                self.isLoading = false
            }
        }
    }
    
    
    func handleGameClosedReoponed() {
        
        guard self.isPlayerTurn() else { return }
        
        if let challenge_result = self.challenge_result {
            
            self.challengeAction(challenge_successful: challenge_result, useFreeChallenge: false, forceEndTurn: self.isTimer)
            
        } else if self.isTimer && self.game_state!.turnStarted {
            
            self.endTurn(force: true)
            
        } else if self.isTimer {
            Firestore.firestore().collection("games").document(self.gameID).updateData(["gameComponents.turnStarted": true])
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
            
            if !self.isLoading { self.isLoading = true }    // Now set the loading flag to true so the UI doesn't update as the view model saves and updates itself
            
            let db = Firestore.firestore()
            let docRef = db.collection("games").document(self.gameID)
            
        // - - - - - Player Components - - - - - //
            docRef.updateData([Auth.auth().currentUser!.uid: [
                "freeChallenges": self.player_component!.freeChallenges,
                "letters": self.player_rack.map { $0.letter },
                "lostTurn": false
            ]])
            
        // - - - - - Last Turn (if challenges are enabled) - - - - - //
            if self.game_settings!.enableChallenges {
                
                if self.letters_drawn.isEmpty {
                    
                    docRef.updateData(["lastTurn": FieldValue.delete()])
                    
                } else {
                 
                    let tiles_location: [Int] = self.tile_tracker.placed_tile.map { $0.board_location }
                    
                    docRef.setData(["lastTurn": [
                        "tilesPlaced": tiles_location,
                        "lettersDrawn": self.letters_drawn,
                        "value": self.tile_tracker.projected_points
                    ]], merge: true)
                }
            }
            
        // - - - - - Reset Stuff - - - - - //
            self.letters_drawn = [String]()
            self.challengeWords = [String]()
            self.last_turn = nil
            
        // - - - - - Game Components - - - - - //
            let player1_score = self.isPlayer1 ? self.tile_tracker.projected_points + self.game_state!.p1Score : self.game_state!.p1Score
            let player2_score = self.isPlayer1 ? self.game_state!.p2Score : self.game_state!.p2Score + self.tile_tracker.projected_points
            
            docRef.updateData(["gameComponents": [
                "board": self.game_state!.board,
                "letters": self.game_state!.letters,
                "player1Turn": !self.isPlayer1,
                "turnStarted": false,
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
            if loc + 1 < 225 && !locations.contains(loc + 1) && !self.boardSquareisEmpty(index: loc + 1) {
                return
            }
            
            if loc + 15 < 225 && !locations.contains(loc + 15) && !self.boardSquareisEmpty(index: loc + 15) {
                return
            }
            
            if loc - 1 >= 0 && !locations.contains(loc - 1) && !self.boardSquareisEmpty(index: loc - 1) {
                return
            }
            
            if loc - 15 >= 0 && !locations.contains(loc - 15) && !self.boardSquareisEmpty(index: loc - 15) {
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
    //                                          C H A L L E N G E S
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
    
    
    // Called by the UI after the challenge words have been showed to the user and they have decided to challenge
    // Returns true if the challenge was successful and false if not
    func challenge() {
        
        self.isLoading = true   // Prevents the user from pushing any buttons while the challenge is going
        
        guard !self.challengeWords.isEmpty else { return }
        
        var invalid_words: [String] = [String]()
    
        for word in self.challengeWords {
            if !self.checkWord(word: word) {
                invalid_words.append(word)
            }
        }
        
        let db = Firestore.firestore()
        let gameDoc = db.collection("games").document(self.gameID)
        
        gameDoc.setData(["challengeResult": !invalid_words.isEmpty], merge: true)   // false = user lost challenge
        
        self.challenge_alert = ChallengeAlertType(error: invalid_words.isEmpty ? .lostChallenge : .wonChallenge(invalid_words))
        self.isLoading = false
    }
    
    
    func challengeAction(challenge_successful: Bool, useFreeChallenge: Bool, forceEndTurn: Bool) {
        
        self.isLoading = true
        
        let db = Firestore.firestore()
        let gameDoc = db.collection("games").document(self.gameID)
        
        if challenge_successful {
            
            // Undo the last turn
            gameDoc.updateData(["lastTurn": FieldValue.delete()])
            
            // Remove the points the opponent got from their last turn
            let player1_score = self.isPlayer1 ? self.game_state!.p1Score : self.game_state!.p1Score - self.last_turn!.value
            let player2_score = self.isPlayer1 ? self.game_state!.p2Score - self.last_turn!.value : self.game_state!.p2Score
            
            // Get the opponents tiles from the DB so they can be updated
            self.getOpponentLetters { [unowned self] (opponent_letters, opponent_id) in
                
                if let opponent_letters = opponent_letters, let opponent_id = opponent_id {
                    var new_opponent_letters: [String] = opponent_letters
                    
                    // Remove the letters they drew last turn and put them back in the letter bag
                    for letter in self.last_turn!.lettersDrawn {
                        new_opponent_letters.remove(at: new_opponent_letters.firstIndex(of: letter)!)
                        self.game_state!.letters.append(letter)
                    }
                    
                    // Give them their old letters back and remove them from the board
                    for letter_location in self.last_turn!.tilesPlaced {
                        new_opponent_letters.append(self.game_state!.board[letter_location])
                        self.game_state!.board[letter_location] = Globals.Default_Board[letter_location]
                    }
                    
                    // Save the changes made to the opoonent's component
                    gameDoc.updateData(["\(opponent_id).letters": new_opponent_letters])
                    gameDoc.updateData(["\(opponent_id).lostTurn": true])
                    
                    // Save the changes made to the gameState
                    gameDoc.updateData(["gameComponents": [
                        "board": self.game_state!.board,
                        "letters": self.game_state!.letters,
                        "player1Turn": self.isPlayer1,              // Do not change this value since it is still the current user's turn after this
                        "turnStarted": false,
                        "p1Score": player1_score,
                        "p2Score": player2_score
                    ]])
                    
                    // Remove the challenge result flag since the result has been handled
                    gameDoc.updateData(["challengeResult": FieldValue.delete()])
                    
                    
                    if forceEndTurn {
                        self.endTurn(force: true)
                    } else {
                        self.last_turn = nil
                        self.challengeWords = [String]()
                        self.refreshGameState()
                    }
                }
            }
            
        } else {
            
            gameDoc.updateData(["challengeResult": FieldValue.delete()])
            
            if useFreeChallenge && self.player_component!.freeChallenges > 0 {
                self.player_component!.freeChallenges -= 1
                // Immediatly save the loss of a free challenge in the DB in case the user closes the app after they see the result of the Challenge and use a free challenge
                gameDoc.updateData(["\(Auth.auth().currentUser!.uid).freeChallenges": self.player_component!.freeChallenges])
                self.isLoading = false
            } else {
                self.endTurn(force: true)
            }
        }
    }
    
    
    // Gets all of the words played by the opponnent last turn so that they can be displayed to the user before they decide to challenge anything
    func getChallenegeWords() {
        
        guard self.last_turn != nil && self.game_settings != nil && self.game_settings!.enableChallenges else { return }
        
        guard self.isPlayerTurn() else { return }
        
        guard !self.last_turn!.tilesPlaced.isEmpty else { return }
        
        self.recallTiles()
        
        // Need to find all the words created by the letters placed by the user
        let locations: [Int] = self.last_turn!.tilesPlaced
        let sorted_locations: [Int] = locations.sorted()
        let isRow: Bool = sorted_locations.first! / 15 == sorted_locations.last! / 15
        
        let indexed_words: [[Int]] = self.getWords(locations: sorted_locations, index: 0, isRow: isRow, words_indexes: [[Int]]())
        
        var words: [String] = [String]()
        
        for indexed_word in indexed_words {
            
            var word: String = ""
            
            for index in indexed_word {
                if !self.boardSquareisEmpty(index: index) {
                    word += self.game_state!.board[index]
                }
            }
            words.append(word)
        }
        self.challengeWords = words
    }
    
    
    private func checkWord(word: String) -> Bool {
        
        guard word.count > 1 else { return false }
        
        guard word.count < 8 else { return true } // 8 letter words or more not handled yet
        
        guard let dictionary_file = Bundle.main.url(forResource: "\(word.count)LetterWords", withExtension: "json") else { return false }
        
        do {
            let data = try Data(contentsOf: dictionary_file)
            let dictionary: [GameWords] =  try JSONDecoder().decode([GameWords].self, from: data)
            
            for gameWord in dictionary {
                if gameWord.word == word {
                    return true
                }
            }
                
        } catch {
            return false
        }
        return false
    }
    
    
    private func getOpponentLetters(completion: @escaping ([String]?, String?) -> Void) {
        let db = Firestore.firestore()
        let gameDoc = db.collection("games").document(self.gameID)
        
        gameDoc.getDocument { (docSnap, error) in
            
            if let docSnap = docSnap {
                let data = docSnap.data()!
                let opponent_id: String = self.isPlayer1 ? self.game_settings!.player2ID : self.game_settings!.player1ID
                
                let player2Component: [String:Any] = data[opponent_id]! as! [String:Any]
                
                do {
                    let jsonComponent = try JSONSerialization.data(withJSONObject: player2Component)
                    let decodedComponent = try JSONDecoder().decode(PlayerComponent.self, from: jsonComponent)
                    completion(decodedComponent.letters, opponent_id)
                } catch {
                    completion(nil, nil)
                }
                
            } else {
                print("FUCK")
                completion(nil, nil)
            }
        }
    }

    
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
    //                                 P R I V A T E   H E L P E R   F U N C T I O N S
    // - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - //
    
    
    
    /*
        This function is used by the initializer to retrieve necessary data from the DB such as the game_settings, game_state, and player info
        The caller of this function must wait until the completion has finished due to the asyncronous nature of the DB read
        
        completion return: game_settings, game_state, player_component
     */
    private func getGameInfo(gameID: String, completion: @escaping (GameSettings?, GameState?, PlayerComponent?, GameAlert?) -> Void) {
        
        let db = Firestore.firestore()
        let gameDoc = db.collection("games").document(gameID)
        
        gameDoc.getDocument { (docSnap, error) in
            
            if let _ = error {
                completion(nil, nil, nil, .errorGettingGame)
            } else if let docSnap = docSnap {
                
                let data = docSnap.data()!
                var lastTurn: [String:Any]?
                
                let settings: [String:Any] = data["gameSettings"]! as! [String:Any]
                let state: [String:Any] = data["gameComponents"]! as! [String:Any]
                let component: [String:Any] = data[Auth.auth().currentUser!.uid]! as! [String:Any]
                self.challenge_result = data["challengeResult"] as? Bool
                
                
                if let last_turn_optional: [String:Any] = data["lastTurn"] as? [String:Any] {
                    lastTurn = last_turn_optional
                }
                
                do {
                    
                    let jsonSettings = try JSONSerialization.data(withJSONObject: settings)
                    let decoder = JSONDecoder()
                    let decodedSettings = try decoder.decode(GameSettings.self, from: jsonSettings)
                    
                    let jsonState = try JSONSerialization.data(withJSONObject: state)
                    let decodedState = try decoder.decode(GameState.self, from: jsonState)
                    
                    let jsonComponent = try JSONSerialization.data(withJSONObject: component)
                    let decodedComponent = try decoder.decode(PlayerComponent.self, from: jsonComponent)
                    
                    if let lastTurn = lastTurn {
                        let jsonLastTurn = try JSONSerialization.data(withJSONObject: lastTurn)
                        let decodedLastTurn = try decoder.decode(LastTurn.self, from: jsonLastTurn)
                        self.last_turn = decodedLastTurn
                    }
                    
                    completion(decodedSettings, decodedState, decodedComponent, nil)
                    
                } catch {
                    completion(nil, nil, nil, .errorGettingGame)
                }
                
            } else {
                completion(nil, nil, nil, .errorGettingGame)
            }
            
        }
        
    }
    
    private func refreshGameState() {
        
        if !self.isLoading { self.isLoading = true }
        
    // - - - - - Zoom Out Board & Reset Tile Tracker - - - - - //
        self.board_details.zoom = false
        self.board_details.offset = .zero
        
        self.tile_tracker = TileTracker()
        
    // - - - - - Update the View Model - - - - - //
        let db = Firestore.firestore()
        let docRef = db.collection("games").document(self.gameID)
        
        docRef.getDocument { (docSnap, error) in
            
            if let _ = error {
                self.game_alert = GameAlertType(error: .errorGettingGame)
            } else if let docSnap = docSnap {
                
                let data = docSnap.data()!
                var lastTurn: [String:Any]?
                
                let state: [String:Any] = data["gameComponents"]! as! [String:Any]
                let component: [String:Any] = data[Auth.auth().currentUser!.uid]! as! [String:Any]
                self.challenge_result = data["challengeResult"] as? Bool
                if let last_turn_option: [String:Any] = data["lastTurn"] as? [String:Any] {
                    lastTurn = last_turn_option
                }
                
                do {
                    
                    let jsonState = try JSONSerialization.data(withJSONObject: state)
                    let decoder = JSONDecoder()
                    let decodedState = try decoder.decode(GameState.self, from: jsonState)
                    
                    let jsonComponent = try JSONSerialization.data(withJSONObject: component)
                    let decodedComponent = try decoder.decode(PlayerComponent.self, from: jsonComponent)
                    
                    if let lastTurn = lastTurn {
                        let jsonLastTurn = try JSONSerialization.data(withJSONObject: lastTurn)
                        let decodedLastTurn = try decoder.decode(LastTurn.self, from: jsonLastTurn)
                        self.last_turn = decodedLastTurn
                    } else {
                        self.last_turn = nil
                    }
                    
                    self.game_state = decodedState
                    self.player_component = decodedComponent
                    self.player_rack = decodedComponent.letters.map { Letter(value: Globals.letterToPointValue(letter: $0), letter: $0) }
                    self.isLoading = false
                    
                } catch {
                    self.game_alert = GameAlertType(error: .errorGettingGame)
                    self.isLoading = false
                }
            } else {
                self.game_alert = GameAlertType(error: .errorGettingGame)
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
                if let isPlayer1Turn: Bool = components["player1Turn"] as? Bool {
                    // Check to see if this player's turn is over according to the DB
                    if isPlayer1Turn != self.game_state!.player1Turn {
                        self.refreshGameState()
                    }
                }
            }
        }
    }
    
    
    private func drawTiles() {
        
        self.player_rack.removeAll(where: { $0.letter == "hidden" })
        
        guard self.player_component != nil && self.game_state != nil && self.player_rack.count < 7 else { return }
        
        let amount_needed: Int = 7 - self.player_rack.count
        var letters: [String] = [String]()
        
        for _ in 0..<amount_needed {
            
            let rand = Int.random(in: 0..<self.game_state!.letters.count)
            let letter = self.game_state!.letters[rand]
            
            self.player_rack.append(Letter(value: Globals.letterToPointValue(letter: letter), letter: letter))
            letters.append(letter)
            
            self.game_state!.letters.remove(at: rand)
            
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
    
    var tilesPlaced: [Int]          // Where the letters were placed on the board
    
    var lettersDrawn: [String]
    
    var value: Int
    
}


struct PlayerComponent: Codable {
    
    var letters: [String]
    
    var freeChallenges: Int
    
    var lostTurn: Bool
    
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
    
    var letters: [String]
    
    var p1Score: Int
    var p2Score: Int
    
    var player1Turn: Bool
    var turnStarted: Bool
    
}

struct GameWords: Codable {
    
    var word: String
}
