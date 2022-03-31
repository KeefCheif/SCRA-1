//
//  ListFriendsViewModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/26/22.
//

import Foundation
import Firebase
import SwiftUI
import FirebaseAuth

class FriendSelectorViewModel: ObservableObject {
    
    @Published var isLoading: Bool = true
    
    @Published var state: FriendSelectorState = .listFriends
    
    @Published var friends: [BasicUser] = [BasicUser]()
    
    @Published var friendReq: [BasicUser]?
    
    @Published var pendingReq: [BasicUser]?
    
    @Published var error: FriendSelectorErrorType?
    
    @Published var isError: Bool = false
    
    init() {
        self.refreshAll()
    }
    
    func refreshAll() {
        
        if !self.isLoading {
            self.isLoading = true
        }
        
        self.getUsers(type: .all) { [unowned self] (friendUsers, requests, pending, error) in
            
            if let error = error {
                self.error = FriendSelectorErrorType(error: error)
                self.isLoading = false
            } else if let friendUsers = friendUsers {
                
                self.friends = friendUsers
                self.friendReq = requests
                self.pendingReq = pending
                self.isLoading = false
                
            } else {
                self.error = FriendSelectorErrorType(error: .unknown)
                self.isLoading = false
            }
            
        }
        
    }
    
    
    // Completion: (Friends, RecievedRequest, PendingRequests, Error)
    private func getUsers(type: FriendSelectorType, completion: @escaping ([BasicUser]?, [BasicUser]?, [BasicUser]?, FriendSelectorError?) -> Void) {
        
        if let currentUser = Auth.auth().currentUser {
            
            let db = Firestore.firestore()
            let userDoc = db.collection("users").document(currentUser.uid)
            
            userDoc.getDocument { (docSnap, error) in
                
                if let error = error {
                    completion(nil, nil, nil, .propogatedError(error.localizedDescription))
                } else if let docSnap = docSnap {
                    
                    let data = docSnap.data()!
                    
                    let friends: [String] = data["friends"]! as! [String]
                    let requests: [String] = data["friendReq"]! as! [String]
                    let pending: [String] = data["pendingFriendReq"]! as! [String]
                    
                    var allUsers: [String] = [String]()
                    
                    switch type {
                    case .all:
                        allUsers = friends + requests + pending
                    case .friends:
                        allUsers = friends
                    case .reqPend:
                        allUsers = requests + pending
                    }
                    
                    if allUsers.isEmpty {
                        completion([BasicUser](), nil, nil, nil)
                    } else {
                        
                        self.getUsersDetails(userIDs: allUsers, returnUsers: [BasicUser]()) { (result, error) in
                        
                            if let error = error {
                                completion(nil, nil, nil, .propogatedError(error.localizedDescription))
                            } else if let result = result {
                                
                                var pendingUsers: [BasicUser]?
                                var requestUsers: [BasicUser]?
                                var friendUsers: [BasicUser] = [BasicUser]()
                                
                                switch type {
                                case .all:
                                    pendingUsers = (pending.isEmpty) ? nil : Array(result[0..<pending.count])
                                    requestUsers = (requests.isEmpty) ? nil : Array(result[pending.count..<(pending.count + requests.count)])
                                    friendUsers = (friends.isEmpty) ? [BasicUser]() : Array(result[(pending.count + requests.count)..<result.count])
                                case .friends:
                                    friendUsers = result
                                case .reqPend:
                                    pendingUsers = (pending.isEmpty) ? nil : Array(result[0..<pending.count])
                                    requestUsers = (requests.isEmpty) ? nil : Array(result[pending.count..<(pending.count + requests.count)])
                                }

                                completion(friendUsers, requestUsers, pendingUsers, nil)
                                
                            } else {
                                completion(nil, nil, nil, .unknown)
                            }
                            
                        }
                    }
                    
                } else {
                    completion(nil, nil, nil, .unknown)
                }
                
            }
            
        } else {
            completion(nil, nil, nil, .notLoggedIn)
        }
    }
    
    
    private func getUsersDetails(userIDs: [String], returnUsers: [BasicUser], completion: @escaping ([BasicUser]?, FriendSelectorError?) -> Void) {
       
        if userIDs.isEmpty {
            completion(returnUsers, nil)
        } else {
            
            var tempUserIDs = userIDs
            
            self.getBasicUser(userID: tempUserIDs.popLast()!) { (result, error) in
                
                if let error = error {
                    completion(nil, .propogatedError(error.localizedDescription))
                } else if let result = result {
                    
                    var tempReturnUsers = returnUsers
                    tempReturnUsers.append(result)
                    
                    self.getUsersDetails(userIDs: tempUserIDs, returnUsers: tempReturnUsers) { (result, error) in
                        
                        if let error = error {
                            completion(nil, .propogatedError(error.localizedDescription))
                        } else if let result = result {
                            completion(result, nil)
                        } else {
                            completion(nil, .unknown)
                        }
                        
                    }
                    
                } else {
                    completion(nil, .unknown)
                }
            }
        }
    }
    
    
    // This function gets the username, displayUsername, & profile picture (not done yet) for a given username
    private func getBasicUser(userID: String, completion: @escaping (BasicUser?, FriendSelectorError?) -> Void) {
        
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(userID)
        
        userDoc.getDocument { (docSnap, error) in
            
            if let error = error {
                completion(nil, .propogatedError(error.localizedDescription))
            } else if let docSnap = docSnap {
                
                let data = docSnap.data()!
                
                let username: String = data["username"]! as! String
                let displayUsername: String = data["displayUsername"]! as! String
                
                completion(BasicUser(displayUsename: displayUsername, username: username, userID: userID), nil)
                
            } else {
                completion(nil, .unknown)
            }
            
        }
    }
    
}

enum FriendSelectorType {
    
    case all
    case friends
    case reqPend
    
}
