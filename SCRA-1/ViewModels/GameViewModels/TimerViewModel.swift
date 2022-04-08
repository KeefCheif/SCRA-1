//
//  TimerViewModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/31/22.
//

import Foundation

class TimerViewModel: ObservableObject {
    
    @Published var min_tens: Int = 0
    
    @Published var min_ones: Int = 0
    
    @Published var sec_tens: Int = 0
    
    @Published var sec_ones: Int = 0
    
    // - - - - - Timer Control Variables - - - - - //
    
    @Published var timerFinished: Bool = false
    
    @Published var total_time_sec: Int = 0
    
    private var timer: Timer!
    
    init(total_time_sec: Int) {
        
        self.total_time_sec = total_time_sec
        
        let minutes: Int = total_time_sec/60
        let seconds: Int = total_time_sec%60
        
        self.min_tens = minutes/10
        self.min_ones = minutes%10
        
        self.sec_tens = seconds/10
        self.sec_ones = seconds%10
        
        var runner: (() -> ())?
        runner = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                if let self = self {
                    self.updateTimer()
                    runner?()
                }
            }
        }
        runner?()
    }
    
    func updateTimer() {
        
        if self.sec_ones == 0 {
            
            if self.sec_tens == 0 {
                
                if self.min_ones == 0 {
                    
                    if self.min_tens == 0 {
                        
                        self.timerFinished = true
                        
                    } else {
                        self.min_tens -= 1
                        self.min_ones = 9
                        self.sec_tens = 5
                        self.sec_ones = 9
                    }
                    
                } else {
                    self.min_ones -= 1
                    self.sec_tens = 5
                    self.sec_ones = 9
                }
                
            } else {
                self.sec_tens -= 1
                self.sec_ones = 9
            }
            
        } else {
            self.sec_ones -= 1
        }
        return
    }
}
