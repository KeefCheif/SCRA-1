//
//  MenuManagerView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/21/22.
//

import SwiftUI
import FirebaseAuth

struct MenuManagerView: View {
    
    @Binding var loggedIn: Bool
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Button(action: {
                    self.signOut()
                }, label: {
                    Text("Sign Out")
                        .bold()
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Rectangle().cornerRadius(8).foregroundColor(.red).frame(width: geo.size.width/5))
                })
            }
        }
        
    }
    
    private func signOut() {
        do {
            try Auth.auth().signOut()
            self.loggedIn = false
        } catch {
            print("SIGN OUT FAILED")
        }
    }
}

struct MenuManagerView_Previews: PreviewProvider {
    static var previews: some View {
        MenuManagerView(loggedIn: Binding.constant(true))
    }
}
