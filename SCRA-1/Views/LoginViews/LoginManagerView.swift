//
//  LoginManagerView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/10/22.
//

import SwiftUI
import FirebaseAuth

struct LoginManagerView: View {
    
    @StateObject var login_manager: LoginManagerViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        
        if (login_manager.state.loggedIn) {
            
            MenuManagerView(loggedIn: self.$login_manager.state.loggedIn, menu_view_model: MenuManagerViewModel())
            
        } else {
            
            GeometryReader { geo in
                
                VStack {
                    
                    Spacer()
                    
                    // Login Section
                    TextField("Email", text: self.$email)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .padding(6)
                    
                    SecureField("Password", text: self.$password)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .padding(6)
                    
                    Button(action: {
                        self.signIn()
                    }, label: {
                        Text("Login")
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Rectangle().cornerRadius(8).foregroundColor(.green).frame(width: geo.size.width/5))
                    })
                        .padding(6)
                    
                    // Register Section
                    Button(action: {
                        self.login_manager.registerFormShowing = true
                    }, label: {
                        Text("Register")
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Rectangle().cornerRadius(8).frame(width: geo.size.width/5))
                    })
                        .padding(6)
                    
                    Spacer()
                    
                    // Register Button
                    
                }
                .sheet(isPresented: self.$login_manager.registerFormShowing, onDismiss: nil) {
                    RegisterForm(registrationFormShowing: self.$login_manager.registerFormShowing)
                }
                .alert(item: self.$login_manager.loginError) { (error) in
                    Alert(title: Text("Login Failed"), message: Text(error.error.localizedDescription), dismissButton: .default(Text("Okay")) {
                        self.login_manager.loginError = nil
                    })
                }
                .onAppear {
                    if Auth.auth().currentUser != nil {
                        self.login_manager.state.loggedIn = true
                    }
                }
                
            }
            
        }
        
    }
    
    private func signIn() {
        Auth.auth().signIn(withEmail: self.email, password: self.password) { (_, error) in
            DispatchQueue.main.async {
                if let error = error {
                    // Login failed
                    self.login_manager.loginError = LoginErrorType(error: .propogatedError(error.localizedDescription))
                    self.password = ""
                
                } else {
                    self.email = ""
                    self.password = ""
                    self.login_manager.state.loggedIn = true
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
