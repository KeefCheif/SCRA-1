//
//  FriendSelectorInvites.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/27/22.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct FriendSelectorInvites: View {
    
    @EnvironmentObject var view_model: FriendSelectorViewModel
    @Binding var view_state: FriendSelectorState
    
    @Binding var friendReq: [BasicUser]?
    @Binding var pendingReq: [BasicUser]?
    
    @State var respondAlert: FriendSelectorErrorType?
    @State var respondingTo: String = ""
    
    var body: some View {
        
        VStack {
            
            HStack {
                Text("Friend Requests:")
                    .GameSelectorSubText()
                Spacer()
            }
            
            if let friendReq = friendReq {
                
                ScrollView(.horizontal) {
                    HStack {
                        Spacer()
                        
                        ForEach(friendReq, id: \.self) { req in
                            
        // - - - - - Friend Request Button - - - - - //
                            Button(action: {
                                self.respondingTo = req.userID!
                                self.respondAlert = FriendSelectorErrorType(error: .respondFriendRequest(req.displayUsename))
                            }, label: {
                                VStack {
                                    Image(systemName: "person.circle")
                                        .GameSelectorLogo()
                                    Text(req.displayUsename)
                                        .GameSelectorSubText()
                                }
                            })
                            
                        }
                        
                        Spacer()
                    }
                }
                
            } else {
                Text("\nYou do not have any friend requests :(\n")
                    .selectorMessage()
            }
            
            HStack{
                Text("Pending Friend Requests:")
                    .GameSelectorSubText()
                Spacer()
            }
            
            if let pendingReq = pendingReq {
                
                ScrollView(.horizontal) {
                    HStack {
                        
                        Spacer()
                        
                        ForEach(pendingReq, id: \.self) { pend in
                            
                            VStack {
                                Image(systemName: "person.circle")
                                    .GameSelectorLogo()
                                Text(pend.displayUsename)
                                    .GameSelectorSubText()
                            }
                            
                        }
                        
                        Spacer()
                        
                    }
                }
                
            } else {
                Text("\nYou do not have any pending friend requests\n")
                    .selectorMessage()
            }
            
    // - - - - - Back Button - - - - - //
            Button(action: {
                self.view_state = .listFriends
            }, label: {
                HStack {
                    Image(systemName: "chevron.left.circle")
                        .selectorSubButton()
                    Text("Back")
                        .GameSelectorSubText()
                }
            })
            
        }
        .alert("Friend Request", isPresented: .constant(self.respondAlert != nil), actions: {
            Button("Yes", role: .cancel, action: {
                self.acceptFriendReq()
                
                self.respondAlert = nil
                self.respondingTo = ""
                
                self.view_model.refreshAll()
                self.view_state = .listFriends
            })
            
            Button("No", role: .destructive, action: {
                self.rejectFriendReq()
                
                self.respondAlert = nil
                self.respondingTo = ""
                
                self.view_model.refreshAll()
                if let friendReq = self.friendReq, let pendingReq = self.pendingReq  {
                    if friendReq.isEmpty && pendingReq.isEmpty {
                        self.view_state = .listFriends
                    }
                } else {
                    self.view_state = .listFriends
                }
            })
        }, message: {
            if let respondAlert = self.respondAlert {
                Text(respondAlert.error.localizedDescription)
            }
        })
    }
    
    
    private func acceptFriendReq() {
        
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(Auth.auth().currentUser!.uid)
        let otherUserDoc = db.collection("users").document(self.respondingTo)
        
        userDoc.updateData(["friends": FieldValue.arrayUnion([self.respondingTo])])
        otherUserDoc.updateData(["friends": FieldValue.arrayUnion([Auth.auth().currentUser!.uid])])
        
        userDoc.updateData(["friendReq": FieldValue.arrayRemove([self.respondingTo])])
        otherUserDoc.updateData(["pendingFriendReq": FieldValue.arrayRemove([Auth.auth().currentUser!.uid])])
        
    }
    
    
    private func rejectFriendReq() {
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(Auth.auth().currentUser!.uid)
        let otherUserDoc = db.collection("users").document(self.respondingTo)
        
        userDoc.updateData(["friendReq": FieldValue.arrayRemove([self.respondingTo])])
        otherUserDoc.updateData(["pendingFriendReq": FieldValue.arrayRemove([Auth.auth().currentUser!.uid])])
    }
    
}
