//
//  FriendSelectorModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/25/22.
//

import Foundation
import SwiftUI

struct FriendSelectorModel {
    
    var state: FriendSelectorState = .listFriends
    
    var friends: [BasicUser] = [BasicUser]()
    
    var recievedRequests: [BasicUser] = [BasicUser]()
    var pendingRequests: [BasicUser] = [BasicUser]()
    
}
