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
}

extension Image {
    func GameSelectorLogo() -> some View {
        self.resizable().scaledToFit().frame(width: 30).foregroundColor(.white)
    }
}


