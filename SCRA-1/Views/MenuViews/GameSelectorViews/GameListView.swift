//
//  GameListView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import SwiftUI

struct GameListView: View {
    
    @ObservedObject var view_model: GameSelectorViewModel
    @Binding var gameID: String
    @Binding var menu_state: MenuViewSelector
    
    @State var acceptInviteAlert: Bool = false
    @State var inviteGame: Game? = nil
    
    var body: some View {
        
        if self.view_model.isLoading {
            GenericLoadingView()
        } else if self.view_model.games.isEmpty && self.view_model.gameReq.isEmpty && self.view_model.pendingReq.isEmpty{
        
            Text("You do not have any games nor requests. You can create a new game by tapping the plus button in the top left corner of the Games region.")
                .selectorMessage()
    
        } else {
            
            VStack {
                
                HStack {
                    Text("Games:")
                        .GameSelectorSubText()
                    Spacer()
                }
                if !self.view_model.games.isEmpty {
                    Group {
                        ScrollView(.horizontal) {
                            HStack {
                                Spacer()
                                
                                ForEach(self.view_model.games, id: \.self) { game in
                                    
                                    Button(action: {
                                        self.gameID = game.gameID
                                        self.menu_state = .game
                                    }, label: {
                                        VStack {
                                            Image(systemName: "person.2.circle")
                                                .GameSelectorLogo()
                                            Text("vs \(game.opponent)")
                                                .GameSelectorSubText()
                                        }
                                    })
                                    
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    
                } else {
                    Text("You do not have any games.")
                        .selectorMessage()
                        .padding(.top, 6)
                }
                
                Divider()
                
                HStack {
                    Text("Game Invites:")
                        .GameSelectorSubText()
                    Spacer()
                }
                
                if !self.view_model.gameReq.isEmpty {
                    Group {
                        ScrollView(.horizontal) {
                            HStack {
                                Spacer()
                                
                                ForEach(self.view_model.gameReq, id: \.self) { invite in
                                    
                                    Button(action: {
                                        self.inviteGame = invite
                                        self.acceptInviteAlert = true
                                    }, label: {
                                        VStack {
                                            Image(systemName: "person.circle")
                                                .GameSelectorLogo()
                                            Text(invite.opponent)
                                                .GameSelectorSubText()
                                        }
                                    })
                                    
                                }
                                
                                Spacer()
                            }
                        }
                    }
                } else {
                    Text("You do not have any game invites.")
                        .selectorMessage()
                        .padding(.top, 6)
                }
                
                Divider()
                
                HStack {
                    Text("Pending Invites:")
                        .GameSelectorSubText()
                    Spacer()
                }
                
                if !self.view_model.pendingReq.isEmpty {
                    Group {
                        ScrollView(.horizontal) {
                            HStack {
                                Spacer()
                                
                                ForEach(self.view_model.pendingReq, id: \.self) { pending in
                                    
                                    VStack {
                                        Image(systemName: "person.circle")
                                            .GameSelectorLogo()
                                        Text(pending.opponent)
                                            .GameSelectorSubText()
                                    }
                                    
                                }
                                
                                Spacer()
                            }
                        }
                    }
                } else {
                    Text("You do not have any pending game invites.")
                        .GameSelectorSubText()
                        .padding(.top, 6)
                }
            }
            .alert("Accept Game Invite?", isPresented: self.$acceptInviteAlert, actions: {
                Button("Yes", role: .cancel, action: {
                    self.view_model.acceptGameRequest(gameReq: self.inviteGame!)
                    self.acceptInviteAlert = false
                    self.inviteGame = nil
                })
                Button("No", role: .destructive, action: {
                    self.view_model.rejectGameRequest(gameReq: self.inviteGame!)
                    self.acceptInviteAlert = false
                    self.inviteGame = nil
                })
            }, message: {
                Text("Would you like to accept the game invite from \(self.inviteGame == nil ? "" : self.inviteGame!.opponent)?")
            })
        }
    }
    
}
