//
//  GameManagerView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/31/22.
//

import SwiftUI

struct GameManagerView: View {
    
    @StateObject var view_model: GameViewModel
    @Binding var menu_state: MenuViewSelector
    
    var body: some View {
        
        if self.view_model.isLoading {
            GenericLoadingView()
        } else {
            
            VStack {
                
                GameTopNaveView(view_model: self.view_model)
                
                GeometryReader { board_geo in
                    VStack {
                        GameBoardView(view_model: self.view_model)
                            .modifier(BoardModifier(geo: board_geo, board_details: self.$view_model.board_details))
                            .frame(width: board_geo.size.width, height: board_geo.size.width)
                        
                        PlayerRackView(view_model: self.view_model, geo: board_geo)
                            .frame(width: board_geo.size.width, height: board_geo.size.width/6)
                        
                        GameBottomNavView(view_model: self.view_model, menu_state: self.$menu_state, geo: board_geo)
                    }
                    .coordinateSpace(name: "board_rack")
                }
            
            }
            .padding(4)
            .onAppear { self.view_model.attatchListener() }
            .onDisappear { if self.view_model.listener != nil { self.view_model.listener!.remove() } }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                if self.view_model.isTimer && self.view_model.isPlayerTurn() { self.view_model.endTurn(force: true) }
            }
        }
    }
}


struct GameBottomNavView: View {
    
    @ObservedObject var view_model: GameViewModel
    @Binding var menu_state: MenuViewSelector
    var geo: GeometryProxy
    
    var body: some View {
        VStack {
            
            GameSubmitRecallView(view_model: self.view_model, geo: self.geo)
            
            GameChallengeTradeView(view_model: self.view_model, geo: self.geo)
            
            Spacer()
            
            Button(action: {
                self.menu_state = .menu
            }, label: {
                Text("Exit")
                    .GameSelectorSubText()
                    .padding(6)
                    //.background(Rectangle().foregroundColor(.blue).cornerRadius(8).frame(width: self.geo.size.width/2))
                    .background(Rectangle().foregroundColor(.blue).cornerRadius(8).frame(width: 50))
            })
            
            Spacer()
        }
        .alert("Illegal Move", isPresented: .constant((self.view_model.move_error != nil || self.view_model.error != nil)), actions: {
            Button("Okay", role: .cancel, action: {
                self.view_model.move_error = nil
                self.view_model.error = nil
            })
        }, message: {
            if let move_error = self.view_model.move_error {
                Text(move_error.error.localizedDescription)
            } else if let error = self.view_model.error {
                Text(error.error.localizedDescription)
            }
        })
    }
}

struct GameChallengeTradeView: View {
    
    @ObservedObject var view_model: GameViewModel
    var geo: GeometryProxy
    
    @State var showChallengeAlert: Bool = false
    
    private var getChallengeColor: Color {
        if self.view_model.game_settings!.enableChallenges && self.view_model.isPlayerTurn() {
            return .red
        } else {
            return .gray
        }
    }
    
    private var getWords: String {
        
        var words: String = ""
        
        for (index, word) in self.view_model.challengeWords.enumerated() {
            words += word
            
            if index < self.view_model.challengeWords.count - 1 {
                words += ", "
            }
        }
        return words
    }
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                if self.view_model.isPlayerTurn() && self.view_model.game_settings!.enableChallenges {
                    self.view_model.getChallenegeWords()
                    
                    if !self.view_model.challengeWords.isEmpty {
                        self.showChallengeAlert = true
                    } else {
                        // Inform the play that their opponent did not play any words last turn
                    }
                }
            }, label: {
                Group {
                    Text("Challenge")
                        .GameSelectorSubText()
                        .multilineTextAlignment(.center)
                        .padding([.top, .bottom], 6)
                }
                .frame(width: self.geo.size.width/2.5, height: 40)
                .background(Rectangle().foregroundColor(self.getChallengeColor).cornerRadius(8))
            })
            
            Spacer()
            Spacer()
            
            Button(action: {
                
            }, label: {
                Group {
                    Text("Trade")
                        .GameSelectorSubText()
                        .multilineTextAlignment(.center)
                        .padding([.top, .bottom], 6)
                }
                .frame(width: self.geo.size.width/2.5, height: 40)
                .background(Rectangle().foregroundColor(.blue).cornerRadius(8))
            })
    
            Spacer()
            
        }
        .alert("Challenge", isPresented: self.$showChallengeAlert, actions: {
            Button("Challenge", role: .cancel, action: {
                self.view_model.challenge()
                self.showChallengeAlert = false
            })
            Button("Cancel", role: .destructive, action: {
                self.showChallengeAlert = false
            })
        }, message: {
            if !self.view_model.challengeWords.isEmpty {
                Text("Last turn your opponent played the word(s): \(self.getWords). Would you like to challenge these words? (If any of them are not real words then your challenge will be successful)")
            }
        })
        .alert("Challenge Result", isPresented: .constant(self.view_model.challenge_alert != nil), actions: {
            if self.view_model.challenge_alert != nil {
                switch self.view_model.challenge_alert!.error {
                case .lostChallenge:
                    Button("End my turn", role: .cancel, action: {
                        self.view_model.challenge_alert = nil
                        self.view_model.challengeAction(challenge_successful: false, useFreeChallenge: false, forceEndTurn: false)
                    })
                    if self.view_model.player_component!.freeChallenges > 0 {
                        Button("Use Free Challenge", role: .destructive, action: {
                            self.view_model.challengeAction(challenge_successful: false, useFreeChallenge: true, forceEndTurn: false)
                            self.view_model.challenge_alert = nil
                        })
                    }
                default:
                    Button("Okay", role: .cancel, action: {
                        self.view_model.challenge_alert = nil
                        self.view_model.challengeAction(challenge_successful: true, useFreeChallenge: false, forceEndTurn: false)
                    })
                }
            }
        }, message: {
            if let challenge_alert = self.view_model.challenge_alert {
                Text(challenge_alert.error.localizedDescription)
            }
        })
    }
}

struct GameSubmitRecallView: View {
    
    @ObservedObject var view_model: GameViewModel
    var geo: GeometryProxy
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                if self.view_model.isPlayerTurn() { self.view_model.endTurn(force: false) }
            }, label: {
                Group {
                    Text("Submit")
                        .GameSelectorSubText()
                        .multilineTextAlignment(.center)
                        .padding([.top, .bottom], 6)
                }
                .frame(width: self.geo.size.width/2.5, height: 40)
                .background(Rectangle().foregroundColor(self.view_model.isPlayerTurn() ? .green : .gray).cornerRadius(8))
            })
            
            Spacer()
            Spacer()
            
            Button(action: {
                self.view_model.recallTiles()
            }, label: {
                Group {
                    Text("Recall")
                        .GameSelectorSubText()
                        .multilineTextAlignment(.center)
                        .padding([.top, .bottom], 6)
                }
                .frame(width: self.geo.size.width/2.5, height: 40)
                .background(Rectangle().foregroundColor(.blue).cornerRadius(8))
            })
            
            Spacer()
        }
    }
}
