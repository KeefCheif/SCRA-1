//
//  GameSelectorCreateGame.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/28/22.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct GameSelectorCreateGame: View {
    
    @ObservedObject var view_model: GameSelectorViewModel

    // - - - - - Toggle & Slider Values - - - - - //
    @State private var enableTimeRestriction: Bool = false
    @State private var timeSelection: Double = 3.0
    
    @State private var enableChallenges: Bool = false
    @State private var freeChallenges: Double = 0.0
    
    // - - - - - Info Alert Values - - - - - //
    @State private var showInfoMessage: Bool = false
    @State private var infoTitle: String = ""
    @State private var infoMessage: String = ""
    
    
    var body: some View {
        
        VStack {
            Text("Game Settings")
                .selectorMessage()
            
            Divider()
            
    // - - - - - Time Limit Toggle & Slider - - - - - //
            Group {
                Toggle(isOn: self.$enableTimeRestriction, label: {
                    HStack(spacing:0) {
                        Button(action: {
                            self.infoTitle = "Time Limit"
                            self.infoMessage = "Enables a chosen time limit for each players turn."
                            self.showInfoMessage = true
                        }, label: {
                            Text("Time Limit")
                                .GameSelectorSubText()
                        })
                    }
                })
                    .frame(width: 150)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
            }
                
            if (self.enableTimeRestriction) {
                Slider(value: self.$timeSelection, in: 0.5...15, step: 0.5)
            } else {
                Slider(value: Binding.constant(0.0), in: 0...0)
            }
            Text(self.enableTimeRestriction ? "Minutes: \(self.timeSelection, specifier: "%.1f")" : "Minutes: unlimited")
                .selectorMessage()
            
            Divider()
            
    // - - - - - Challenges Toggle & Slider - - - - - //
            Group {
                Toggle(isOn: self.$enableChallenges, label: {
                    Button(action: {
                        self.infoTitle = "Challenges"
                        self.infoMessage = "Enables challenges so that an illegal word could be played so long as your opponent does not challenge it. Additionally, failing a challenge results in the challenger losing their turn unless they have any Free Challenges."
                        self.showInfoMessage = true
                    }, label: {
                        Text("Challenges")
                            .GameSelectorSubText()
                    })
                })
                    .frame(width: 150)
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                
                if (self.enableChallenges) {
                    Slider(value: self.$freeChallenges, in: 0.0...50, step: 1.0)
                } else {
                    Slider(value: Binding.constant(0.0), in: 0.0...50)
                }
                Text(self.enableChallenges ? "Free Challenges: \(self.freeChallenges == 50.0 ? "unlimited" : String(self.freeChallenges))" : "Free Challenges: NA")
                    .selectorMessage()
            }
            
            Divider()
            
    // - - - - - Cancel & Submit Button - - - - - //
            HStack {
                Spacer()
                
                Button(action: {
                    self.view_model.state = .list_friends
                }, label: {
                    HStack {
                        Image(systemName: "chevron.left.circle")
                            .selectorSubButton()
                        Text("Cancel")
                            .GameSelectorSubText()
                    }
                })
                
                Button(action: {
                    self.sendGameInvite() { error in
                        if let _ = error {
                            self.view_model.isError = true
                        } else {
                            self.view_model.invitee = nil
                            self.view_model.refresh()
                            self.view_model.state = .list
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
        .alert(self.infoTitle, isPresented: self.$showInfoMessage, actions: {
            Button("Okay", role: .cancel, action: {
                self.infoTitle = ""
                self.infoMessage = ""
                self.showInfoMessage = false
            })
        }, message: {
            Text(self.infoMessage)
        })
        .alert("Error Sending Invite", isPresented: self.$view_model.isError, actions: {
            Button("Okay", role: .cancel, action: {
                self.view_model.isError = false
                self.view_model.error = nil
            })
        }, message: {
            Text("Failed to send the game invite.")
        })
    }
    
    private func sendGameInvite(completion: @escaping (GameSelectorError?) -> Void) {
       
        DispatchQueue.main.async {
            let db = Firestore.firestore()
            let otherUserDoc = db.collection("users").document(self.view_model.invitee!.userID!)
            let userDoc = db.collection("users").document(Auth.auth().currentUser!.uid)
            
            userDoc.getDocument { (docSnap, error) in
                if let error = error {
                    completion(.propogatedError(error.localizedDescription))
                } else if let docSnap = docSnap {
                    
                    let displayUsername = docSnap.data()!["displayUsername"]! as! String
                    
                    let game = db.collection("games").addDocument(data: [
                        "gameSettings": [
                            "timeRestriction": Int(self.timeSelection * 60),
                            "enableChallenges": self.enableChallenges,
                            "freeChallenges": self.freeChallenges,
                            "player1": self.view_model.invitee!.displayUsename,
                            "player2": displayUsername,
                            "player1ID": self.view_model.invitee!.userID!,
                            "player2ID": Auth.auth().currentUser!.uid
                        ],
                        self.view_model.invitee!.userID!: [      // Player1 Component
                            "freeChallenges": self.freeChallenges >= 50 ? 100 : self.freeChallenges,
                        ],
                        Auth.auth().currentUser!.uid: [                              // Player2 Component
                            "freeChallenges": self.freeChallenges >= 50 ? 100 : self.freeChallenges,
                        ]
                    ]) { error in
                        if let error = error {
                            completion(.propogatedError(error.localizedDescription))
                        }
                    }
                    
                    userDoc.updateData(["pendingGameReq": FieldValue.arrayUnion([[
                        "gameID": game.documentID,
                        "opponent": self.view_model.invitee!.displayUsename,
                        "opponentID": self.view_model.invitee!.userID!
                    ]])])
                    
                    otherUserDoc.updateData(["gameReq": FieldValue.arrayUnion([[
                        "gameID": game.documentID,
                        "opponent": displayUsername,
                        "opponentID": Auth.auth().currentUser!.uid
                    ]])])
                    
                    completion(nil)
                    
                } else {
                    completion(.unknown)
                }
            }
        }
    }
    
}
