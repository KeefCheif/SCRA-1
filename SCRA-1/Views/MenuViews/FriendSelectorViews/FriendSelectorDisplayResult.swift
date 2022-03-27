//
//  FriendSelectorDisplayResult.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/27/22.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct FriendSelectorDisplayResult: View {
    
    @EnvironmentObject var view_model: FriendSelectorViewModel
    @Binding var displayUser: BasicUser?
    @Binding var view_state: FriendSelectorState
    
    var body: some View {
        
        if let profile = self.displayUser {
            VStack {
                
                Image(systemName: "person.circle")
                    .GameSelectorLogo()
                
                Text(profile.displayUsename)
                    .GameSelectorSubText()
                
                HStack {
                    
                    Spacer()
                    
                // Cancel Button
                    Button(action: {
                        self.displayUser = nil
                        self.view_state = .requestFriend
                    }, label: {
                        HStack {
                            Image(systemName: "chevron.left.circle")
                                .selectorSubButton()
                            Text("Cancel")
                                .GameSelectorSubText()
                        }
                    })
                    
                    Spacer()
                    
                    Button(action: {
                        self.sendFriendRequest()
                        self.displayUser = nil
                        self.view_model.refreshAll()
                        self.view_state = .listFriends
                    }, label: {
                        HStack {
                            Image(systemName: "paperplane.circle")
                                .selectorSubButton()
                            Text("Send")
                                .GameSelectorSubText()
                        }
                    })
                    
                    Spacer()
                }
                
            }
        } else {
            
            Text("No user found")
                .GameSelectorSubText()
            
            Button(action: {
                self.displayUser = nil
                self.view_state = .requestFriend
            }, label: {
                HStack {
                    Image(systemName: "chevron.left.circle")
                        .selectorSubButton()
                    Text("Back")
                        .GameSelectorSubText()
                }
            })
            
        }
    }
    
    private func sendFriendRequest() {
        
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(Auth.auth().currentUser!.uid)
        let otherUserDoc = db.collection("users").document(self.displayUser!.userID!)
        
        userDoc.setData(["pendingFriendReq": [self.displayUser!.userID!]], merge: true)
        otherUserDoc.setData(["friendReq": [Auth.auth().currentUser!.uid]], merge: true)
        
        return
    }
}
