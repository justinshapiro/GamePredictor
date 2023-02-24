//
//  Models.swift
//  GamePredictor
//
//  Created by Justin on 12/15/22.
//

import Foundation

struct Team: Codable {
    let teamID: String
    let conference: String
    var conferenceRanking: Int
    var nationalRanking: Int?
    var roster: [Player]
    var games: Games
    
    func getAdjustedTempo(onDate date: Date) -> Double {
        let seasonsStats = getStats(onDate: date, statType: .team)
        let numberOfPossesions = seasonsStats.fieldGoals.attempted - seasonsStats.rebounds.offensive + seasonsStats.turnovers + (0.475 * seasonsStats.freeThrows.attempted)
        
        let minutesPlayed: Int
        if let cachedValue = statCache[teamID]?.teamMinutesPlayed[date.timeIntervalSinceReferenceDate] {
            minutesPlayed = cachedValue
        } else {
            let minutes = roster.reduce(0) { $0 + getTotalMinutesPlayed(for: $1, onDate: date) }
            statCache[teamID]?.teamMinutesPlayed[date.timeIntervalSinceReferenceDate] = minutes
            minutesPlayed = minutes
        }
        
        guard numberOfPossesions > 0 else { return 0 }
        
        return Double(numberOfPossesions) / Double(minutesPlayed)
    }
    
    var isInBIGConference: Bool {
        ["Big 12", "Big East", "Big West", "Big South", "Big Sky", "Big Ten", "Big 10"].contains(conference)
    }
    
    var averageHeight: Double {
        roster.reduce(0.0) { $0 + (($1.height?.inInches).flatMap { Double($0) } ?? 0.0) }
    }
    
    func getNationalRanking(onDate date: Date) -> Int? {
        let currentRankingWeek = nationalRankings.sorted { $0.week > $1.week }.first!.week
        let rankingWeekOfGame = currentRankingWeek - (Calendar.current.dateComponents([.weekOfYear], from: date, to: .now).weekOfYear ?? 0)
        
        return nationalRankings.first { $0.week == rankingWeekOfGame }!.rankings.first { $0.teamID == teamID }?.ranking
    }
    
    func getOffsensiveEfficiency(onDate date: Date) -> Int {
        let seasonsStats = getStats(onDate: date, statType: .team)
        let numberOfPossesions = seasonsStats.fieldGoals.attempted - seasonsStats.rebounds.offensive + seasonsStats.turnovers + (0.475 * seasonsStats.freeThrows.attempted)
        
        guard numberOfPossesions > 0 else { return 0 }
        
        return Int((Double(seasonsStats.pointsScored) / Double(numberOfPossesions)) * 100)
    }
    
    func getDefensiveEfficiency(onDate date: Date) -> Int {
        let seasonsStats = getStats(onDate: date, statType: .team)
        let numberOfPossesions = seasonsStats.fieldGoals.attempted - seasonsStats.rebounds.offensive + seasonsStats.turnovers + (0.475 * seasonsStats.freeThrows.attempted)
        let opponentPointsAllowed = getStats(onDate: date, statType: .opponent).pointsScored
        
        guard numberOfPossesions > 0 else { return 0 }
        
        return Int((Double(opponentPointsAllowed) / Double(numberOfPossesions)) * 100)
    }
    
    func getPossesionsPerGame(onDate date: Date) -> Double {
        let seasonsStats = getStats(onDate: date, statType: .team)
        let numberOfPossesions = seasonsStats.fieldGoals.attempted - seasonsStats.rebounds.offensive + seasonsStats.turnovers + (0.475 * seasonsStats.freeThrows.attempted)
        
        return Double(numberOfPossesions) / Double(games.previous.count)
    }
    
    var combinedYearsOfExperience: Int {
        roster
            .lazy
            .map { $0.class.yearsOfExperience }
            .reduce(0, +)
    }
    
    private func getTotalMinutesPlayed(for player: Player, onDate date: Date) -> Int {
        guard let currentSeason = player.seasons.first(where: { $0.seasonYear == CURRENT_SEASON_YEAR }) else {
            return 0
        }
        
        return currentSeason.gameLogs.lazy.filter { $0.date <= date }.map { $0.minutesPlayed }.reduce(0, +)
    }
    
    func getTop5PlayersCombinedYearsOfExperience(onDate date: Date) -> Int {
        if let cachedValue = statCache[teamID]?.top5PlayersCombinedYearsOfExperience[date.timeIntervalSinceReferenceDate] {
            return cachedValue
        } else {
            let experience = roster
                .sorted { getTotalMinutesPlayed(for: $0, onDate: date) > getTotalMinutesPlayed(for: $1, onDate: date) }
                .prefix(5)
                .map { $0.class.yearsOfExperience }
                .reduce(0, +)
            
            statCache[teamID]?.top5PlayersCombinedYearsOfExperience[date.timeIntervalSinceReferenceDate] = experience
            return experience
        }
        
    }
    
    struct Record {
        var wins: Int
        var losses: Int
        var conferenceWins: Int
        var conferenceLosses: Int
        
        var netWins: Int {
            wins - losses
        }
        
        var netConferenceWins: Int {
            conferenceWins - conferenceLosses
        }
        
        var overallPercentage: Double {
            if wins == 0 || losses == 0 {
                return 0
            } else {
                return Double(wins) / (Double(wins) + Double(losses))
            }
        }
        
        var conferencePercentage: Double {
            if conferenceWins == 0 || conferenceLosses == 0 {
                return 0
            } else {
                return Double(conferenceWins) / (Double(conferenceWins) + Double(conferenceLosses))
            }
        }
    }
    
    func getRecord(beforeDate date: Date, isHome: Bool? = nil, isNeutralVenue: Bool? = nil, last5Games: Bool = false) -> Record {
        var record = Record(wins: 0, losses: 0, conferenceWins: 0, conferenceLosses: 0)
        
        games.previous
            .sorted { $0.date > $1.date }
            .filter { game in
                guard game.date < date else { return false }
                
                switch (isHome, isNeutralVenue) {
                case (.some(let isHome), .some(let isNeutralVenue)):
                    switch (isHome, isNeutralVenue) {
                    case (true, true):   return game.venue.isHome && game.venue.isNeutral
                    case (true, false):  return game.venue.isHome && !game.venue.isNeutral
                    case (false, true):  return !game.venue.isHome && game.venue.isNeutral
                    case (false, false): return !game.venue.isHome && !game.venue.isNeutral
                    }
                case (.some(let isHome), .none):
                    return isHome ? game.venue.isHome : !game.venue.isHome
                case (.none, .some(let isNeutralVenue)):
                    return isNeutralVenue ? game.venue.isNeutral : !game.venue.isNeutral
                case (.none, .none):
                    return true
                }
            }
            .prefix(last5Games ? 5 : games.previous.count)
            .forEach { game in
                if game.didWin {
                    record.wins += 1
                    
                    if game.isConferenceMatchup {
                        record.conferenceWins += 1
                    }
                } else {
                    record.losses += 1
                    
                    if game.isConferenceMatchup {
                        record.conferenceLosses += 1
                    }
                }
            }
        
        return record
    }
    
    enum StatType {
        case team
        case opponent
        case differential
    }
    
    func getStats(onDate date: Date, statType: StatType) -> StatList {
        switch statType {
        case .team:
            if let cachedValue = statCache[teamID]?.teamCache[date.timeIntervalSinceReferenceDate] {
                return cachedValue
            } else {
                let allGameLogs = roster
                    .lazy
                    .compactMap { $0.currentSeason }
                    .reduce([]) { $0 + $1.gameLogs }
                    .filter { $0.date < date }
                
                let statList = statList(from: allGameLogs)
                statCache[teamID]?.teamCache[date.timeIntervalSinceReferenceDate] = statList
                return statList
            }
        case .opponent:
            if let cachedValue = statCache[teamID]?.opponentCache[date.timeIntervalSinceReferenceDate] {
                return cachedValue
            } else {
                let opponentsPlayedOnDate = games.previous.reduce([String: [Date]]()) { previous, current in
                    if previous.keys.contains(current.opponentID) {
                        var newPrevious = previous
                        newPrevious[current.opponentID] = newPrevious[current.opponentID]! + [current.date]
                        return newPrevious
                    } else {
                        var newPrevious = previous
                        newPrevious[current.opponentID] = [current.date]
                        return newPrevious
                    }
                }
                
                let allGameLogs = opponentsPlayedOnDate.keys.reduce([Player.Season.GameLog]()) { previous, current in
                    guard let opponent = teams.first(where: { $0.teamID == current }) else { return previous }
                    
                    return previous + opponent.roster
                        .lazy
                        .compactMap { $0.currentSeason }
                        .reduce([]) { $0 + $1.gameLogs }
                        .filter { opponentsPlayedOnDate[current]!.contains($0.date) && $0.date < date }
                }
                
                let statList = statList(from: allGameLogs)
                statCache[teamID]?.opponentCache[date.timeIntervalSinceReferenceDate] = statList
                return statList
            }
        case .differential:
            let stats = statCache[teamID]?.teamCache[date.timeIntervalSinceReferenceDate] ?? getStats(onDate: date, statType: .team)
            let opponentStats = statCache[teamID]?.opponentCache[date.timeIntervalSinceReferenceDate] ?? getStats(onDate: date, statType: .opponent)
            
            return StatList(fieldGoals: .init(made: stats.fieldGoals.made - opponentStats.fieldGoals.made,
                                              attempted: stats.fieldGoals.attempted - opponentStats.fieldGoals.attempted,
                                              differentialPercentage: stats.fieldGoals.percentages - opponentStats.fieldGoals.percentages),
                            threePointFieldGoals: .init(made: stats.threePointFieldGoals.made - opponentStats.threePointFieldGoals.made,
                                                        attempted: stats.threePointFieldGoals.attempted - opponentStats.threePointFieldGoals.attempted,
                                                        differentialPercentage: stats.threePointFieldGoals.percentages - opponentStats.threePointFieldGoals.percentages),
                            freeThrows: .init(made: stats.freeThrows.made - opponentStats.freeThrows.made,
                                              attempted: stats.freeThrows.attempted - opponentStats.freeThrows.attempted,
                                              differentialPercentage: stats.freeThrows.percentages - opponentStats.freeThrows.percentages),
                            rebounds: .init(offensive: stats.rebounds.offensive - opponentStats.rebounds.offensive,
                                            defensive: stats.rebounds.defensive - opponentStats.rebounds.defensive),
                            assists: stats.assists - opponentStats.assists,
                            steals: stats.steals - opponentStats.steals,
                            blocks: stats.blocks - opponentStats.blocks,
                            personalFouls: stats.personalFouls - opponentStats.personalFouls,
                            turnovers: stats.turnovers - opponentStats.turnovers,
                            pointsScored: stats.pointsScored - opponentStats.pointsScored)
        }
    }
    
    private func statList(from allGameLogs: [Player.Season.GameLog]) -> StatList {
        let allGamesPlayed = Double(games.previous.count)
        
        let fieldGoalsAttempted = allGameLogs.reduce(0.0) { $0 + $1.stats.fieldGoals.attempted } / allGamesPlayed
        let fieldGoalsMade = allGameLogs.reduce(0.0) { $0 + $1.stats.fieldGoals.made } / allGamesPlayed
        
        let threePointFieldGoalsAttempted = allGameLogs.reduce(0.0) { $0 + $1.stats.threePointFieldGoals.attempted } / allGamesPlayed
        let threePointFieldGoalsMade = allGameLogs.reduce(0.0) { $0 + $1.stats.threePointFieldGoals.made } / allGamesPlayed
        
        let freeThrowsAttempted = allGameLogs.reduce(0.0) { $0 + $1.stats.freeThrows.attempted } / allGamesPlayed
        let freeThrowsMade = allGameLogs.reduce(0.0) { $0 + $1.stats.freeThrows.made } / allGamesPlayed
        
        let offensiveRebounds = allGameLogs.reduce(0.0) { $0 + $1.stats.rebounds.offensive } / allGamesPlayed
        let defensiveRebounds = allGameLogs.reduce(0.0) { $0 + $1.stats.rebounds.defensive } / allGamesPlayed
        
        return StatList(fieldGoals: .init(made: fieldGoalsMade, attempted: fieldGoalsAttempted),
                        threePointFieldGoals: .init(made: threePointFieldGoalsMade, attempted: threePointFieldGoalsAttempted),
                        freeThrows: .init(made: freeThrowsMade, attempted: freeThrowsAttempted),
                        rebounds: .init(offensive: offensiveRebounds, defensive: defensiveRebounds),
                        assists: allGameLogs.reduce(0.0) { $0 + $1.stats.assists } / allGamesPlayed,
                        steals: allGameLogs.reduce(0.0) { $0 + $1.stats.steals } / allGamesPlayed,
                        blocks: allGameLogs.reduce(0.0) { $0 + $1.stats.blocks } / allGamesPlayed,
                        personalFouls: allGameLogs.reduce(0.0) { $0 + $1.stats.personalFouls } / allGamesPlayed,
                        turnovers: allGameLogs.reduce(0.0) { $0 + $1.stats.turnovers } / allGamesPlayed,
                        pointsScored: allGameLogs.reduce(0.0) { $0 + $1.stats.pointsScored } / allGamesPlayed)
    }
    
    var seasonStats: StatList {
        let allGameLogs = roster
            .lazy
            .compactMap { $0.currentSeason }
            .reduce([]) { $0 + $1.gameLogs }
        
        return statList(from: allGameLogs)
    }
    
    var opponentStats: StatList {
        let opponentsPlayedOnDate = games.previous.reduce([String: [Date]]()) { previous, current in
            if previous.keys.contains(current.opponentID) {
                var newPrevious = previous
                newPrevious[current.opponentID] = newPrevious[current.opponentID]! + [current.date]
                return newPrevious
            } else {
                var newPrevious = previous
                newPrevious[current.opponentID] = [current.date]
                return newPrevious
            }
        }
        
        let allGameLogs = opponentsPlayedOnDate.keys.reduce([Player.Season.GameLog]()) { previous, current in
            guard let opponent = teams.first(where: { $0.teamID == current }) else { return previous }
            
            return previous + opponent.roster
                .lazy
                .compactMap { $0.currentSeason }
                .reduce([]) { $0 + $1.gameLogs }
                .filter { opponentsPlayedOnDate[current]!.contains($0.date) }
        }
        
        return statList(from: allGameLogs)
    }
    
    struct Games: Codable {
        var previous: [PreviousGame]
        var upcoming: [UpcomingGame]
    }
    
    enum Coverage: String, Codable {
        case sportsTV
        case standardTV
        case subscriptionRequired
        
        init?(channel: String) {
            if channel.contains("ESPN+") {
                self = .subscriptionRequired
            } else if channel.isEmpty {
                return nil
            } else {
                let standardChannels = ["ESPN", "ESPN2", "ESPNU", "ESPNN", "CBSSN", "ABC", "FOX", "NBC", "FS1", "FS2", "USA NET"]
                
                if standardChannels.first(where: { channel.contains($0) }) != nil {
                    self = .standardTV
                } else {
                    self = .sportsTV
                }
            }
        }
    }
    
    enum SeasonType: String, Codable {
        case regularSeason
        case postseason
    }
    
    struct PreviousGame: Codable, Game {
        let date: Date
        var opponentID: String
        let venue: Venue
        let didWin: Bool
        let score: GameScore
        let line: Double?
        let overUnder: Double?
        let coverage: Coverage?
        let attendance: Int
        let venueCapacity: Int?
        let referees: [String]
        let largestLead: Int?
        let isConferenceMatchup: Bool
        let seasonType: SeasonType
        
        var didCoverSpread: Bool {
            guard let line = line else { return false }
            
            let isFavored = line < 0
            let resultSpread = Double(abs(score.fullTime.teamPoints - score.fullTime.opponentPoints))
            
            if (didWin && isFavored) || (!didWin && !isFavored) {
                return abs(line) >= resultSpread
            } else if !didWin && isFavored {
                return false
            } else if didWin && !isFavored {
                return true
            } else {
                return false
            }
        }
        
        var venuePercentFull: Double {
            if let venueCapacity = venueCapacity {
                return Double(attendance) / Double(venueCapacity)
            } else {
                return 0
            }
        }
        
        struct GameScore: Codable {
            let firstHalf: Score
            let secondHalf: Score
            let overtimePeriods: [Score]?
            
            var fullTime: Score {
                .init(teamPoints: firstHalf.teamPoints
                        + secondHalf.teamPoints
                      + (overtimePeriods.flatMap { $0.reduce(0) { $0 + $1.teamPoints } } ?? 0),
                      opponentPoints: firstHalf.opponentPoints
                        + secondHalf.opponentPoints
                      + (overtimePeriods.flatMap { $0.reduce(0) { $0 + $1.opponentPoints } } ?? 0))
            }
            
            struct Score: Codable {
                let teamPoints: Int
                let opponentPoints: Int
            }
        }
    }
    
    struct UpcomingGame: Codable, Equatable, Game {
        let date: Date
        var opponentID: String
        let venue: Venue
        let coverage: Coverage?
        let venueCapacity: Int?
        let isConferenceMatchup: Bool
        let seasonType: SeasonType
    }
}

protocol Game: Codable {
    var date: Date { get }
    var opponentID: String { get set }
    var venue: Venue { get }
    var coverage: Team.Coverage? { get }
    var venueCapacity: Int? { get }
    var isConferenceMatchup: Bool { get }
    var seasonType: Team.SeasonType { get }
}

struct Player: Codable {
    let name: String
    let number: Int
    let position: Position
    let height: Height?
    let weight: Int?
    let `class`: Class
    let origin: Origin
    var seasons: [Season]
    
    var currentSeason: Season? {
        if let season = seasons.first(where: { $0.seasonYear == CURRENT_SEASON_YEAR }) {
            return season
        } else {
            return nil
        }
    }
    
    enum Position: String, Codable {
        case `guard` = "Guard"
        case pointGuard = "Point Guard"
        case forward = "Forward"
        case center = "Center"
        case powerForward = "Power Forward"
        case smallForward = "Small Forward"
        case shootingGuard = "Shooting Guard"
        case notAvailabile = "Not Available"
    }
    
    struct Height: Codable {
        let feet: Int
        let inches: Int
        
        init(feet: Int, inches: Int) {
            self.feet = feet
            self.inches = inches
        }
        
        var inInches: Int {
            (feet * 12) + inches
        }
    }
    
    enum Class: String, Codable {
        case freshman = "Freshman"
        case sophmore = "Sophomore"
        case junior = "Junior"
        case senior = "Senior"
        case unknown = "--"
        
        var yearsOfExperience: Int {
            switch self {
            case .unknown:  return 0
            case .freshman: return 1
            case .sophmore: return 2
            case .junior:   return 3
            case .senior:   return 4
            }
        }
    }
    
    enum Origin: String, Codable {
        case local
        case international
    }
    
    struct Season: Codable {
        let seasonYear: Int
        let teamID: String
        var gameLogs: [GameLog]
        
        struct GameLog: Codable {
            let date: Date
            let didStart: Bool
            let minutesPlayed: Int
            let stats: StatList
        }
    }
}

struct StatList: Codable {
    let fieldGoals: ShotStat // FG
    let threePointFieldGoals: ShotStat // 3P
    let freeThrows: ShotStat // FT
    let rebounds: Rebounds // REB
    let assists: Double // AST
    let steals: Double // STL
    let blocks: Double // BLK
    let personalFouls: Double // PF
    let turnovers: Double // TO
    let pointsScored: Double // PTS
    
    init(fieldGoals: ShotStat,
         threePointFieldGoals: ShotStat,
         freeThrows: ShotStat,
         rebounds: Rebounds,
         assists: Double,
         steals: Double,
         blocks: Double,
         personalFouls: Double,
         turnovers: Double,
         pointsScored: Double) {
        self.fieldGoals = fieldGoals
        self.threePointFieldGoals = threePointFieldGoals
        self.freeThrows = freeThrows
        self.rebounds = rebounds
        self.assists = assists
        self.steals = steals
        self.blocks = blocks
        self.personalFouls = personalFouls
        self.turnovers = turnovers
        self.pointsScored = pointsScored
    }
    
    init(statsArray: [String]) {
        let fieldGoalComponents = statsArray[5].components(separatedBy: "-")
        let fieldGoals = StatList.ShotStat(made: .init(fieldGoalComponents[0]) ?? 0,
                                           attempted: .init(fieldGoalComponents[1]) ?? 0)
        
        let threePointFieldGoalComponents = statsArray[7].components(separatedBy: "-")
        let threePointFieldGoals = StatList.ShotStat(made: .init(threePointFieldGoalComponents[0]) ?? 0,
                                                     attempted: .init(threePointFieldGoalComponents[1]) ?? 0)
        
        let freeThrowComponents = statsArray[9].components(separatedBy: "-")
        let freeThrows = StatList.ShotStat(made: .init(freeThrowComponents[0]) ?? 0,
                                           attempted: .init(freeThrowComponents[1]) ?? 0)
        
        self = StatList(fieldGoals: fieldGoals,
                        threePointFieldGoals: threePointFieldGoals,
                        freeThrows: freeThrows,
                        rebounds: .init(offensive: .init(statsArray[11])!, defensive: .init(statsArray[12])!),
                        assists: .init(statsArray[14])!,
                        steals: .init(statsArray[16])!,
                        blocks: .init(statsArray[15])!,
                        personalFouls: .init(statsArray[17])!,
                        turnovers: .init(statsArray[18])!,
                        pointsScored: .init(statsArray[19])!)
    }
    
    struct ShotStat: Codable {
        let made: Double
        let attempted: Double
        private let differentialPercentage: Double?
        
        init(made: Double, attempted: Double, differentialPercentage: Double? = nil) {
            self.made = made
            self.attempted = attempted
            self.differentialPercentage = differentialPercentage
        }
        
        var percentages: Double {
            if let differentialPercentage = differentialPercentage {
                return differentialPercentage
            } else {
                if made.isZero || attempted.isZero {
                    return 0
                } else {
                    return made / attempted
                }
            }
        }
    }
    
    struct Rebounds: Codable {
        let offensive: Double // OR
        let defensive: Double // DR
        
        var total: Double {
            offensive + defensive
        }
    }
    
    static var empty: StatList {
        .init(fieldGoals: .init(made: 0, attempted: 0),
              threePointFieldGoals: .init(made: 0, attempted: 0),
              freeThrows: .init(made: 0, attempted: 0),
              rebounds: .init(offensive: 0, defensive: 0),
              assists: 0,
              steals: 0,
              blocks: 0,
              personalFouls: 0,
              turnovers: 0,
              pointsScored: 0)
    }
}

enum Venue: String, Codable {
    case home
    case away
    case neutral
    
    // there was a bug initially when pulling the data where opponent.homeAway was interpreted as the opponent's venue when it was the current team's
    // so here 'away' actually means 'home' and vice versa
    
    var isHome: Bool {
        if case .away = self {
            return true
        } else {
            return false
        }
    }
    
    var isAway: Bool {
        if case .home = self {
            return true
        } else {
            return false
        }
    }
    
    var isNeutral: Bool {
        if case .neutral = self {
            return true
        } else {
            return false
        }
    }
}





struct CodableBettingMatchup: Codable {
    let teamName: String
    let game: Team.PreviousGame
}


