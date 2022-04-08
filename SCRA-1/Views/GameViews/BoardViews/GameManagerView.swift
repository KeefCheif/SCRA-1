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
                if self.view_model.isTimer && self.view_model.isPlayerTurn() {
                    self.view_model.endTurn(force: true)
                }
            }
            .alert("Game Update", isPresented: .constant(self.view_model.game_alert != nil), actions: {
                if self.view_model.game_alert != nil {
                    switch self.view_model.game_alert!.error {
                    case .lostCurrentTurn:
                        Button("Okay", role: .cancel, action: {
                            self.view_model.game_alert = nil
                            self.view_model.endTurn(force: true)
                        })
                    case .opponentResigned:
                        Button("Okay", role: .cancel, action: {
                            self.view_model.game_alert = nil
                            // Prepare game to be deleted when they exit
                        })
                    case .gameOver:
                        Button("Okay", role: .cancel, action: {
                            self.view_model.game_alert = nil
                            // Prepare game to be deleted when they exit only if the other person has already exited
                        })
                    case .errorGettingGame:
                        Button("Exit", role: .cancel, action: {
                            // Not sure if this works
                            self.view_model.game_alert = nil
                            self.menu_state = .menu
                        })
                    default:
                        Button("Okay", role: .cancel, action: {
                            self.view_model.game_alert = nil
                        })
                    }
                }
            }, message: {
                
            })
        }
    }
}
