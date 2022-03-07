//
//  SCRA_1App.swift
//  SCRA-1
//
//  Created by KeefCheif on 1/3/22.
//

import SwiftUI

@main
struct SCRA_1App: App {
    var body: some Scene {
        WindowGroup {
            MainGameView()
                .environmentObject(GameBoardViewModel())
        }
    }
}
