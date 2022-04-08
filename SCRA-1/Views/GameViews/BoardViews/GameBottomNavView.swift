//
//  GameBottomNavView.swift
//  SCRA-1
//
//  Created by peter allgeier on 4/8/22.
//

import SwiftUI

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
                    .background(Rectangle().foregroundColor(.blue).cornerRadius(8).frame(width: 50))
            })
            
            Spacer()
        }
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
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                if self.view_model.isPlayerTurn() && self.view_model.game_settings!.enableChallenges {
                    self.view_model.getChallenegeWords()
                    
                    if !self.view_model.challengeWords.isEmpty {
                        self.view_model.challenge_alert = ChallengeAlertType(error: .challengeAlert(self.view_model.challengeWords))
                    } else {
                        self.view_model.challenge_alert = ChallengeAlertType(error: .cannotChallenge("your opponent did not play any words last turn"))
                    }
                } else {
                    self.view_model.challenge_alert = ChallengeAlertType(error: .cannotChallenge(self.view_model.isPlayerTurn() ? "challenges are disabled" : "it is not your turn"))
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
        .alert("Challenge", isPresented: .constant(self.view_model.challenge_alert != nil), actions: {
            if self.view_model.challenge_alert != nil {
                switch self.view_model.challenge_alert!.error {
                case .cannotChallenge:
                    Button("Okay", role: .cancel, action: {
                        self.view_model.challenge_alert = nil
                    })
                case .challengeAlert:
                    Button("Challenge", role: .destructive, action: {
                        self.view_model.challenge()
                        self.view_model.challenge_alert = nil
                    })
                    Button("Cancel", role: .cancel, action: {
                        self.view_model.challenge_alert = nil
                    })
                case .lostChallenge:
                    Button("End my turn", role: .cancel, action: {
                        self.view_model.challenge_alert = nil
                        self.view_model.challengeAction(challenge_successful: false, useFreeChallenge: false, forceEndTurn: false)
                    })
                    if self.view_model.player_component!.freeChallenges > 0 {
                        Button("Use Free Challenge", role: .destructive, action: {
                            self.view_model.challenge_alert = nil
                            self.view_model.challengeAction(challenge_successful: false, useFreeChallenge: true, forceEndTurn: false)
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
            if let alert = self.view_model.challenge_alert {
                Text(alert.error.localizedDescription)
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
        .alert("Illegal Move", isPresented: .constant((self.view_model.move_error != nil)), actions: {
            Button("Okay", role: .cancel, action: {
                self.view_model.move_error = nil
            })
        }, message: {
            if let move_error = self.view_model.move_error {
                Text(move_error.error.localizedDescription)
            }
        })
    }
}
