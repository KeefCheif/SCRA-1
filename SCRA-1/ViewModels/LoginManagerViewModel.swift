//
//  LoginManagerViewModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/10/22.
//

import Foundation

class LoginManagerViewModel: ObservableObject {
    
    @Published var state: LoginStateModel = LoginStateModel()
    
    @Published var registerFormShowing: Bool = false
    
    @Published var loginError: LoginErrorType?
    
    //@Published var login_errors:
    
    func login(password: String) -> Bool {
        return false
    }
    
}
