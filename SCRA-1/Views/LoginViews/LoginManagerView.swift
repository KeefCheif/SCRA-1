//
//  LoginManagerView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/10/22.
//

import SwiftUI

struct LoginManagerView: View {
    
    @StateObject var login_manager: LoginManagerViewModel
    
    var body: some View {
        
        if (login_manager.state.loggedIn) {
            
            MenuManagerView()
            
        } else {
            
            GeometryReader { geo in
                
                VStack {
                    
                }
                
            }
            
        }
        
    }
}

struct LoginManagerView_Previews: PreviewProvider {
    static var previews: some View {
        LoginManagerView(login_manager: LoginManagerViewModel())
    }
}
