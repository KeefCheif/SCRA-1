//
//  GameSelectorViewModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import Foundation
import Firebase
import FirebaseAuth
import UIKit

class GameSelectorViewModel: ObservableObject {
    
    @Published var username: String = ""
    
    @Published var isLoading: Bool = true
    
// - - - - - DB Values - - - - - //
    @Published var games: [GameSelectionDisplay] = [GameSelectionDisplay]()
    
    @Published var gameReq: [Game] = [Game]()
    
    @Published var pendingReq: [Game] = [Game]()
    
// - - - - - View Values - - - - - //
    @Published var state: GameSelectorState = .list
    
    @Published var invitee: BasicUser?
    
    @Published var error: GameSelectorErrorType?
    
    @Published var isError: Bool = false
    
    init() {
        self.refresh()
    }
    
    func refresh() {
        
        if !self.isLoading { self.isLoading = true }
        
        self.getGames { (games, pending, invites, user, error) in
            
            if let error = error {
                self.error = GameSelectorErrorType(error: error)
                self.isLoading = false
            } else if let games = games, let pending = pending, let invites = invites, let user = user {
                self.games = games
                self.pendingReq = pending
                self.gameReq = invites
                self.username = user
                self.isLoading = false
            } else {
                self.error = GameSelectorErrorType(error: .unknown)
                self.isLoading = false
            }
        }
    }
    
    private func getGames(completion: @escaping ([GameSelectionDisplay]?, [Game]?, [Game]?, String?, GameSelectorError?) -> Void) {
        
        if let currentUser = Auth.auth().currentUser {
            
            let db = Firestore.firestore()
            let userDoc = db.collection("users").document(currentUser.uid)
            
            userDoc.getDocument { (docSnap, error) in
                
                if let error = error {
                    completion(nil, nil, nil, nil, .propogatedError(error.localizedDescription))
                } else if let docSnap = docSnap {
                    
                    let data = docSnap.data()!
                    let games: [Dictionary<String, String>] = data["games"]! as! [Dictionary<String, String>]
                    let pendingReq: [Dictionary<String, String>] = data["pendingGameReq"]! as! [Dictionary<String, String>]
                    let gameReq: [Dictionary<String, String>] = data["gameReq"]! as! [Dictionary<String, String>]
                    let user: String = data["displayUsername"]! as! String
                    
                    let gamesItem: [GameSelectionDisplay] = games.map { gamesDict -> GameSelectionDisplay in
                        let gameID = gamesDict["gameID"]! as String
                        let opponent = gamesDict["opponent"]! as String
                        return GameSelectionDisplay(gameID: gameID, opponent: opponent)
                    }
                    
                    let pendingItem: [Game] = pendingReq.map { pendingDict -> Game in
                        let gameID = pendingDict["gameID"]! as String
                        let opponent = pendingDict["opponent"]! as String
                        let opponentID = pendingDict["opponentID"]! as String
                        return Game(gameID: gameID, opponent: opponent, opponentID: opponentID)
                    }
                    
                    let gameReqItem: [Game] = gameReq.map { gameReqDict -> Game in
                        let gameID = gameReqDict["gameID"]! as String
                        let opponent = gameReqDict["opponent"]! as String
                        let opponentID = gameReqDict["opponentID"]! as String
                        return Game(gameID: gameID, opponent: opponent, opponentID: opponentID)
                    }
                    
                    completion(gamesItem, pendingItem, gameReqItem, user, nil)
                    
                    
                } else {
                    completion(nil, nil, nil, nil, .unknown)
                }
                
            }
            
        } else {
            completion(nil, nil, nil, nil, .notLoggedIn)
        }
    }
    
    func rejectGameRequest(gameReq: Game) {
            
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(Auth.auth().currentUser!.uid)
        let otherUserDoc = db.collection("users").document(gameReq.opponentID)
        let gameDoc = db.collection("games").document(gameReq.gameID)
        
        // First Delete the game
        gameDoc.delete()
        
        // Prep Data to delete
        let deleteGameReq: [String: Any] = [
            "gameID": gameReq.gameID,
            "opponent": gameReq.opponent,
            "opponentID": gameReq.opponentID
        ]
        
        let deletePendingReq: [String: Any] = [
            "gameID": gameReq.gameID,
            "opponent": self.username,
            "opponentID": Auth.auth().currentUser!.uid
        ]
        
        // Now delete the requests for each user
        userDoc.updateData(["gameReq": FieldValue.arrayRemove([deleteGameReq])])
        otherUserDoc.updateData(["pendingGameReq": FieldValue.arrayRemove([deletePendingReq])])
        
        // Refresh
        self.refresh()
    }
    
    func acceptGameRequest(gameReq: Game) {
        
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(Auth.auth().currentUser!.uid)
        let otherUserDoc = db.collection("users").document(gameReq.opponentID)
        let gameDoc = db.collection("games").document(gameReq.gameID)
        
        // Prep Data to delete
        let deleteGameReq: [String: Any] = [
            "gameID": gameReq.gameID,
            "opponent": gameReq.opponent,
            "opponentID": gameReq.opponentID
        ]
        
        let deletePendingReq: [String: Any] = [
            "gameID": gameReq.gameID,
            "opponent": self.username,
            "opponentID": Auth.auth().currentUser!.uid
        ]
        
        // Now delete the requests for each user
        userDoc.updateData(["gameReq": FieldValue.arrayRemove([deleteGameReq])])
        otherUserDoc.updateData(["pendingGameReq": FieldValue.arrayRemove([deletePendingReq])])
        
        // Add game to both user's games list
        userDoc.updateData(["games": FieldValue.arrayUnion([[
            "gameID": gameReq.gameID,
            "opponent": gameReq.opponent
        ]])])
        
        otherUserDoc.updateData(["games": FieldValue.arrayUnion([[
            "gameID": gameReq.gameID,
            "opponent": self.username
        ]])])
        
        // Create data for the game: Board & Letter Bag
        let board: [String] = [String](repeating: "blank", count: 225)
        let letters: [Int] = [9, 2, 2, 4, 12, 2, 3, 2, 9, 1, 1, 4, 2, 6, 8, 2, 1, 6, 4, 6, 4, 2, 2, 1, 2, 1, 2]
        
        // Add necessary Data to the game
        gameDoc.setData(["gameComponents" : [
            "board": board,
            "letters": letters,
            "startofGame": true,
            "player1Turn": true,
            "turnStarted": false,
            "p1Score": 0,
            "p2Score": 0
            // Still need p1 & p2 letters, last turn, &
        ]], merge: true)
        
        // Refresh
        self.refresh()
        
    }
}
