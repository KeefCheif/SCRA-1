//
//  SCRA_1App.swift
//  SCRA-1
//
//  Created by KeefCheif on 1/3/22.
//

import SwiftUI
import Firebase
import FirebaseAuth

@main
struct SCRA_1App: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            /*
            MainGameView()
                .environmentObject(GameBoardViewModel())
            */
            LoginManagerView(login_manager: LoginManagerViewModel())
        }
    }
}

func checkLogin() -> Bool {
    return Auth.auth().currentUser == nil ? false : true
}
