//
//  GameSelectorModifiers.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import SwiftUI


extension Text {
    func GameSelectorSubText() -> some View {
        self.fontWeight(.heavy).foregroundColor(.white).font(.caption)
    }
    
    func selectorMessage() -> some View {
        self.fontWeight(.heavy).foregroundColor(.white).font(.caption).italic()
    }
}

extension Image {
    func GameSelectorLogo() -> some View {
        self.resizable().scaledToFit().frame(width: 40).foregroundColor(.white)
    }
    
    func selectorSubButton() -> some View {
        self.resizable().scaledToFit().frame(width: 20).foregroundColor(.white)
    }
}


