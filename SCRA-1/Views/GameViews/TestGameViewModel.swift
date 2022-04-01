//
//  TestGameViewModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/31/22.
//

import SwiftUI

struct TestGameViewModel: View {
    
    @ObservedObject var view_model: GameViewModel
    @Binding var menu_state: MenuViewSelector
    
    var body: some View {
        Text("YAY")
    }
}
