//
//  CategoryHelperFunctions.swift
//  GamePredictor
//
//  Created by Justin on 1/5/23.
//

import Foundation
import Algorithms

// MARK: - Category Groups

typealias GameFilter = ((String, Game)) -> Bool
typealias PreviousGameFilter = ((String, Team.PreviousGame)) -> Bool
typealias CategoryProducer = (String, ((String, Game)) -> Bool)
typealias NameFilter = ((String, Game)) -> String?

let bothBothString = "(Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)"
let bothNonNeutralString = "(Both Conference And Non-Conference Games, Non-Neutral Venues)"
let conferenceNonNeturalString = "(Conference Games, Non-Neutral Venues)"
let nonConferenceBothString = "(Non-Conference Games, Both Neutral And Non-Neutral Venues)"
let nonConferenceNeutralString = "(Non-Conference Games, Neutral Venues)"
let nonConferenceNonNeutralString = "(Non-Conference Games, Non-Neutral Venues)"

let categoryClassStrings = [
    bothBothString,
    bothNonNeutralString,
    conferenceNonNeturalString,
    nonConferenceBothString,
    nonConferenceNeutralString,
    nonConferenceNonNeutralString
]

let generalCategoryProducers: [CategoryProducer] = [
    (bothBothString, { _ in true }),
    (bothNonNeutralString, { !$0.1.venue.isNeutral }),
    (conferenceNonNeturalString, { $0.1.isConferenceMatchup && !$0.1.venue.isNeutral }),
    (nonConferenceBothString, { !$0.1.isConferenceMatchup }),
    (nonConferenceNeutralString, { !$0.1.isConferenceMatchup && $0.1.venue.isNeutral }),
    (nonConferenceNonNeutralString, { !$0.1.isConferenceMatchup && !$0.1.venue.isNeutral })
]

let homeAwayCategoryProducers: [CategoryProducer] = [
    (bothNonNeutralString, { !$0.1.venue.isNeutral }),
    (conferenceNonNeturalString, { $0.1.isConferenceMatchup && !$0.1.venue.isNeutral }),
    (nonConferenceNonNeutralString, { !$0.1.isConferenceMatchup && !$0.1.venue.isNeutral })
]

func getCategoryGroup(baseName: String,
                      generalSize: @escaping GameFilter,
                      homeSize: @escaping GameFilter,
                      awaySize: @escaping GameFilter,
                      generalDidMatch: @escaping PreviousGameFilter,
                      generalDesignatedTeam: @escaping NameFilter) -> [Category] {
    
    let generalCategoires = generalCategoryProducers.map { producer in
        Category(name: "Covered Spread w/ \(baseName) \(producer.0)",
                 isMember: { generalSize($0) && producer.1($0) },
                 didMatch: generalDidMatch,
                 designatedTeam: generalDesignatedTeam,
                 weight: 1)
    }
    
    // Commented this block out for now: home/away categories don't seem to improve prediction accuracy
    /*
    let homeCategories = homeAwayCategoryProducers.map { producer in
        Category(name: "Home Team Covered Spread w/ \(baseName) \(producer.0)",
                 isMember: { homeSize($0) && producer.1($0) },
                 didMatch: didHomeTeamCoverTheSpread,
                 designatedTeam: getHomeTeamName)
    }
    
    let awayCategories = homeAwayCategoryProducers.map { producer in
        Category(name: "Away Team Covered Spread w/ \(baseName) \(producer.0)",
                 isMember: { awaySize($0) && producer.1($0) },
                 didMatch: didAwayTeamCoverTheSpread,
                 designatedTeam: getAwayTeamName)
    }*/
    
    return generalCategoires// + homeCategories + awayCategories
}

func getHomeAwayCategoryGroup(baseName: String, size: @escaping GameFilter) -> [Category] {
    let homeCategories: [Category] = homeAwayCategoryProducers.map { producer in
        let prefixName = "Home Team Covered Spread" + (baseName.isEmpty ? "" : "w/")
        
        return Category(name: "\(prefixName) \(baseName) \(producer.0)",
                        isMember: { size($0) && producer.1($0) },
                        didMatch: didHomeTeamCoverTheSpread,
                        designatedTeam: getHomeTeamName,
                        weight: 1)
    }
    
    let awayCategories: [Category] = homeAwayCategoryProducers.map { producer in
        let prefixName = "Away Team Covered Spread" + (baseName.isEmpty ? "" : " w/")
        
        return Category(name: "\(prefixName) \(baseName) \(producer.0)",
                        isMember: { size($0) && producer.1($0) },
                        didMatch: didAwayTeamCoverTheSpread,
                        designatedTeam: getAwayTeamName,
                        weight: 1)
    }
    
    return homeCategories + awayCategories
}

func getCategoriesForAllComparisons() -> [Category] {
    let greaterComparisons: [[Category]] = Comparison.all.map { comparison in
        let baseNamePrefix = comparison.isOpponentStat ? "\(comparison.greaterPrefix) Opponent" : comparison.greaterPrefix
        
        return getCategoryGroup(baseName: "\(baseNamePrefix) \(comparison.name)",
                                generalSize: { isComparisonNonEqual(comparison, for: $0) },
                                homeSize: { isComparisonNonEqual(comparison, for: $0) && isComparisonGreaterForHomeTeam(comparison, for: $0) },
                                awaySize: { isComparisonNonEqual(comparison, for: $0) && isComparisonGreaterForAwayTeam(comparison, for: $0) },
                                generalDidMatch: { didTeamWithGreaterComparisonCoverSpread(comparison, for: $0) },
                                generalDesignatedTeam: { getTeamNameWithGreaterComparison(comparison, for: $0) })
    }
    
    let lesserComparisons: [[Category]] = Comparison.all.map { comparison in
        let baseNamePrefix = comparison.isOpponentStat ? "\(comparison.lesserPrefix) Opponent" : comparison.lesserPrefix
        
        return getCategoryGroup(baseName: "\(baseNamePrefix) \(comparison.name)",
                                generalSize: { isComparisonNonEqual(comparison, for: $0) },
                                homeSize: { isComparisonNonEqual(comparison, for: $0) && isComparisonLessForHomeTeam(comparison, for: $0) },
                                awaySize: { isComparisonNonEqual(comparison, for: $0) && isComparisonLessForAwayTeam(comparison, for: $0) },
                                generalDidMatch: { didTeamWithLesserComparisonCoverSpread(comparison, for: $0) },
                                generalDesignatedTeam: { getTeamNameWithLesserComparison(comparison, for: $0) })
    }
    
    return (greaterComparisons + lesserComparisons).flatMap { $0 }
}

func getCategoryCombinations(from categories: [Category]) -> [Category] {
    // This is commented out for now because this produces millions of categories and takes too long,
    // but this essentially "mines" categories to find specific meaningful stat combinations
    
    /*
    var newCategories = categories
    
    let categoriesByClass: [[Category]] = categoryClassStrings.map { name in
        categories.filter { $0.name.contains(name) }
    }
    
    for classIsolatedCategories in categoriesByClass {
        for combination in classIsolatedCategories.combinations(ofCount: 2) {
            var newCategory = combination.first!
            combination.dropFirst().forEach { newCategory = newCategory + $0 }
            newCategories.append(newCategory)
        }
    }
    */
    return categories
}


// MARK: - Category Operators

func +(lhs: Category, rhs: Category) -> Category {
    let categoryClassString = categoryClassStrings.first { lhs.name.contains($0) || rhs.name.contains($0) }!
    let lhsBaseString = lhs.name.replace(categoryClassString, with: "")
    let rhsBaseString = rhs.name.replace(categoryClassString, with: "")
    
    let newDesignatedTeam: ((String, Game)) -> String? = {
        let lhsDesignatedTeam = lhs.designatedTeam($0)
        let rhsDesignatedTeam = rhs.designatedTeam($0)
        return lhsDesignatedTeam == rhsDesignatedTeam ? lhsDesignatedTeam : nil
    }
    
    return Category(name: "\(lhsBaseString)+ \(rhsBaseString)\(categoryClassString)",
                    isMember: { lhs.isMember($0) && rhs.isMember($0) },
                    didMatch: { lhs.didMatch($0) && rhs.didMatch($0) },
                    designatedTeam: newDesignatedTeam,
                    weight: (lhs.weight + rhs.weight) / 2)
}


// MARK: - Codable Categories

func getCodableCategories(categories: [Category]) -> [CodableCategory] {
    teams.forEach { statCache[$0.teamID] = StatCache() }
    
    let categoriesFileName = "categoryRatings.json"
    let dataDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
    let destinationPath = dataDirectory.path + "/GamePredictor/Data/\(SPORT_MODE.league)"
    
    if !FileManager.default.directoryExists(atPath: destinationPath) {
        try! FileManager.default.createDirectory(atPath: destinationPath, withIntermediateDirectories: true)
    }
    
    let directoryContents = try! FileManager.default.contentsOfDirectory(atPath: destinationPath)
    
    if let fileName = directoryContents.first(where: { $0 == categoriesFileName }) {
        print("\nReading category ratings file...")
        
        let attributes = try! FileManager.default.attributesOfItem(atPath: destinationPath + "/" + fileName) as NSDictionary
        let fileCreationDate = attributes.fileModificationDate() ?? attributes.fileCreationDate()!
        
        if !(fileCreationDate < .now && !Calendar.current.isDateInToday(fileCreationDate)) {
            let fileURL = URL(fileURLWithPath: fileName,
                              relativeTo: dataDirectory.appendingPathComponent("GamePredictor").appendingPathComponent("Data").appendingPathComponent(SPORT_MODE.league))
            let fileData = try! Data(contentsOf: fileURL)
            let codableCategories = try! JSONDecoder().decode([CodableCategory].self, from: fileData)
            
            let newCategories = categories.filter { category in !codableCategories.contains { $0.name == category.name } }
            
            if newCategories.isEmpty {
                return codableCategories
            } else {
                print("Updating category ratings file with \(newCategories.count) new categories...")
                
                let updatedCodableCategories = codableCategories + newCategories.map { .init(name: $0.name, rating: $0.rating, weight: getCategoryWeight(for: $0.rating)) }
                updatedCodableCategories.export(as: categoriesFileName)
                
                return updatedCodableCategories
            }
        }
    }
    
    print("\nCreating new category ratings file...\n")
    
    let codableCategories: [CodableCategory] = categories.enumerated().map { index, category in
        if VERBOSE_OUTPUT {
            print("(\(index) of \(categories.count)): Obtaining rating for \(category.name)")
        }
        
        return CodableCategory(name: category.name, rating: category.rating, weight: getCategoryWeight(for: category.rating))
    }
    
    codableCategories.export(as: categoriesFileName)
    
    return codableCategories
}

func getCategoryWeight(for ranking: Int) -> Double {
    1.0 + ((Double(ranking) - 50.0) / 10.0)
}


// MARK: - General Home/Away Helper Functions

func didHomeTeamCoverTheSpread(_ game: (String, Team.PreviousGame)) -> Bool {
    (game.1.venue.isHome && game.1.didCoverSpread) || (game.1.venue.isAway && !game.1.didCoverSpread)
}

func didAwayTeamCoverTheSpread(_ game: (String, Team.PreviousGame)) -> Bool {
    (game.1.venue.isAway && game.1.didCoverSpread) || (game.1.venue.isHome && !game.1.didCoverSpread)
}

func getHomeTeamName(_ game: (String, Game)) -> String? {
    switch game.1.venue {
    case .home:    return game.0
    case .away:    return game.1.opponentID
    case .neutral: return nil
    }
}

func getAwayTeamName(_ game: (String, Game)) -> String? {
    switch game.1.venue {
    case .home:    return game.1.opponentID
    case .away:    return game.0
    case .neutral: return nil
    }
}


// MARK: - Pairs

func getComparisonPair(_ comparison: Comparison, for game: (String, Game)) -> (Double?, Double?) {
    let teamA = teams.first { $0.teamID == game.0 }!
    let teamB = teams.first { $0.teamID == game.1.opponentID }!
    
    switch comparison {
    case .record(let record):
        switch record {
        case .overall:
            return (Double(teamA.getRecord(beforeDate: game.1.date).overallPercentage),
                    Double(teamB.getRecord(beforeDate: game.1.date).overallPercentage))
        case .conference:
            return (Double(teamA.getRecord(beforeDate: game.1.date).conferencePercentage),
                    Double(teamB.getRecord(beforeDate: game.1.date).conferencePercentage))
        case .nationalRanking:
            return (teamA.getNationalRanking(onDate: game.1.date).flatMap { Double($0) },
                    teamB.getNationalRanking(onDate: game.1.date).flatMap { Double($0) })
        case .last5Games:
            return (Double(teamA.getRecord(beforeDate: game.1.date, last5Games: true).overallPercentage),
                    Double(teamB.getRecord(beforeDate: game.1.date, last5Games: true).overallPercentage))
        case .road:
            return (Double(teamA.getRecord(beforeDate: game.1.date, isHome: false).overallPercentage),
                    Double(teamB.getRecord(beforeDate: game.1.date, isHome: false).overallPercentage))
        case .home:
            return (Double(teamA.getRecord(beforeDate: game.1.date, isHome: true).overallPercentage),
                    Double(teamB.getRecord(beforeDate: game.1.date, isHome: true).overallPercentage))
        }
    case .stat(let stat), .opponentStat(let stat):
        let statType: Team.StatType = comparison.isOpponentStat ? .opponent : .team
        let teamAStats = teamA.getStats(onDate: game.1.date, statType: statType)
        let teamBStats = teamB.getStats(onDate: game.1.date, statType: statType)
        
        switch stat {
        case .points:               return (Double(teamAStats.pointsScored), Double(teamBStats.pointsScored))
        case .fieldGoals:           return (Double(teamAStats.fieldGoals.percentages), Double(teamBStats.fieldGoals.percentages))
        case .threePointFieldGoals: return (Double(teamAStats.threePointFieldGoals.percentages), Double(teamBStats.threePointFieldGoals.percentages))
        case .freeThrows:           return (Double(teamAStats.freeThrows.percentages), Double(teamBStats.freeThrows.percentages))
        case .offensiveRebounds:    return (Double(teamAStats.rebounds.offensive), Double(teamBStats.rebounds.offensive))
        case .defensiveRebounds:    return (Double(teamAStats.rebounds.defensive), Double(teamBStats.rebounds.defensive))
        case .totalRebounds:        return (Double(teamAStats.rebounds.total), Double(teamBStats.rebounds.total))
        case .assists:              return (Double(teamAStats.assists), Double(teamBStats.assists))
        case .steals:               return (Double(teamAStats.steals), Double(teamBStats.steals))
        case .blocks:               return (Double(teamAStats.blocks), Double(teamBStats.blocks))
        case .turnovers:            return (Double(teamAStats.turnovers), Double(teamBStats.turnovers))
        case .personalFouls:        return (Double(teamAStats.personalFouls), Double(teamBStats.personalFouls))
        case .offensiveEfficiency:  return (Double(teamA.getOffsensiveEfficiency(onDate: game.1.date)), Double(teamB.getOffsensiveEfficiency(onDate: game.1.date)))
        case .defensiveEfficiency:  return (Double(teamA.getDefensiveEfficiency(onDate: game.1.date)), Double(teamB.getDefensiveEfficiency(onDate: game.1.date)))
        case .adjustedTempo:        return (Double(teamA.getAdjustedTempo(onDate: game.1.date)), Double(teamB.getAdjustedTempo(onDate: game.1.date)))
        case .averageHeights:       return (teamA.averageHeight, teamB.averageHeight)
        case .assistToTurnoverRatio:
            let teamAAssists = Double(teamAStats.assists)
            let teamBAssists = Double(teamBStats.assists)
            let teamATurnovers = Double(teamAStats.turnovers)
            let teamBTurnovers = Double(teamBStats.turnovers)
            
            guard ![teamATurnovers, teamBTurnovers].contains(0) else { return (nil, nil) }
            return (teamAAssists / teamATurnovers, teamBAssists / teamBTurnovers)
        }
    case .experience(let experience):
        switch experience {
        case .combined:
            return (Double(teamA.combinedYearsOfExperience), Double(teamB.combinedYearsOfExperience))
        case .top5Combined:
            return (Double(teamA.getTop5PlayersCombinedYearsOfExperience(onDate: game.1.date)),
                    Double(teamB.getTop5PlayersCombinedYearsOfExperience(onDate: game.1.date)))
        }
    }
}


// MARK: - General Comparison Functions

func isComparisonNonEqual(_ comparison: Comparison, for game: (String, Game)) -> Bool {
    let (teamAValue, teamBValue) = getComparisonPair(comparison, for: game)
    guard let teamAValue = teamAValue, let teamBValue = teamBValue else { return false }
    return teamAValue != teamBValue
}

func isComparisonGreaterForHomeTeam(_ comparison: Comparison, for game: (String, Game)) -> Bool {
    let (teamAValue, teamBValue) = getComparisonPair(comparison, for: game)
    guard let teamAValue = teamAValue, let teamBValue = teamBValue else { return false }
    return (teamAValue > teamBValue && game.1.venue.isHome) || (teamBValue > teamAValue && game.1.venue.isAway)
}

func isComparisonGreaterForAwayTeam(_ comparison: Comparison, for game: (String, Game)) -> Bool {
    let (teamAValue, teamBValue) = getComparisonPair(comparison, for: game)
    guard let teamAValue = teamAValue, let teamBValue = teamBValue else { return false }
    return (teamAValue > teamBValue && game.1.venue.isAway) || (teamBValue > teamAValue && game.1.venue.isHome)
}

func isComparisonLessForHomeTeam(_ comparison: Comparison, for game: (String, Game)) -> Bool {
    let (teamAValue, teamBValue) = getComparisonPair(comparison, for: game)
    guard let teamAValue = teamAValue, let teamBValue = teamBValue else { return false }
    return (teamAValue < teamBValue && game.1.venue.isHome) || (teamBValue < teamAValue && game.1.venue.isAway)
}

func isComparisonLessForAwayTeam(_ comparison: Comparison, for game: (String, Game)) -> Bool {
    let (teamAValue, teamBValue) = getComparisonPair(comparison, for: game)
    guard let teamAValue = teamAValue, let teamBValue = teamBValue else { return false }
    return (teamAValue < teamBValue && game.1.venue.isAway) || (teamBValue < teamAValue && game.1.venue.isHome)
}

func didTeamWithGreaterComparisonCoverSpread(_ comparison: Comparison, for game: (String, Team.PreviousGame)) -> Bool {
    let (teamAValue, teamBValue) = getComparisonPair(comparison, for: game)
    guard let teamAValue = teamAValue, let teamBValue = teamBValue else { return false }
    return (teamAValue > teamBValue && game.1.didCoverSpread) || (teamBValue > teamAValue && !game.1.didCoverSpread)
}

func didTeamWithLesserComparisonCoverSpread(_ comparison: Comparison, for game: (String, Team.PreviousGame)) -> Bool {
    let (teamAValue, teamBValue) = getComparisonPair(comparison, for: game)
    guard let teamAValue = teamAValue, let teamBValue = teamBValue else { return false }
    return (teamAValue < teamBValue && game.1.didCoverSpread) || (teamBValue < teamAValue && !game.1.didCoverSpread)
}

func getTeamNameWithGreaterComparison(_ comparison: Comparison, for game: (String, Game)) -> String? {
    let (teamAValue, teamBValue) = getComparisonPair(comparison, for: game)
    guard let teamAValue = teamAValue, let teamBValue = teamBValue else { return nil }
    
    if teamAValue > teamBValue {
        return game.0
    } else if teamBValue > teamAValue {
        return game.1.opponentID
    } else {
        return nil
    }
}

func getTeamNameWithLesserComparison(_ comparison: Comparison, for game: (String, Game)) -> String? {
    let (teamAValue, teamBValue) = getComparisonPair(comparison, for: game)
    guard let teamAValue = teamAValue, let teamBValue = teamBValue else { return nil }
    
    if teamAValue < teamBValue {
        return game.0
    } else if teamBValue < teamAValue {
        return game.1.opponentID
    } else {
        return nil
    }
}

                                                                  
// MARK: - More Offensive Rebounds Against Teams With Less Defensive Rebounds

func doesMatchupHaveATeamWithMoreOffensiveReboundsAndDefensiveRebounds(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveRebounds, teamBOffensiveRebounds) = getComparisonPair(.stat(.offensiveRebounds), for: game)
    let (teamADefensiveRebounds, teamBDefensiveRebounds) = getComparisonPair(.stat(.defensiveRebounds), for: game)
    
    guard
        let teamAOffensiveRebounds = teamAOffensiveRebounds,
        let teamBOffensiveRebounds = teamBOffensiveRebounds,
        let teamADefensiveRebounds = teamADefensiveRebounds,
        let teamBDefensiveRebounds = teamBDefensiveRebounds
    else { return false }
    
    return (teamAOffensiveRebounds > teamBOffensiveRebounds && teamADefensiveRebounds > teamBDefensiveRebounds)
        || (teamBOffensiveRebounds > teamAOffensiveRebounds && teamBDefensiveRebounds > teamADefensiveRebounds)
}

func doesMatchupHaveAHomeTeamWithMoreOffensiveReboundsAndDefensiveRebounds(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveRebounds, teamBOffensiveRebounds) = getComparisonPair(.stat(.offensiveRebounds), for: game)
    let (teamADefensiveRebounds, teamBDefensiveRebounds) = getComparisonPair(.stat(.defensiveRebounds), for: game)
    
    guard
        let teamAOffensiveRebounds = teamAOffensiveRebounds,
        let teamBOffensiveRebounds = teamBOffensiveRebounds,
        let teamADefensiveRebounds = teamADefensiveRebounds,
        let teamBDefensiveRebounds = teamBDefensiveRebounds
    else { return false }
    
    return (teamAOffensiveRebounds > teamBOffensiveRebounds && teamADefensiveRebounds > teamBDefensiveRebounds && game.1.venue.isHome)
        || (teamBOffensiveRebounds > teamAOffensiveRebounds && teamBDefensiveRebounds > teamADefensiveRebounds && game.1.venue.isAway)
}

func doesMatchupHaveAnAwayTeamWithMoreOffensiveReboundsAndDefensiveRebounds(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveRebounds, teamBOffensiveRebounds) = getComparisonPair(.stat(.offensiveRebounds), for: game)
    let (teamADefensiveRebounds, teamBDefensiveRebounds) = getComparisonPair(.stat(.defensiveRebounds), for: game)
    
    guard
        let teamAOffensiveRebounds = teamAOffensiveRebounds,
        let teamBOffensiveRebounds = teamBOffensiveRebounds,
        let teamADefensiveRebounds = teamADefensiveRebounds,
        let teamBDefensiveRebounds = teamBDefensiveRebounds
    else { return false }
    
    return (teamAOffensiveRebounds > teamBOffensiveRebounds && teamADefensiveRebounds > teamBDefensiveRebounds && game.1.venue.isAway)
        || (teamBOffensiveRebounds > teamAOffensiveRebounds && teamBDefensiveRebounds > teamADefensiveRebounds && game.1.venue.isHome)
}

func didTeamWithMoreOffensiveAndDefensiveReboundsCoverTheSpread(_ game: (String, Team.PreviousGame)) -> Bool {
    let (teamAOffensiveRebounds, teamBOffensiveRebounds) = getComparisonPair(.stat(.offensiveRebounds), for: game)
    let (teamADefensiveRebounds, teamBDefensiveRebounds) = getComparisonPair(.stat(.defensiveRebounds), for: game)
    
    guard
        let teamAOffensiveRebounds = teamAOffensiveRebounds,
        let teamBOffensiveRebounds = teamBOffensiveRebounds,
        let teamADefensiveRebounds = teamADefensiveRebounds,
        let teamBDefensiveRebounds = teamBDefensiveRebounds
    else { return false }
    
    return (teamAOffensiveRebounds > teamBOffensiveRebounds && teamADefensiveRebounds > teamBDefensiveRebounds && game.1.didCoverSpread)
        || (teamBOffensiveRebounds > teamAOffensiveRebounds && teamBDefensiveRebounds > teamADefensiveRebounds && !game.1.didCoverSpread)
}

func getTeamNameWithMoreOffensiveAndDefensiveRebounds(_ game: (String, Game)) -> String? {
    let (teamAOffensiveRebounds, teamBOffensiveRebounds) = getComparisonPair(.stat(.offensiveRebounds), for: game)
    let (teamADefensiveRebounds, teamBDefensiveRebounds) = getComparisonPair(.stat(.defensiveRebounds), for: game)
    
    guard
        let teamAOffensiveRebounds = teamAOffensiveRebounds,
        let teamBOffensiveRebounds = teamBOffensiveRebounds,
        let teamADefensiveRebounds = teamADefensiveRebounds,
        let teamBDefensiveRebounds = teamBDefensiveRebounds
    else { return nil }
    
    if teamAOffensiveRebounds > teamBOffensiveRebounds && teamADefensiveRebounds > teamBDefensiveRebounds {
        return game.0
    } else if teamBOffensiveRebounds > teamAOffensiveRebounds && teamBDefensiveRebounds > teamADefensiveRebounds {
        return game.1.opponentID
    } else {
        return nil
    }
}


// MARK: - Less Offensive Rebounds Against Teams With Less Defensive Rebounds

func doesMatchupHaveATeamWithLessOffensiveReboundsAndDefensiveRebounds(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveRebounds, teamBOffensiveRebounds) = getComparisonPair(.stat(.offensiveRebounds), for: game)
    let (teamADefensiveRebounds, teamBDefensiveRebounds) = getComparisonPair(.stat(.defensiveRebounds), for: game)
    
    guard
        let teamAOffensiveRebounds = teamAOffensiveRebounds,
        let teamBOffensiveRebounds = teamBOffensiveRebounds,
        let teamADefensiveRebounds = teamADefensiveRebounds,
        let teamBDefensiveRebounds = teamBDefensiveRebounds
    else { return false }
    
    return (teamAOffensiveRebounds < teamBOffensiveRebounds && teamADefensiveRebounds < teamBDefensiveRebounds)
        || (teamBOffensiveRebounds < teamAOffensiveRebounds && teamBDefensiveRebounds < teamADefensiveRebounds)
}

func doesMatchupHaveAHomeTeamWithLessOffensiveReboundsAndDefensiveRebounds(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveRebounds, teamBOffensiveRebounds) = getComparisonPair(.stat(.offensiveRebounds), for: game)
    let (teamADefensiveRebounds, teamBDefensiveRebounds) = getComparisonPair(.stat(.defensiveRebounds), for: game)
    
    guard
        let teamAOffensiveRebounds = teamAOffensiveRebounds,
        let teamBOffensiveRebounds = teamBOffensiveRebounds,
        let teamADefensiveRebounds = teamADefensiveRebounds,
        let teamBDefensiveRebounds = teamBDefensiveRebounds
    else { return false }
    
    return (teamAOffensiveRebounds < teamBOffensiveRebounds && teamADefensiveRebounds < teamBDefensiveRebounds && game.1.venue.isHome)
        || (teamBOffensiveRebounds < teamAOffensiveRebounds && teamBDefensiveRebounds < teamADefensiveRebounds && game.1.venue.isAway)
}

func doesMatchupHaveAnAwayTeamWithLessOffensiveReboundsAndDefensiveRebounds(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveRebounds, teamBOffensiveRebounds) = getComparisonPair(.stat(.offensiveRebounds), for: game)
    let (teamADefensiveRebounds, teamBDefensiveRebounds) = getComparisonPair(.stat(.defensiveRebounds), for: game)
    
    guard
        let teamAOffensiveRebounds = teamAOffensiveRebounds,
        let teamBOffensiveRebounds = teamBOffensiveRebounds,
        let teamADefensiveRebounds = teamADefensiveRebounds,
        let teamBDefensiveRebounds = teamBDefensiveRebounds
    else { return false }
    
    return (teamAOffensiveRebounds < teamBOffensiveRebounds && teamADefensiveRebounds < teamBDefensiveRebounds && game.1.venue.isAway)
        || (teamBOffensiveRebounds < teamAOffensiveRebounds && teamBDefensiveRebounds < teamADefensiveRebounds && game.1.venue.isHome)
}

func didTeamWithLessOffensiveAndDefensiveReboundsCoverTheSpread(_ game: (String, Team.PreviousGame)) -> Bool {
    let (teamAOffensiveRebounds, teamBOffensiveRebounds) = getComparisonPair(.stat(.offensiveRebounds), for: game)
    let (teamADefensiveRebounds, teamBDefensiveRebounds) = getComparisonPair(.stat(.defensiveRebounds), for: game)
    
    guard
        let teamAOffensiveRebounds = teamAOffensiveRebounds,
        let teamBOffensiveRebounds = teamBOffensiveRebounds,
        let teamADefensiveRebounds = teamADefensiveRebounds,
        let teamBDefensiveRebounds = teamBDefensiveRebounds
    else { return false }
    
    return (teamAOffensiveRebounds < teamBOffensiveRebounds && teamADefensiveRebounds < teamBDefensiveRebounds && game.1.didCoverSpread)
        || (teamBOffensiveRebounds < teamAOffensiveRebounds && teamBDefensiveRebounds < teamADefensiveRebounds && !game.1.didCoverSpread)
}

func getTeamNameWithLessOffensiveAndDefensiveRebounds(_ game: (String, Game)) -> String? {
    let (teamAOffensiveRebounds, teamBOffensiveRebounds) = getComparisonPair(.stat(.offensiveRebounds), for: game)
    let (teamADefensiveRebounds, teamBDefensiveRebounds) = getComparisonPair(.stat(.defensiveRebounds), for: game)
    
    guard
        let teamAOffensiveRebounds = teamAOffensiveRebounds,
        let teamBOffensiveRebounds = teamBOffensiveRebounds,
        let teamADefensiveRebounds = teamADefensiveRebounds,
        let teamBDefensiveRebounds = teamBDefensiveRebounds
    else { return nil }
    
    if teamAOffensiveRebounds < teamBOffensiveRebounds && teamADefensiveRebounds < teamBDefensiveRebounds {
        return game.0
    } else if teamBOffensiveRebounds < teamAOffensiveRebounds && teamBDefensiveRebounds < teamADefensiveRebounds {
        return game.1.opponentID
    } else {
        return nil
    }
}


// MARK: - More Steals Against Team With More Turnovers

func doesMatchupHaveATeamWithMoreStealsAndLessTurnovers(_ game: (String, Game)) -> Bool {
    let (teamASteals, teamBSteals) = getComparisonPair(.stat(.steals), for: game)
    let (teamATurnovers, teamBTurnovers) = getComparisonPair(.stat(.turnovers), for: game)
    
    guard
        let teamASteals = teamASteals, let teamBSteals = teamBSteals,
        let teamATurnovers = teamATurnovers, let teamBTurnovers = teamBTurnovers
    else { return false }
    
    return (teamASteals > teamBSteals && teamBTurnovers > teamATurnovers)
        || (teamBSteals > teamASteals && teamATurnovers > teamBTurnovers)
}

func doesMatchupHaveAHomeTeamWithMoreStealsAndLessTurnovers(_ game: (String, Game)) -> Bool {
    let (teamASteals, teamBSteals) = getComparisonPair(.stat(.steals), for: game)
    let (teamATurnovers, teamBTurnovers) = getComparisonPair(.stat(.turnovers), for: game)
    
    guard
        let teamASteals = teamASteals, let teamBSteals = teamBSteals,
        let teamATurnovers = teamATurnovers, let teamBTurnovers = teamBTurnovers
    else { return false }
    
    return (teamASteals > teamBSteals && teamBTurnovers > teamATurnovers && game.1.venue.isHome)
        || (teamBSteals > teamASteals && teamATurnovers > teamBTurnovers && game.1.venue.isAway)
}

func doesMatchupHaveAnAwayTeamWithMoreStealsAndLessTurnovers(_ game: (String, Game)) -> Bool {
    let (teamASteals, teamBSteals) = getComparisonPair(.stat(.steals), for: game)
    let (teamATurnovers, teamBTurnovers) = getComparisonPair(.stat(.turnovers), for: game)
    
    guard
        let teamASteals = teamASteals, let teamBSteals = teamBSteals,
        let teamATurnovers = teamATurnovers, let teamBTurnovers = teamBTurnovers
    else { return false }
    
    return (teamASteals > teamBSteals && teamBTurnovers > teamATurnovers && game.1.venue.isAway)
        || (teamBSteals > teamASteals && teamATurnovers > teamBTurnovers && game.1.venue.isHome)
}

func didTeamWithMoreStealsAndLessTurnoversCoverSpread(_ game: (String, Team.PreviousGame)) -> Bool {
    let (teamASteals, teamBSteals) = getComparisonPair(.stat(.steals), for: game)
    let (teamATurnovers, teamBTurnovers) = getComparisonPair(.stat(.turnovers), for: game)
    
    guard
        let teamASteals = teamASteals, let teamBSteals = teamBSteals,
        let teamATurnovers = teamATurnovers, let teamBTurnovers = teamBTurnovers
    else { return false }
    
    return (teamASteals > teamBSteals && teamBTurnovers > teamATurnovers && game.1.didCoverSpread)
        || (teamBSteals > teamASteals && teamATurnovers > teamBTurnovers && !game.1.didCoverSpread)
}

func getTeamNameWithMoreStealsAndLessTurnovers(_ game: (String, Game)) -> String? {
    let (teamASteals, teamBSteals) = getComparisonPair(.stat(.steals), for: game)
    let (teamATurnovers, teamBTurnovers) = getComparisonPair(.stat(.turnovers), for: game)
    
    guard
        let teamASteals = teamASteals, let teamBSteals = teamBSteals,
        let teamATurnovers = teamATurnovers, let teamBTurnovers = teamBTurnovers
    else { return nil }
    
    if teamASteals > teamBSteals && teamBTurnovers > teamATurnovers {
        return game.0
    } else if teamBSteals > teamASteals && teamATurnovers > teamBTurnovers {
        return game.1.opponentID
    } else {
        return nil
    }
}


// MARK: - Less Steals Against Team With Less Turnovers

func doesMatchupHaveATeamWithLessStealsAndMoreTurnovers(_ game: (String, Game)) -> Bool {
    let (teamASteals, teamBSteals) = getComparisonPair(.stat(.steals), for: game)
    let (teamATurnovers, teamBTurnovers) = getComparisonPair(.stat(.turnovers), for: game)
    
    guard
        let teamASteals = teamASteals, let teamBSteals = teamBSteals,
        let teamATurnovers = teamATurnovers, let teamBTurnovers = teamBTurnovers
    else { return false }
    
    return (teamASteals < teamBSteals && teamBTurnovers < teamATurnovers)
        || (teamBSteals < teamASteals && teamATurnovers < teamBTurnovers)
}

func doesMatchupHaveAHomeTeamWithLessStealsAndMoreTurnovers(_ game: (String, Game)) -> Bool {
    let (teamASteals, teamBSteals) = getComparisonPair(.stat(.steals), for: game)
    let (teamATurnovers, teamBTurnovers) = getComparisonPair(.stat(.turnovers), for: game)
    
    guard
        let teamASteals = teamASteals, let teamBSteals = teamBSteals,
        let teamATurnovers = teamATurnovers, let teamBTurnovers = teamBTurnovers
    else { return false }
    
    return (teamASteals < teamBSteals && teamBTurnovers < teamATurnovers && game.1.venue.isHome)
        || (teamBSteals < teamASteals && teamATurnovers < teamBTurnovers && game.1.venue.isAway)
}

func doesMatchupHaveAnAwayTeamWithLessStealsAndMoreTurnovers(_ game: (String, Game)) -> Bool {
    let (teamASteals, teamBSteals) = getComparisonPair(.stat(.steals), for: game)
    let (teamATurnovers, teamBTurnovers) = getComparisonPair(.stat(.turnovers), for: game)
    
    guard
        let teamASteals = teamASteals, let teamBSteals = teamBSteals,
        let teamATurnovers = teamATurnovers, let teamBTurnovers = teamBTurnovers
    else { return false }
    
    return (teamASteals < teamBSteals && teamBTurnovers < teamATurnovers && game.1.venue.isAway)
        || (teamBSteals < teamASteals && teamATurnovers < teamBTurnovers && game.1.venue.isHome)
}

func didTeamWithLessStealsAndMoreTurnoversCoverSpread(_ game: (String, Team.PreviousGame)) -> Bool {
    let (teamASteals, teamBSteals) = getComparisonPair(.stat(.steals), for: game)
    let (teamATurnovers, teamBTurnovers) = getComparisonPair(.stat(.turnovers), for: game)
    
    guard
        let teamASteals = teamASteals, let teamBSteals = teamBSteals,
        let teamATurnovers = teamATurnovers, let teamBTurnovers = teamBTurnovers
    else { return false }
    
    return (teamASteals < teamBSteals && teamBTurnovers < teamATurnovers && game.1.didCoverSpread)
        || (teamBSteals < teamASteals && teamATurnovers < teamBTurnovers && !game.1.didCoverSpread)
}

func getTeamNameWithLessStealsAndMoreTurnovers(_ game: (String, Game)) -> String? {
    let (teamASteals, teamBSteals) = getComparisonPair(.stat(.steals), for: game)
    let (teamATurnovers, teamBTurnovers) = getComparisonPair(.stat(.turnovers), for: game)
    
    guard
        let teamASteals = teamASteals, let teamBSteals = teamBSteals,
        let teamATurnovers = teamATurnovers, let teamBTurnovers = teamBTurnovers
    else { return nil }
    
    if teamASteals < teamBSteals && teamBTurnovers < teamATurnovers {
        return game.0
    } else if teamBSteals < teamASteals && teamATurnovers < teamBTurnovers {
        return game.1.opponentID
    } else {
        return nil
    }
}


// MARK: - Both Opponents Are Nationally Ranked

func doesMatchupHaveTwoNationallyRankedTeams(_ game: (String, Game)) -> Bool {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    return [teamARanking, teamBRanking].compactMap { $0 }.count == 2
}


// MARK: - Better National Ranking When Both Opponents Are Nationally Ranked

func doesHomeTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(_ game: (String, Game)) -> Bool {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    guard [teamARanking, teamBRanking].compactMap({ $0 }).count == 2 else { return false }
    return (teamARanking! > teamBRanking! && game.1.venue.isHome) || (teamBRanking! > teamARanking! && game.1.venue.isAway)
}

func doesAwayTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(_ game: (String, Game)) -> Bool {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    guard [teamARanking, teamBRanking].compactMap({ $0 }).count == 2 else { return false }
    return (teamARanking! > teamBRanking! && game.1.venue.isAway) || (teamBRanking! > teamARanking! && game.1.venue.isHome)
}

func didTeamWithBetterNationalRankingCoverSpread(_ game: (String, Team.PreviousGame)) -> Bool {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    guard [teamARanking, teamBRanking].compactMap({ $0 }).count == 2 else { return false }
    return (teamARanking! > teamBRanking! && game.1.didCoverSpread) || (teamBRanking! > teamARanking! && !game.1.didCoverSpread)
}

func getTeamNameWithBetterNationalRanking(_ game: (String, Game)) -> String? {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    
    guard [teamARanking, teamBRanking].compactMap({ $0 }).count == 2 else { return nil }
    
    if teamARanking! > teamBRanking! {
        return game.0
    } else if teamBRanking! > teamARanking! {
        return game.1.opponentID
    } else {
        return nil
    }
}


// MARK: - Worse National Ranking When Both Opponents Are Nationally Ranked

func doesHomeTeamHaveWorseNationalRankingThanNationallyRankedAwayTeam(_ game: (String, Game)) -> Bool {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    guard [teamARanking, teamBRanking].compactMap({ $0 }).count == 2 else { return false }
    return (teamARanking! < teamBRanking! && game.1.venue.isHome) || (teamBRanking! < teamARanking! && game.1.venue.isAway)
}

func doesAwayTeamHaveWorseNationalRankingThanNationallyRankedAwayTeam(_ game: (String, Game)) -> Bool {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    guard [teamARanking, teamBRanking].compactMap({ $0 }).count == 2 else { return false }
    return (teamARanking! < teamBRanking! && game.1.venue.isAway) || (teamBRanking! < teamARanking! && game.1.venue.isHome)
}

func didTeamWithWorseNationalRankingCoverSpread(_ game: (String, Team.PreviousGame)) -> Bool {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    guard [teamARanking, teamBRanking].compactMap({ $0 }).count == 2 else { return false }
    return (teamARanking! < teamBRanking! && game.1.didCoverSpread) || (teamBRanking! < teamARanking! && !game.1.didCoverSpread)
}

func getTeamNameWithWorseNationalRanking(_ game: (String, Game)) -> String? {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    
    guard [teamARanking, teamBRanking].compactMap({ $0 }).count == 2 else { return nil }
    
    if teamARanking! < teamBRanking! {
        return game.0
    } else if teamBRanking! < teamARanking! {
        return game.1.opponentID
    } else {
        return nil
    }
}


// MARK: - Better Offensive And Defensive Efficiency

func doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveEfficiency, teamBOffensiveEfficiency) = getComparisonPair(.stat(.offensiveEfficiency), for: game)
    let (teamADefensiveEfficiency, teamBDefensiveEfficiency) = getComparisonPair(.stat(.defensiveEfficiency), for: game)
    
    guard
        let teamAOffensiveEfficiency = teamAOffensiveEfficiency,
        let teamBOffensiveEfficiency = teamBOffensiveEfficiency,
        let teamADefensiveEfficiency = teamADefensiveEfficiency,
        let teamBDefensiveEfficiency = teamBDefensiveEfficiency
    else { return false }

    
    return (teamAOffensiveEfficiency > teamBOffensiveEfficiency && teamADefensiveEfficiency > teamBDefensiveEfficiency)
        || (teamBOffensiveEfficiency > teamAOffensiveEfficiency && teamBDefensiveEfficiency > teamADefensiveEfficiency)
}

func doesHomeTeamHaveBetterOffensiveAndDefensiveEfficiency(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveEfficiency, teamBOffensiveEfficiency) = getComparisonPair(.stat(.offensiveEfficiency), for: game)
    let (teamADefensiveEfficiency, teamBDefensiveEfficiency) = getComparisonPair(.stat(.defensiveEfficiency), for: game)
    
    guard
        let teamAOffensiveEfficiency = teamAOffensiveEfficiency,
        let teamBOffensiveEfficiency = teamBOffensiveEfficiency,
        let teamADefensiveEfficiency = teamADefensiveEfficiency,
        let teamBDefensiveEfficiency = teamBDefensiveEfficiency
    else { return false }
    
    return (teamAOffensiveEfficiency > teamBOffensiveEfficiency && teamADefensiveEfficiency > teamBDefensiveEfficiency && game.1.venue.isHome)
        || (teamBOffensiveEfficiency > teamAOffensiveEfficiency && teamBDefensiveEfficiency > teamADefensiveEfficiency && game.1.venue.isAway)
}

func doesAwayTeamHaveBetterOffensiveAndDefensiveEfficiency(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveEfficiency, teamBOffensiveEfficiency) = getComparisonPair(.stat(.offensiveEfficiency), for: game)
    let (teamADefensiveEfficiency, teamBDefensiveEfficiency) = getComparisonPair(.stat(.defensiveEfficiency), for: game)
    
    guard
        let teamAOffensiveEfficiency = teamAOffensiveEfficiency,
        let teamBOffensiveEfficiency = teamBOffensiveEfficiency,
        let teamADefensiveEfficiency = teamADefensiveEfficiency,
        let teamBDefensiveEfficiency = teamBDefensiveEfficiency
    else { return false }
    
    return (teamAOffensiveEfficiency > teamBOffensiveEfficiency && teamADefensiveEfficiency > teamBDefensiveEfficiency && game.1.venue.isAway)
        || (teamBOffensiveEfficiency > teamAOffensiveEfficiency && teamBDefensiveEfficiency > teamADefensiveEfficiency && game.1.venue.isHome)
}

func didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(_ game: (String, Team.PreviousGame)) -> Bool {
    let (teamAOffensiveEfficiency, teamBOffensiveEfficiency) = getComparisonPair(.stat(.offensiveEfficiency), for: game)
    let (teamADefensiveEfficiency, teamBDefensiveEfficiency) = getComparisonPair(.stat(.defensiveEfficiency), for: game)
    
    guard
        let teamAOffensiveEfficiency = teamAOffensiveEfficiency,
        let teamBOffensiveEfficiency = teamBOffensiveEfficiency,
        let teamADefensiveEfficiency = teamADefensiveEfficiency,
        let teamBDefensiveEfficiency = teamBDefensiveEfficiency
    else { return false }
    
    return (teamAOffensiveEfficiency > teamBOffensiveEfficiency && teamADefensiveEfficiency > teamBDefensiveEfficiency && game.1.didCoverSpread)
        || (teamBOffensiveEfficiency > teamAOffensiveEfficiency && teamBDefensiveEfficiency > teamADefensiveEfficiency && !game.1.didCoverSpread)
}

func getTeamNameWithBetterOffensiveAndDefensiveEfficiency(_ game: (String, Game)) -> String? {
    let (teamAOffensiveEfficiency, teamBOffensiveEfficiency) = getComparisonPair(.stat(.offensiveEfficiency), for: game)
    let (teamADefensiveEfficiency, teamBDefensiveEfficiency) = getComparisonPair(.stat(.defensiveEfficiency), for: game)
    
    guard
        let teamAOffensiveEfficiency = teamAOffensiveEfficiency,
        let teamBOffensiveEfficiency = teamBOffensiveEfficiency,
        let teamADefensiveEfficiency = teamADefensiveEfficiency,
        let teamBDefensiveEfficiency = teamBDefensiveEfficiency
    else { return nil }
    
    if teamAOffensiveEfficiency > teamBOffensiveEfficiency && teamADefensiveEfficiency > teamBDefensiveEfficiency {
        return game.0
    } else if teamBOffensiveEfficiency > teamAOffensiveEfficiency && teamBDefensiveEfficiency > teamADefensiveEfficiency {
        return game.1.opponentID
    } else {
        return nil
    }
}


// MARK: - Worse Offensive And Defensive Efficiency

func doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveEfficiency, teamBOffensiveEfficiency) = getComparisonPair(.stat(.offensiveEfficiency), for: game)
    let (teamADefensiveEfficiency, teamBDefensiveEfficiency) = getComparisonPair(.stat(.defensiveEfficiency), for: game)
    
    guard
        let teamAOffensiveEfficiency = teamAOffensiveEfficiency,
        let teamBOffensiveEfficiency = teamBOffensiveEfficiency,
        let teamADefensiveEfficiency = teamADefensiveEfficiency,
        let teamBDefensiveEfficiency = teamBDefensiveEfficiency
    else { return false }
    
    return (teamAOffensiveEfficiency < teamBOffensiveEfficiency && teamADefensiveEfficiency < teamBDefensiveEfficiency)
        || (teamBOffensiveEfficiency < teamAOffensiveEfficiency && teamBDefensiveEfficiency < teamADefensiveEfficiency)
}

func doesHomeTeamHaveWorseOffensiveAndDefensiveEfficiency(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveEfficiency, teamBOffensiveEfficiency) = getComparisonPair(.stat(.offensiveEfficiency), for: game)
    let (teamADefensiveEfficiency, teamBDefensiveEfficiency) = getComparisonPair(.stat(.defensiveEfficiency), for: game)
    
    guard
        let teamAOffensiveEfficiency = teamAOffensiveEfficiency,
        let teamBOffensiveEfficiency = teamBOffensiveEfficiency,
        let teamADefensiveEfficiency = teamADefensiveEfficiency,
        let teamBDefensiveEfficiency = teamBDefensiveEfficiency
    else { return false }
    
    return (teamAOffensiveEfficiency < teamBOffensiveEfficiency && teamADefensiveEfficiency < teamBDefensiveEfficiency && game.1.venue.isHome)
        || (teamBOffensiveEfficiency < teamAOffensiveEfficiency && teamBDefensiveEfficiency < teamADefensiveEfficiency && game.1.venue.isAway)
}

func doesAwayTeamHaveWorseOffensiveAndDefensiveEfficiency(_ game: (String, Game)) -> Bool {
    let (teamAOffensiveEfficiency, teamBOffensiveEfficiency) = getComparisonPair(.stat(.offensiveEfficiency), for: game)
    let (teamADefensiveEfficiency, teamBDefensiveEfficiency) = getComparisonPair(.stat(.defensiveEfficiency), for: game)
    
    guard
        let teamAOffensiveEfficiency = teamAOffensiveEfficiency,
        let teamBOffensiveEfficiency = teamBOffensiveEfficiency,
        let teamADefensiveEfficiency = teamADefensiveEfficiency,
        let teamBDefensiveEfficiency = teamBDefensiveEfficiency
    else { return false }
    
    return (teamAOffensiveEfficiency < teamBOffensiveEfficiency && teamADefensiveEfficiency < teamBDefensiveEfficiency && game.1.venue.isAway)
        || (teamBOffensiveEfficiency < teamAOffensiveEfficiency && teamBDefensiveEfficiency < teamADefensiveEfficiency && game.1.venue.isHome)
}

func didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(_ game: (String, Team.PreviousGame)) -> Bool {
    let (teamAOffensiveEfficiency, teamBOffensiveEfficiency) = getComparisonPair(.stat(.offensiveEfficiency), for: game)
    let (teamADefensiveEfficiency, teamBDefensiveEfficiency) = getComparisonPair(.stat(.defensiveEfficiency), for: game)
    
    guard
        let teamAOffensiveEfficiency = teamAOffensiveEfficiency,
        let teamBOffensiveEfficiency = teamBOffensiveEfficiency,
        let teamADefensiveEfficiency = teamADefensiveEfficiency,
        let teamBDefensiveEfficiency = teamBDefensiveEfficiency
    else { return false }
    
    return (teamAOffensiveEfficiency < teamBOffensiveEfficiency && teamADefensiveEfficiency < teamBDefensiveEfficiency && game.1.didCoverSpread)
        || (teamBOffensiveEfficiency < teamAOffensiveEfficiency && teamBDefensiveEfficiency < teamADefensiveEfficiency && !game.1.didCoverSpread)
}

func getTeamNameWithWorseOffensiveAndDefensiveEfficiency(_ game: (String, Game)) -> String? {
    let (teamAOffensiveEfficiency, teamBOffensiveEfficiency) = getComparisonPair(.stat(.offensiveEfficiency), for: game)
    let (teamADefensiveEfficiency, teamBDefensiveEfficiency) = getComparisonPair(.stat(.defensiveEfficiency), for: game)
    
    guard
        let teamAOffensiveEfficiency = teamAOffensiveEfficiency,
        let teamBOffensiveEfficiency = teamBOffensiveEfficiency,
        let teamADefensiveEfficiency = teamADefensiveEfficiency,
        let teamBDefensiveEfficiency = teamBDefensiveEfficiency
    else { return nil }
    
    if teamAOffensiveEfficiency < teamBOffensiveEfficiency && teamADefensiveEfficiency < teamBDefensiveEfficiency {
        return game.0
    } else if teamBOffensiveEfficiency < teamAOffensiveEfficiency && teamBDefensiveEfficiency < teamADefensiveEfficiency {
        return game.1.opponentID
    } else {
        return nil
    }
}


// MARK: - National Ranking Against Unranked Opponent

func doesMatchupHaveOneNationallyRankedAndOneUnrankedTeam(_ game: (String, Game)) -> Bool {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    return [teamARanking, teamBRanking].compactMap { $0 }.count == 1
}

func doesMatchupHaveOneNationallyRankedHomeTeamAndOneUnrankedTeam(_ game: (String, Game)) -> Bool {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    
    guard
        let nationallyRankedTeamIndex = [teamARanking, teamBRanking].firstIndex(where: { $0 != nil }),
        [teamARanking, teamBRanking].firstIndex(where: { $0 == nil }) != nil
    else { return false }
    
    return (nationallyRankedTeamIndex == 0 && game.1.venue.isHome) || (nationallyRankedTeamIndex == 1 && game.1.venue.isAway)
}

func doesMatchupHaveOneNationallyRankedAwayTeamAndOneUnrankedTeam(_ game: (String, Game)) -> Bool {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    
    guard
        let nationallyRankedTeamIndex = [teamARanking, teamBRanking].firstIndex(where: { $0 != nil }),
        [teamARanking, teamBRanking].firstIndex(where: { $0 == nil }) != nil
    else { return false }
    
    return (nationallyRankedTeamIndex == 0 && game.1.venue.isAway) || (nationallyRankedTeamIndex == 1 && game.1.venue.isHome)
}

func didNationallyRankedTeamCoverSpreadOverUnrankedTeam(_ game: (String, Team.PreviousGame)) -> Bool {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    
    guard
        let nationallyRankedTeamIndex = [teamARanking, teamBRanking].firstIndex(where: { $0 != nil }),
        [teamARanking, teamBRanking].firstIndex(where: { $0 == nil }) != nil
    else { return false }
    
    return nationallyRankedTeamIndex == 0 ? game.1.didCoverSpread : !game.1.didCoverSpread
}

func getNationallyRankedTeamName(_ game: (String, Game)) -> String? {
    let (teamARanking, teamBRanking) = getComparisonPair(.record(.nationalRanking), for: game)
    
    guard
        let nationallyRankedTeamIndex = [teamARanking, teamBRanking].firstIndex(where: { $0 != nil }),
        [teamARanking, teamBRanking].firstIndex(where: { $0 == nil }) != nil
    else { return nil }
    
    return nationallyRankedTeamIndex == 0 ? game.0 : game.1.opponentID
}


// MARK: - Unranked Coming Off Big Loss Facing Ranked Opponent

func doesMatchupHaveOneNationallyRankedAndOneUnrankedTeamComingOffBigLoss(_ game: (String, Game)) -> Bool {
    guard
        doesMatchupHaveOneNationallyRankedAndOneUnrankedTeam(game),
        let nationallyRankedTeam = getNationallyRankedTeamName(game),
        let unrankedTeam = teams.first(where: { $0.teamID == (nationallyRankedTeam == game.0 ? game.1.opponentID : game.0) }),
        let mostRecentGame = unrankedTeam.games.previous.sorted(by: { $0.date > $1.date }).first,
        !mostRecentGame.didWin
    else { return false }
    
    return abs(mostRecentGame.score.fullTime.teamPoints - mostRecentGame.score.fullTime.teamPoints) > 15
}

func doesMatchupHaveOneNationallyRankedAndOneUnrankedHomeTeamComingOffBigLoss(_ game: (String, Game)) -> Bool {
    guard
        doesMatchupHaveOneNationallyRankedAndOneUnrankedTeam(game),
        let nationallyRankedTeam = getNationallyRankedTeamName(game),
        let unrankedTeam = teams.first(where: { $0.teamID == (nationallyRankedTeam == game.0 ? game.1.opponentID : game.0) }),
        (unrankedTeam.teamID == game.0 && game.1.venue.isHome) || (unrankedTeam.teamID == game.1.opponentID && game.1.venue.isAway),
        let mostRecentGame = unrankedTeam.games.previous.sorted(by: { $0.date > $1.date }).first,
        !mostRecentGame.didWin
    else { return false }
    
    return abs(mostRecentGame.score.fullTime.teamPoints - mostRecentGame.score.fullTime.teamPoints) > 15
}

func doesMatchupHaveOneNationallyRankedAndOneUnrankedAwayTeamComingOffBigLoss(_ game: (String, Game)) -> Bool {
    guard
        doesMatchupHaveOneNationallyRankedAndOneUnrankedTeam(game),
        let nationallyRankedTeam = getNationallyRankedTeamName(game),
        let unrankedTeam = teams.first(where: { $0.teamID == (nationallyRankedTeam == game.0 ? game.1.opponentID : game.0) }),
        (unrankedTeam.teamID == game.0 && game.1.venue.isAway) || (unrankedTeam.teamID == game.1.opponentID && game.1.venue.isHome),
        let mostRecentGame = unrankedTeam.games.previous.sorted(by: { $0.date > $1.date }).first,
        !mostRecentGame.didWin
    else { return false }
    
    return abs(mostRecentGame.score.fullTime.teamPoints - mostRecentGame.score.fullTime.teamPoints) > 15
}

func getUnrankedTeamName(_ game: (String, Game)) -> String? {
    getNationallyRankedTeamName(game).flatMap { $0 == game.0 ? game.1.opponentID : game.0 }
}


// MARK: - Being In a Non-BIG Conference Facing Opponent in a BIG Conference

func doesMatchupHaveTeamInNonBIGConferenceFacingTeamInBIGConference(_ game: (String, Game)) -> Bool {
    let isTeamAInBigConference = teams.first { $0.teamID == game.0 }?.isInBIGConference ?? false
    let isTeamBInBigConference = teams.first { $0.teamID == game.1.opponentID }?.isInBIGConference ?? false
    
    return (isTeamAInBigConference && !isTeamBInBigConference) || (!isTeamAInBigConference && isTeamBInBigConference)
}

func doesMatchupHaveAHomeTeamInNonBIGConferenceFacingTeamInBIGConference(_ game: (String, Game)) -> Bool {
    let isTeamAInBigConference = teams.first { $0.teamID == game.0 }?.isInBIGConference ?? false
    let isTeamBInBigConference = teams.first { $0.teamID == game.1.opponentID }?.isInBIGConference ?? false
    
    return (isTeamAInBigConference && !isTeamBInBigConference && game.1.venue.isAway)
        || (!isTeamAInBigConference && isTeamBInBigConference && game.1.venue.isHome)
}

func doesMatchupHaveAnAwayTeamInNonBIGConferenceFacingTeamInBIGConference(_ game: (String, Game)) -> Bool {
    let isTeamAInBigConference = teams.first { $0.teamID == game.0 }?.isInBIGConference ?? false
    let isTeamBInBigConference = teams.first { $0.teamID == game.1.opponentID }?.isInBIGConference ?? false
    
    return (isTeamAInBigConference && !isTeamBInBigConference && game.1.venue.isHome)
        || (!isTeamAInBigConference && isTeamBInBigConference && game.1.venue.isAway)
}

func didTeamInNonBIGConferenceCoverSpreadAgainstOpponentInBIGConference(_ game: (String, Team.PreviousGame)) -> Bool {
    let isTeamAInBigConference = teams.first { $0.teamID == game.0 }?.isInBIGConference ?? false
    let isTeamBInBigConference = teams.first { $0.teamID == game.1.opponentID }?.isInBIGConference ?? false
    
    return (isTeamAInBigConference && !isTeamBInBigConference && !game.1.didCoverSpread)
        || (!isTeamAInBigConference && isTeamBInBigConference && game.1.didCoverSpread)
}

func getNameOfTeamInNonBIGConference(_ game: (String, Game)) -> String? {
    let isTeamAInBigConference = teams.first { $0.teamID == game.0 }?.isInBIGConference ?? false
    let isTeamBInBigConference = teams.first { $0.teamID == game.1.opponentID }?.isInBIGConference ?? false
    
    if isTeamAInBigConference && !isTeamBInBigConference {
        return game.1.opponentID
    } else if !isTeamAInBigConference && isTeamBInBigConference {
        return game.0
    } else {
        return nil
    }
}


// MARK: - Being In a BIG Conference Facing Opponent in a Non-BIG Conference

func doesMatchupHaveAHomeTeamInABIGConferenceFacingTeamInANonBIGConference(_ game: (String, Game)) -> Bool {
    let isTeamAInBigConference = teams.first { $0.teamID == game.0 }?.isInBIGConference ?? false
    let isTeamBInBigConference = teams.first { $0.teamID == game.1.opponentID }?.isInBIGConference ?? false
    
    return (isTeamAInBigConference && !isTeamBInBigConference && game.1.venue.isHome)
        || (!isTeamAInBigConference && isTeamBInBigConference && game.1.venue.isAway)
}

func doesMatchupHaveAnAwayTeamInABIGConferenceFacingTeamInNonBIGConference(_ game: (String, Game)) -> Bool {
    let isTeamAInBigConference = teams.first { $0.teamID == game.0 }?.isInBIGConference ?? false
    let isTeamBInBigConference = teams.first { $0.teamID == game.1.opponentID }?.isInBIGConference ?? false
    
    return (isTeamAInBigConference && !isTeamBInBigConference && game.1.venue.isAway)
        || (!isTeamAInBigConference && isTeamBInBigConference && game.1.venue.isHome)
}

func getNameOfTeamInBIGConference(_ game: (String, Game)) -> String? {
    getNameOfTeamInNonBIGConference(game).flatMap { $0 == game.0 ? game.1.opponentID : game.0 }
}


// MARK: - Home/Road Record Comparisons

func doesMatchupHaveAnAwayTeamWithGoodRoadRecordAndHomeTeamWithBadHomeRecord(_ game: (String, Game)) -> Bool {
    let homeTeamID = game.1.venue.isHome ? game.0 : game.1.opponentID
    let awayTeamID = game.1.venue.isHome ? game.1.opponentID : game.0
    let homeTeamRecord = teams.first { $0.teamID == homeTeamID }!.getRecord(beforeDate: game.1.date, isHome: true)
    let awayTeamRecord = teams.first { $0.teamID == awayTeamID }!.getRecord(beforeDate: game.1.date, isHome: false)
    return awayTeamRecord.overallPercentage >= 0.6 && homeTeamRecord.overallPercentage < 0.5
}

func doesMatchupHaveAHomeTeamWithGoodHomeRecordAndAwayTeamWithBadRoadRecord(_ game: (String, Game)) -> Bool {
    let homeTeamID = game.1.venue.isHome ? game.0 : game.1.opponentID
    let awayTeamID = game.1.venue.isHome ? game.1.opponentID : game.0
    let homeTeamRecord = teams.first { $0.teamID == homeTeamID }!.getRecord(beforeDate: game.1.date, isHome: true)
    let awayTeamRecord = teams.first { $0.teamID == awayTeamID }!.getRecord(beforeDate: game.1.date, isHome: false)
    return awayTeamRecord.overallPercentage < 0.5 && homeTeamRecord.overallPercentage >= 0.6
}

func areRoadRecordsNonEqual(_ game: (String, Game)) -> Bool {
    let (teamARecord, teamBRecord) = getComparisonPair(.record(.road), for: game)
    return teamARecord != teamBRecord
}

func didTeamWithBetterRoadRecordCoverSpread(_ game: (String, Team.PreviousGame)) -> Bool {
    let (teamARecord, teamBRecord) = getComparisonPair(.record(.road), for: game)
    
    return (teamARecord! > teamBRecord! && game.1.didCoverSpread)
        || (teamBRecord! > teamARecord! && !game.1.didCoverSpread)
}

func getTeamNameWithBetterRoadRecord(_ game: (String, Game)) -> String? {
    let (teamARecord, teamBRecord) = getComparisonPair(.record(.road), for: game)
    
    if teamARecord! > teamBRecord! {
        return game.0
    } else if teamBRecord! > teamARecord! {
        return game.1.opponentID
    } else {
        return nil
    }
}
