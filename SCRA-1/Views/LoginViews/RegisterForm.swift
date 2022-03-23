//
//  RegisterForm.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/21/22.
//

import SwiftUI
import FirebaseAuth

struct RegisterForm: View {
    
    @Binding var registrationFormShowing: Bool
    
    @State var registerError: LoginErrorType?
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirm_password: String = ""
    
    var body: some View {
        
        GeometryReader { geo in
            
            VStack {
                
                Spacer()
                
                TextField("Email ", text: self.$email)
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .padding(6)
                
                SecureField("Password", text: self.$password)
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .padding(6)
                
                SecureField("Confirm Password", text: self.$confirm_password)
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .padding(6)
                
                Button(action: {
                    self.register()
                }, label: {
                    Text("Register")
                        .bold()
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Rectangle().cornerRadius(8).foregroundColor(.green).frame(width: geo.size.width/5))
                })
                    .padding(6)
                
                Button(action: {
                    self.registrationFormShowing = false
                }, label: {
                    Text("Cancel")
                        .bold()
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Rectangle().cornerRadius(8).foregroundColor(.red).frame(width: geo.size.width/5))
                })
                    .padding(6)
                
                Spacer()
                Spacer()
                
            }
            .alert(item: self.$registerError) { (error) in
                Alert(title: Text("Register Failed"), message: Text(error.error.localizedDescription), dismissButton: .default(Text("Okay")) {
                    self.registerError = nil
                })
            }
            
        }
    }
    
    private func register() {
        guard self.password == self.confirm_password else {
            self.password = ""
            self.confirm_password = ""
            self.registerError = LoginErrorType(error: .passwordMismatch)
            return
        }
        
        Auth.auth().createUser(withEmail: self.email, password: self.password) { (_, error) in
            DispatchQueue.main.async {
                if let error = error {
                    
                    self.registerError = LoginErrorType(error: .propogatedError(error.localizedDescription))
                    self.password = ""
                    self.confirm_password = ""
                    
                } else {
                    self.registrationFormShowing = false
                }
            }
        }
    }
}

struct RegisterForm_Previews: PreviewProvider {
    static var previews: some View {
        RegisterForm(registrationFormShowing: Binding.constant(true))
    }
}
