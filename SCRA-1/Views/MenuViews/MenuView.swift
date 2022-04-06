//
//  MenuView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/23/22.
//

import SwiftUI

struct MenuView: View {
    
    @EnvironmentObject var view_model: FriendSelectorViewModel
    
    @Binding var menu_state: MenuViewSelector
    @Binding var gameID: String
    @Binding var loggedIn: Bool
    
    @State var expandGame: Bool = false
    @State var expandFriend: Bool = false
    
    var body: some View {
        
        ZStack {
            Color(.gray)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                MenuTopNav(menu_view_manager: self.$menu_state, loggedIn: self.$loggedIn)

                GameSelectorDropDown(friends: self.$view_model.friends, expand: self.$expandGame, gameID: self.$gameID, menu_state: self.$menu_state)
                    .animation(.spring(), value: self.expandFriend)
                
                FriendSelectorDropDown(expand: self.$expandFriend)
                    .animation(.spring(), value: self.expandGame)
                    .environmentObject(self.view_model)
                
                Spacer()
                
            }
            .padding(10)
            
        }
    }
}


struct GameSelectorDropDown: View {
    
    @Binding var friends: [BasicUser]
    @Binding var expand: Bool
    @Binding var gameID: String
    @Binding var menu_state: MenuViewSelector
    
    @StateObject var view_model: GameSelectorViewModel = GameSelectorViewModel()
    
    var body: some View {
        
        VStack {
            
            HStack {
                
                Button(action: {
                    self.view_model.state = .new_game
                    self.expand = true
                }, label: {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                        .foregroundColor(.white)
                    
                })
                
                Spacer()
                
                Button(action: {
                    self.expand.toggle()
                    self.view_model.state = .list
                }, label: {
                    
                    HStack {
                        Group {
                            Text("Games")
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                            
                            Image(systemName: self.expand ? "chevron.down.circle" : "chevron.up.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25)
                                .foregroundColor(.white)
                        }
                    }
                })

                Spacer()
                
                Button(action: {
                    self.view_model.refresh()
                }, label: {
                    Image(systemName: "arrow.clockwise.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                        .foregroundColor(.white)
                })
            }
            
            if (self.expand) {
                GameSelectorManager(view_model: self.view_model, friends: self.$friends, gameID: self.$gameID, menu_state: self.$menu_state)
                    .padding(6)
            }
        }
        .padding(6)
        //.frame(width: geo.size.width - 20)
        .background(LinearGradient(gradient: .init(colors: [.green, .yellow]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(20)
        .animation(.spring(), value: self.expand)
    }
}

struct FriendSelectorDropDown: View {
    
    @EnvironmentObject var view_model: FriendSelectorViewModel
    @Binding var expand: Bool
    
    var body: some View {
        
        VStack {
            HStack {
                
                Button(action: {
                    self.view_model.state = .requestFriend
                    self.expand = true
                }, label: {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                        .foregroundColor(.white)
                    
                })
                
                Spacer()
        // - - - - - Drop Down Button - - - - - //
                Button(action: {
                    self.expand.toggle()
                    self.view_model.state = .listFriends
                }, label: {
                    
                    HStack {
                        Text("Friends")
                            .fontWeight(.heavy)
                            .foregroundColor(.white)
                        
                        Image(systemName: self.expand ? "chevron.down.circle" : "chevron.up.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25)
                            .foregroundColor(.white)
                    }
                })
                
                Spacer()
        
        // - - - - - Refresh Button - - - - - //
                Button(action: {
                    self.view_model.refreshAll()
                }, label: {
                    Image(systemName: "arrow.clockwise.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 25)
                        .foregroundColor(.white)
                    
                })
            }
            
            if (self.expand) {
                FriendSelectorManager()
                    .environmentObject(self.view_model)
                    .padding(6)
            }
            
        }
        .padding(6)
        //.frame(width: geo.size.width - 20)
        .background(LinearGradient(gradient: .init(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(20)
        .animation(.spring(), value: self.expand)
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView(menu_state: Binding.constant(.menu), gameID: Binding.constant(""), loggedIn: Binding.constant(true))
            .environmentObject(FriendSelectorViewModel())
    }
}

