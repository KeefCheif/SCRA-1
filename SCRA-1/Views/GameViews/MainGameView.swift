//
//  MainGameView.swift
//  SCRA-1
//
//  Created by KeefCheif on 3/7/22.
//

import SwiftUI

struct MainGameView: View {
    
    @EnvironmentObject var view_model: GameBoardViewModel
    
    var body: some View {
        
        GeometryReader { geo in
            
            VStack {
                
                GameBoardWrapperView2()
                    .frame(width: geo.size.width, height: geo.size.width + geo.size.width/6)
                    .environmentObject(self.view_model)
                
                Button(action: {
                    self.view_model.recallTiles()
                    
                }, label: {
                    Text("Recall")
                })
                
            }
        }
        .padding(4)
    }
}
