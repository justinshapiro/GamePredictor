//
//  SportMode.swift
//  GamePredictor
//
//  Created by Justin on 2/25/23.
//

import Foundation

enum SportMode {
    case collegeBasketball(CollegeBasketballMode)
    case nba
    
    enum CollegeBasketballMode {
        case mens
        case womens
    }
    
    init?(leagueString: String) {
        switch leagueString.lowercased() {
        case "nba":   self = .nba
        case "ncaam": self = .collegeBasketball(.mens)
        case "ncaaw": self = .collegeBasketball(.womens)
        default:      return nil
        }
    }
    
    var isCollege: Bool {
        switch self {
        case .collegeBasketball: return true
        case .nba: return false
        }
    }
    
    var isFourQuarterGame: Bool {
        switch self {
        case .collegeBasketball(let collegeBasketballMode):
            switch collegeBasketballMode {
            case .mens:   return false
            case .womens: return true
            }
        case .nba:
            return true
        }
    }
    
    var league: String {
        switch self {
        case .collegeBasketball(let collegeBasketballMode):
            switch collegeBasketballMode {
            case .mens:   return "NCAAM"
            case .womens: return "NCAAW"
            }
        case .nba: return "NBA"
        }
    }
    
    var espnPathIndicator: String {
        switch self {
        case .collegeBasketball(let collegeBasketballMode):
            switch collegeBasketballMode {
            case .mens:   return "mens-college-basketball"
            case .womens: return "womens-college-basketball"
            }
        case .nba: return "nba"
        }
    }
}
