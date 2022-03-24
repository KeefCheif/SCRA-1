//
//  MenuViewModel.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/23/22.
//

import Foundation

class MenuManagerViewModel: ObservableObject {
    
    @Published var isLoading: Bool = true
    
    @Published var menu_model: MenuModel = MenuModel()
    
}
