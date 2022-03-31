//
//  InviteFriendView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/26/22.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct InviteFriendView: View {
    
    @EnvironmentObject var view_model: FriendSelectorViewModel
    @Binding var displayUser: BasicUser?
    @Binding var view_state: FriendSelectorState
    
    @State var friendSelctorError: FriendSelectorErrorType?
    @State var username: String = ""
    @State var displayUsername: String = ""
    
    var body: some View {
        
        VStack {
            
            TextField("Username", text: self.$displayUsername)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .font(.title)
            
            HStack {
                
                Spacer()
                
        // - - - - - Cancel Button - - - - - //
                Button(action: {
                    self.view_state = .listFriends
                }, label: {
                    HStack {
                        Image(systemName: "chevron.left.circle")
                            .selectorSubButton()
                        Text("Cancel")
                            .GameSelectorSubText()
                    }
                })
                
                Spacer()
                        
        // - - - - - Submit Button - - - - - //
                Button(action: {
                    
                    self.username = self.displayUsername.lowercased()       // Lowercase the username so it can easily be searched for
                    
                    self.validateOutgoingRequest { (user, error) in
                        if let error = error {
                            self.friendSelctorError = FriendSelectorErrorType(error: error)
                        } else if let user = user {
                            self.displayUser = user
                            self.view_state = .displayResult
                        } else {
                            self.friendSelctorError = FriendSelectorErrorType(error: .unknown)
                        }
                    }
                    
                }, label: {
                    HStack {
                        Image(systemName: "pencil.circle")
                            .selectorSubButton()
                        Text("Submit")
                            .GameSelectorSubText()
                    }
                })
                
                Spacer()
            }
        }
        .alert(item: self.$friendSelctorError) { (error) in
            Alert(title: Text("Login Failed"), message: Text(error.error.localizedDescription), dismissButton: .default(Text("Okay")) {
                self.friendSelctorError = nil
            })
        }
        
    }


    private func validateOutgoingRequest(completion: @escaping (BasicUser?, FriendSelectorError?) -> Void) {
        
        let db = Firestore.firestore()
        let userCollection = db.collection("users")
        
        let _ = userCollection.whereField("username", isEqualTo: self.username).getDocuments { (querySnapshot, error) in
        
            if let error = error {
                completion(nil, .propogatedError(error.localizedDescription))
            } else if let querySnapshot = querySnapshot {
                
                if querySnapshot.documents.isEmpty || querySnapshot.documents.count > 1 {
                    completion(nil, .userNotFound)
                } else {
                    
                    if querySnapshot.documents[0].documentID == Auth.auth().currentUser!.uid {
                        completion(nil, .selfRequest)    // Tried to send a friend request to themself
                    } else {
                        
                        let otherUserID = querySnapshot.documents[0].documentID
                        
                        if self.alreadyFriends(otherUserID: otherUserID) {
                            completion(nil, .alreadyFriends)
                        } else if self.alreadyRequested(otherUserID: otherUserID) {
                            completion(nil, .alreadyRecievedRequest)
                        } else if self.alreadyPending(otherUserID: otherUserID) {
                            completion(nil, .alreadySentRequest)
                        } else {
                            
                            let data = querySnapshot.documents[0].data()
                            let displayUsername = data["displayUsername"]! as! String
                            completion(BasicUser(displayUsename: displayUsername, username: self.username, userID: otherUserID), nil)
                            
                        }
                    }
                }
                
            } else {
                completion(nil, .unknown)
            }
        }
    }
    
    
    private func alreadyFriends(otherUserID: String) -> Bool {
        
        for friend in self.view_model.friends {
            if friend.userID! == otherUserID {
                return true
            }
        }
        
        return false
    }
    
    
    private func alreadyPending(otherUserID: String) -> Bool {
        
        if let pending = self.view_model.pendingReq {
            
            for pend in pending {
                if pend.userID! == otherUserID {
                    return true
                }
            }
        }
        
        return false
    }
    
    
    private func alreadyRequested(otherUserID: String) -> Bool {
        
        if let requests = self.view_model.friendReq {
            
            for req in requests {
                if req.userID! == otherUserID {
                    return true
                }
            }
        }
        
        return false
    }

}
