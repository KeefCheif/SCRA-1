//
//  Globals.swift
//  SCRA-1
//
//  Created by peter allgeier on 3/31/22.
//

import Foundation

struct Globals {
    
    static let Default_Board: [String] = [
        "tw", "blank", "blank", "dl", "blank", "blank", "blank", "tw", "blank", "blank", "blank", "dl", "blank", "blank", "tw",
        "blank", "dw", "blank", "blank", "blank", "tl", "blank", "blank", "blank", "tl", "blank", "blank", "blank", "dw", "blank",
        "blank", "blank", "dw", "blank", "blank", "blank", "dl", "blank", "dl", "blank", "blank", "blank", "dw", "blank", "blank",
        "dl", "blank", "blank", "dw", "blank", "blank", "blank", "dl", "blank", "blank", "blank", "dw", "blank", "blank", "dl",
        "blank", "blank", "blank", "blank", "dw", "blank", "blank", "blank", "blank", "blank", "dw", "blank", "blank", "blank", "blank",
        "blank", "tl", "blank", "blank", "blank", "tl", "blank", "blank", "blank", "tl", "blank", "blank", "blank", "tl", "blank",
        "blank", "blank", "dl", "blank", "blank", "blank", "dl", "blank", "dl", "blank", "blank", "blank", "dl", "blank", "blank",
        "tw", "blank", "blank", "dl", "blank", "blank", "blank", "center", "blank", "blank", "blank", "dl", "blank", "blank", "tw",
        "blank", "blank", "dl", "blank", "blank", "blank", "dl", "blank", "dl", "blank", "blank", "blank", "dl", "blank", "blank",
        "blank", "tl", "blank", "blank", "blank", "tl", "blank", "blank", "blank", "tl", "blank", "blank", "blank", "tl", "blank",
        "blank", "blank", "blank", "blank", "dw", "blank", "blank", "blank", "blank", "blank", "dw", "blank", "blank", "blank", "blank",
        "dl", "blank", "blank", "dw", "blank", "blank", "blank", "dl", "blank", "blank", "blank", "dw", "blank", "blank", "dl",
        "blank", "blank", "dw", "blank", "blank", "blank", "dl", "blank", "dl", "blank", "blank", "blank", "dw", "blank", "blank",
        "blank", "dw", "blank", "blank", "blank", "tl", "blank", "blank", "blank", "tl", "blank", "blank", "blank", "dw", "blank",
        "tw", "blank", "blank", "dl", "blank", "blank", "blank", "tw", "blank", "blank", "blank", "dl", "blank", "blank", "tw"
    ]
    
    static let Letter_Amounts: [Int] = [9, 2, 2, 4, 12, 2, 3, 2, 9, 1, 1, 4, 2, 6, 8, 2, 1, 6, 4, 6, 4, 2, 2, 1, 2, 1, 2]
    
    static let Letter_Values = ["a":1, "b":3, "c":3, "d":2, "e":1, "f":4, "g":2, "h":4, "i":1, "j":8, "k":5, "l":1, "m":3, "n":1, "o":1, "p":3, "q":10, "r":1, "s":1, "t":1, "u":1, "v":4, "w":4, "x":8, "y":4, "z":10, "wild":0]
    
    static let Letter_Types: [String] = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "wild"]
    
}
