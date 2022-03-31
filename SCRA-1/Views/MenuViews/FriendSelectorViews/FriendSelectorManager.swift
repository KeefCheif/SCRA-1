//
//  FriendSelectorManager.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/25/22.
//

import SwiftUI

struct FriendSelectorManager: View {
    
    @EnvironmentObject var view_model: FriendSelectorViewModel
    @State var displayUser: BasicUser?
    //@State var friendSelectorError: FriendSelectorErrorType?
    
    var body: some View {
        
        switch self.view_model.state {
        case .listFriends:      // List out their friends (also add friend button)
            ListFriendsView(view_state: self.$view_model.state)
                .environmentObject(self.view_model)
        case .requestFriend:    // Send someone a friend request
            InviteFriendView(displayUser: self.$displayUser, view_state: self.$view_model.state)
                .environmentObject(self.view_model)
        case .displayResult:    // Display the result after trying to send a friend request
            FriendSelectorDisplayResult(displayUser: self.$displayUser, view_state: self.$view_model.state)
                .environmentObject(self.view_model)
        case .invites:          // List out the requests that they have recieved
            FriendSelectorInvites(view_state: self.$view_model.state, friendReq: self.$view_model.friendReq, pendingReq: self.$view_model.pendingReq)
                .environmentObject(self.view_model)
        }
        
    }
}
