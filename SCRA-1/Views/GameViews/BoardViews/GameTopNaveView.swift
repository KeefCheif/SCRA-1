//
//  GameTopNaveView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/31/22.
//

import SwiftUI

struct GameTopNaveView: View {
    
    @ObservedObject var view_model: GameViewModel
    
    var userScore: String {
        return String(self.view_model.isPlayer1 ? self.view_model.game_state!.p1Score : self.view_model.game_state!.p2Score)
    }
    
    var otherUserScore: String {
        return String(self.view_model.isPlayer1 ? self.view_model.game_state!.p2Score : self.view_model.game_state!.p1Score)
    }
    
    var username: String {
        return self.view_model.isPlayer1 ? String(self.view_model.game_settings!.player1.prefix(2)) : String(self.view_model.game_settings!.player2.prefix(2))
    }
    
    var otherUsername: String {
        return self.view_model.isPlayer1 ? String(self.view_model.game_settings!.player2.prefix(2)) : String(self.view_model.game_settings!.player1.prefix(2))
    }
    
    var body: some View {
        
        HStack {
         
            HStack {
                
                Text(self.username)
                    .GameSelectorSubText()
                    .padding(6)
                    .background(Circle().foregroundColor(.gray))
                
                Spacer()
                
                Text(self.userScore)
                    .GameSelectorSubText()
                
                if self.view_model.isTimer {
                    
                    Spacer()
                    
                    VStack {
                        Text("Time Remaining")
                            .selectorMessage()
                        
                        TimerView(game_model: self.view_model, timer_model: TimerViewModel(total_time_sec: Int(self.view_model.game_settings!.timeRestriction * 60)))
                            
                    }
                    
                    Spacer()
                    
                } else {
                    Spacer()
                }
                
                Text(self.otherUserScore)
                    .GameSelectorSubText()
                
                Spacer()
                
                Text(self.otherUsername)
                    .GameSelectorSubText()
                    .padding(6)
                    .background(Circle().foregroundColor(.gray))
            }
        }
        .padding(4)
        .background(LinearGradient(gradient: Gradient(stops: [Gradient.Stop(color: .blue, location: 0.5), Gradient.Stop(color: .red, location: 0.5)]), startPoint: .leading, endPoint: .trailing).cornerRadius(8))
    }
}

struct TimerView: View {
    
    @ObservedObject var game_model: GameViewModel
    @StateObject var timer_model: TimerViewModel
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        
        HStack(spacing: 1) {
            
            Spacer()
            
            Text("\(self.timer_model.min_tens)")
                .GameSelectorSubText()
            Text("\(self.timer_model.min_ones)")
                .GameSelectorSubText()
            
            Text(":")
                .GameSelectorSubText()
            
            Text("\(self.timer_model.sec_tens)")
                .GameSelectorSubText()
            Text("\(self.timer_model.sec_ones)")
                .GameSelectorSubText()
            
            Spacer()
            
        }
        .onReceive(timer) { _ in
            if self.timer_model.timerFinished {
                self.timer.upstream.connect().cancel()  // Stop the Timer
                // End their turn
            } else {
                self.timer_model.updateTimer()
            }
        }
    }
}
