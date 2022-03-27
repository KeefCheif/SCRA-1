//
//  MenuView.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/23/22.
//

import SwiftUI

struct MenuView: View {
    
    @Binding var menu_view_manager: MenuViewSelector
    @Binding var loggedIn: Bool
    
    @State var expandGame: Bool = false
    @State var expandFriend: Bool = false
    
    var body: some View {
        
        GeometryReader { geo in
            ZStack {
                
                VStack() {
                    
                    MenuTopNav(menu_view_manager: self.$menu_view_manager, loggedIn: self.$loggedIn)
                        .padding(.top, 50)
                    
                    Spacer()
                    
                    GameSelectorDropDown(geo: geo, expand: self.$expandGame)
                        .animation(.spring(), value: self.expandFriend)
                    FriendSelectorDropDown(geo: geo, expand: self.$expandFriend)
                        .animation(.spring(), value: self.expandGame)
                        .environmentObject(FriendSelectorViewModel())
                    
                    Spacer()
                    
                }
                
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
            .background(Color.gray)
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct GameSelectorDropDown: View {
    
    var geo:GeometryProxy
    @Binding var expand: Bool
    
    var body: some View {
        
        VStack {
            
            Button(action: {
                self.expand.toggle()
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
            
            if (self.expand) {
                GameSelectorManager(view_model: GameSelectorViewModel())
            }
        }
        .padding(6)
        .frame(width: geo.size.width - 20)
        .background(LinearGradient(gradient: .init(colors: [.green, .yellow]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(20)
        .animation(.spring(), value: self.expand)
        
    }
}

struct FriendSelectorDropDown: View {
    
    var geo: GeometryProxy
    
    @EnvironmentObject var view_model: FriendSelectorViewModel
    @Binding var expand: Bool
    
    var body: some View {
        
        VStack {
            HStack {
                
                Spacer()
        // - - - - - Drop Down Button - - - - - //
                Button(action: {
                    self.expand.toggle()
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
        .frame(width: geo.size.width - 20)
        .background(LinearGradient(gradient: .init(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(20)
        .animation(.spring(), value: self.expand)
        
    }
}

