//
//  ListFriendsView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/26/22.
//

import SwiftUI

struct ListFriendsView: View {
    
    @EnvironmentObject var view_model: FriendSelectorViewModel
    @Binding var view_state: FriendSelectorState
    
    var body: some View {
        
        if (self.view_model.isLoading) {
            GenericLoadingView()
        } else {
            
            ScrollView(.horizontal) {
                HStack {
                    
                    Spacer()
                    
                    if self.view_model.friendReq != nil || self.view_model.pendingReq != nil {
                        
        // - - - - - Requests Notification/Button - - - - - //
                        Button(action: {
                            self.view_state = .invites
                        }, label: {
                            VStack {
                                Image(systemName: "exclamationmark.circle")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40)
                                    .foregroundColor(.yellow)
                                
                                Text("Requests")
                                    .fontWeight(.heavy)
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        })
                    }
                    
        // - - - - - List Friend Section - - - - - //
                    ForEach(self.view_model.friends, id: \.self) { friend in
                        
                        Button(action: {
                            // Take user to the account they clicked on's profile
                        }, label: {
                            VStack {
                                Image(systemName: "person.circle")
                                    .GameSelectorLogo()
                                Text(friend.displayUsename)
                                    .GameSelectorSubText()
                            }
                        })
                        
                    }
                    Spacer()
                }
            }
        }
    }
    
}
