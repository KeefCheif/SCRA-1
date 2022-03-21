//
//  LoginManagerModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/10/22.
//

import Foundation

struct LoginStateModel {
    
    var login_state: LoginState = LoginState.home
    var loggedIn: Bool = checkLogin()
    //var login_error:
    
}

enum LoginState {
    case home
    case login
    case register
}
