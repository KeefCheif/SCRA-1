//
//  ListFriendsModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/26/22.
//

import Foundation

struct BasicUser: Hashable {
    
    var displayUsename: String
    var username: String
    var userID: String?
    //var profilePicture: UIImage
    
}

struct Requests {
    
    var friendReq: [String] = [String]()
    var pendingReq: [String] = [String]()
    
}

enum FriendSelectorState {
    
    case listFriends        // Also the menu
    case requestFriend
    case displayResult
    case invites
}
