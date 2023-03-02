//
//  CategoryModels.swift
//  GamePredictor
//
//  Created by Justin on 1/5/23.
//

import Foundation

final class Category {
    let name: String
    let isMember: ((String, Game)) -> Bool
    let didMatch: ((String, Team.PreviousGame)) -> Bool
    let designatedTeam: ((String, Game)) -> String?
    let weight: Double
    
    init(name: String,
         isMember: @escaping ((String, Game)) -> Bool,
         didMatch: @escaping ((String, Team.PreviousGame)) -> Bool,
         designatedTeam: @escaping ((String, Game)) -> String?,
         weight: Double) {
        self.name = name
        self.isMember = isMember
        self.didMatch = didMatch
        self.designatedTeam = designatedTeam
        self.weight = weight
    }
    
    var sampleSize: Int {
        bettingMatchups.filter(isMember).count
    }
    
    var _rating: Int?
    
    var rating: Int {
        if let savedRating = codableCategories.first(where: { $0.name == name })?.rating {
            return savedRating
        } else if let cachedRating = _rating {
            return cachedRating
        } else {
            let samples = bettingMatchups.filter(isMember)
            let matches = samples.filter(didMatch).count
            
            guard samples.count > 0 else { return 0 }
            
            _rating = Int((Double(matches) / Double(samples.count)) * 100)
            return _rating!
        }
    }
}

struct CodableCategory: Codable {
    let name: String
    let rating: Int
    let weight: Double
}

enum Comparison {
    case record(Record)
    case stat(Stat)
    case opponentStat(Stat)
    case experience(Experience)
    
    enum Record: String, CaseIterable {
        case overall = "Record"
        case conference = "Conference Record"
        case nationalRanking = "National Ranking"
        case last5Games = "Record In Last 5 Games"
        case road = "Road Record"
        case home = "Home Record"
    }
    
    enum Stat: String, CaseIterable {
        case points                = "Points Scored"
        case fieldGoals            = "Field Goal Percentage"
        case threePointFieldGoals  = "Three Point Field Goal Percentage"
        case freeThrows            = "Free Throw Percentage"
        case offensiveRebounds     = "Offensive Rebounds"
        case defensiveRebounds     = "Defensive Rebounds"
        case totalRebounds         = "Total Rebounds"
        case assists               = "Assists"
        case steals                = "Steals"
        case blocks                = "Blocks"
        case turnovers             = "Turnovers"
        case personalFouls         = "Personal Fouls"
        case assistToTurnoverRatio = "Assist-to-Turnover Ratio"
        case offensiveEfficiency   = "Offensive Efficiency"
        case defensiveEfficiency   = "Defensive Efficiency"
        case averageHeights        = "Average Heights"
        case adjustedTempo         = "Adjusted Tempo"
    }
    
    enum Experience: String, CaseIterable {
        case combined = "Combined Player Experience"
        case top5Combined = "Combined Experience In Top 5 Players"
    }
    
    static let all: [Comparison] = Record.allCases.compactMap { !SPORT_MODE.isCollege && [.conference, .nationalRanking].contains($0) ? nil : Comparison.record($0) }
        + Stat.allCases.map { Comparison.stat($0) }
        + Stat.allCases.map { Comparison.opponentStat($0) }
        + Experience.allCases.map { Comparison.experience($0) }
    
    var name: String {
        switch self {
        case .record(let record):
            return record.rawValue
        case .stat(let stat):
            return stat.rawValue
        case .opponentStat(let stat):
            return stat.rawValue
        case .experience(let experience):
            return experience.rawValue
        }
    }
    
    var isOpponentStat: Bool {
        if case .opponentStat = self {
            return true
        } else {
            return false
        }
    }
    
    var greaterPrefix: String {
        switch self {
        case .record:
            return "Better"
        case .stat(let stat), .opponentStat(let stat):
            switch stat {
            case .points, .offensiveRebounds, .defensiveRebounds, .totalRebounds, .assists, .steals, .blocks, .turnovers, .personalFouls, .averageHeights, .adjustedTempo:
                return "More"
            case .fieldGoals, .freeThrows, .threePointFieldGoals, .assistToTurnoverRatio, .offensiveEfficiency, .defensiveEfficiency:
                return "Better"
            }
        case .experience:
            return "More"
        }
    }
    
    var lesserPrefix: String {
        switch self {
        case .record:
            return "Worse"
        case .stat(let stat), .opponentStat(let stat):
            switch stat {
            case .points, .offensiveRebounds, .defensiveRebounds, .totalRebounds, .assists, .steals, .blocks, .turnovers, .personalFouls, .averageHeights, .adjustedTempo:
                return "Less"
            case .fieldGoals, .freeThrows, .threePointFieldGoals, .assistToTurnoverRatio, .offensiveEfficiency, .defensiveEfficiency:
                return "Worse"
            }
        case .experience:
            return "Less"
        }
    }
}

final class StatCache {
    var teamCache = [TimeInterval: StatList]()
    var opponentCache = [TimeInterval: StatList]()
    var top5PlayersCombinedYearsOfExperience = [TimeInterval: Int]()
    var teamMinutesPlayed = [TimeInterval: Int]()
}

var statCache = [String: StatCache]()
