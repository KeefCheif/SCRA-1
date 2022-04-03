//
//  RegisterForm.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/21/22.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct RegisterForm: View {
    
    @Binding var registrationFormShowing: Bool
    
    @State var registerError: LoginErrorType?
    
    @State var username: String = ""
    @State private var displayUsername: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirm_password: String = ""
    
    @State private var checkingRegistration: Bool = false   // Checking the registration uses the DB so the UI must wait for this to finish
    
    var body: some View {
        
        GeometryReader { geo in
            
            ZStack {
                
                if (self.checkingRegistration) {
                    GenericLoadingViewBackground(message: "Validating Registration...", color: .gray)
                }
                
                VStack {
                    
                    Spacer()
                    
                    TextField("Username", text: self.$displayUsername)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .padding(6)
                    
                    TextField("Email", text: self.$email)
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
                        if (!checkingRegistration) {
                            self.username = self.displayUsername.lowercased()
                            self.register()
                        }
                    }, label: {
                        Text("Register")
                            .bold()
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Rectangle().cornerRadius(8).foregroundColor(.green).frame(width: geo.size.width/5))
                    })
                        .padding(6)
                    
                    Button(action: {
                        if (!checkingRegistration) {
                            self.registrationFormShowing = false
                        }
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
                .alert("Registration Failed", isPresented: .constant(self.registerError != nil), actions: {
                    Button("Okay", role: .cancel, action: {
                        self.registerError = nil
                    })
                }, message: {
                    if let registerError = self.registerError {
                        Text(registerError.error.localizedDescription)
                    }
                })
            }
            
        }
    }
    
    private func usernameValid() -> Bool {
        // Only letters, numbers, and '_' are allowed in the username
        
        let characters: [Character] = Array(username)
        
        for ch in characters {
            
            if let asci = ch.asciiValue {
                
                if asci < 48 || (asci > 57 && asci < 65) || (asci > 90 && asci < 97) || asci > 122 {
                    if asci != 95 {
                        return false
                    }
                }
                
            } else {
                return false
            }
        }
        return true
    }
    

    private func usernameTaken(completion: @escaping (Bool) -> Void) {
        // * Completes true if the username is available
        
        if self.username.isEmpty {
            completion(false)
        } else {
            
            DispatchQueue.main.async {
                let db = Firestore.firestore()
                let userDocs = db.collection("users")
                
                let _ = userDocs.whereField("username", isEqualTo: self.username)
                    .getDocuments { (querySnapshot, error) in
                        if let _ = error {
                            // Maybe don't send this error to the user
                        } else if let querySnapshot = querySnapshot {
                            
                            if querySnapshot.isEmpty {
                                completion(true)
                            } else {
                                completion(false)
                            }
                            
                        }
                    }
            }
        }
    }
    
    private func validateRegistration(completion: @escaping (Bool) -> Void) {
        
        self.usernameTaken { result in
            
            if self.username.count > 20 || self.username.count < 2 {
                // Check the length of the username
                self.registerError = self.username.count > 20 ? LoginErrorType(error: .usernameTooLong) : LoginErrorType(error: .usernameTooShort)
                completion(false)
                
            } else if !self.usernameValid() {
                // Make sure the username is valid
                self.registerError = LoginErrorType(error: .usernameInvalid)
                completion(false)
                
            } else if !result {
                // Make sure the username is not taken
                registerError = LoginErrorType(error: .usernameTaken)
                completion(false)
                
            } else if self.password != self.confirm_password {
                self.password = ""
                self.confirm_password = ""
                self.registerError = LoginErrorType(error: .passwordMismatch)
                completion(false)
                
            } else {
                completion(true)
            }
            
        }
    }
    
    private func register() {
        
        self.checkingRegistration = true
        
        self.validateRegistration { result in
            
            self.checkingRegistration = false
            
            if result {
                Auth.auth().createUser(withEmail: self.email, password: self.password) { (_, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            
                            self.registerError = LoginErrorType(error: .propogatedError(error.localizedDescription))
                            self.password = ""
                            self.confirm_password = ""
                            
                        } else {
                            print("- - - - - - - - - - - \(Auth.auth().currentUser!.uid)")
                            
                            // Add their info to the DB
                            let db = Firestore.firestore()
                            let userDoc = db.collection("users").document(Auth.auth().currentUser!.uid)
                            
                            let usernameData: [String: String] = [
                                "username": self.username,
                                "displayUsername": self.displayUsername
                            ]
                            
                            userDoc.setData(usernameData, merge: true)
                            
                            // tracks the current user's friends and games
                            userDoc.setData(["friends":[]], merge: true)
                            userDoc.setData(["games":[]], merge: true)
                            
                            // Requests sent by the current user to other users
                            userDoc.setData(["pendingGameReq":[]], merge: true)
                            userDoc.setData(["pendingFriendReq":[]], merge: true)
                            
                            // Requests sent by other users to the current user
                            userDoc.setData(["gameReq":[]], merge: true)
                            userDoc.setData(["friendReq":[]], merge: true)
                            
                            self.registrationFormShowing = false
                        }
                    }
                }
            }
        }
    }
    
}
