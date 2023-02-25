//
//  SportMode.swift
//  GamePredictor
//
//  Created by Justin on 2/25/23.
//

import Foundation

enum SportMode {
    case collegeBasketball(CollegeBasketballMode)
    
    enum CollegeBasketballMode {
        case mens
        case womens
    }
    
    var isWomanLeague: Bool {
        switch self {
        case .collegeBasketball(let collegeBasketballMode):
            switch collegeBasketballMode {
            case .mens:   return false
            case .womens: return true
            }
        }
    }
    
    var league: String {
        switch self {
        case .collegeBasketball(let collegeBasketballMode):
            switch collegeBasketballMode {
            case .mens:   return "NCAAM"
            case .womens: return "NCAAW"
            }
        }
    }
    
    var espnPathIndicator: String {
        switch self {
        case .collegeBasketball(let collegeBasketballMode):
            switch collegeBasketballMode {
            case .mens:   return "mens-college-basketball"
            case .womens: return "womens-college-basketball"
            }
        }
    }
}
