//
//  ColoredToggleStyle.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/29/22.
//

import SwiftUI

// This Toggle Style allows one to customize the colors associated with a ToggleView
// An example of its usage can be seen in the NewPostDisplayView.swift file
struct ColoredToggleStyle: ToggleStyle {
    var label = ""
    var onColor = Color(UIColor.green)
    var offColor = Color(UIColor.systemGray5)
    var thumbColor = Color.white
    //var toggle: Bool = false
    
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            if (self.label != "") {
                Text(label)
                Spacer()
            }
            Button(action: { configuration.isOn.toggle() } )
            {
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .fill(configuration.isOn ? onColor : offColor)
                    .frame(width: 50, height: 29)
                    .overlay(
                        Circle()
                            .fill(thumbColor)
                            .shadow(radius: 1, x: 0, y: 1)
                            .padding(1.5)
                            .offset(x: configuration.isOn ? 10 : -10))
                    .animation(.easeInOut(duration: 0.1), value: configuration.isOn)
            }
        }
        .font(.title)
        .padding(.horizontal)
    }
}


struct ToggleButton: View {
    
    var onColor: Color
    var offColor: Color
    var thumbColor: Color
    var message: String
    
    @Binding var toggleStatus: Bool
    
    var body: some View {
        
        HStack {
            
            Group {
                
                Text(self.message)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                
                Toggle("", isOn: self.$toggleStatus)
                    .toggleStyle(ColoredToggleStyle(onColor: self.onColor, offColor: self.offColor, thumbColor: self.thumbColor))
                
            }
            .padding(10)
        }
    }
}
