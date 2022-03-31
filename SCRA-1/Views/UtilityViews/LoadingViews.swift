//
//  LoadingViews.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/24/22.
//

import SwiftUI

struct GenericLoadingView: View {
    
    var message: String?
    
    var body: some View {
        
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(3)
                .padding()
            
            if let message = message {
                Text(message)
                    .fontWeight(.heavy)
                    .foregroundColor(.black)
                    .font(.subheadline)
            }
        }
    }
}

struct GenericLoadingViewBackground: View {
    
    var message: String?
    var color: UIColor

    var body: some View {
        
        ZStack {
            Color(self.color)
                .ignoresSafeArea()
                .opacity(0.8)
            
            GenericLoadingView(message: self.message)
        }
    }
}
