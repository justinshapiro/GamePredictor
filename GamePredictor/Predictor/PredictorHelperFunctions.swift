//
//  PredictorHelperFunctions.swift
//  GamePredictor
//
//  Created by Justin on 1/5/23.
//

import Foundation

// MARK: - Get Unique Matchups (Previous and Upcoming)

func getBettingMatchups(from teams: [Team]) -> [(String, Team.PreviousGame)] {
    let matchupsFileName = "bettingMatchups.json"
    
    if let codableBettingMatchups: [CodableBettingMatchup] = FileManager.default.getDecodedFileIfExists(fileName: matchupsFileName, todayOnly: true) {
        return codableBettingMatchups.map { ($0.teamName, $0.game) }
    }
    
    if VERBOSE_OUTPUT {
        print("\nProducing betting matchups...")
    }
    
    let matchups = teams.flatMap { team in team.games.previous.map { (team.teamID, $0) } }
    var bettingMatchups = [(String, Team.PreviousGame)]()

    for matchup in matchups {
        guard matchup.1.line != nil else { continue }
        
        let isMatchupAccountedFor = bettingMatchups.contains { bettingMatchup in
            guard Calendar.current.isDate(bettingMatchup.1.date, inSameDayAs: matchup.1.date) else { return false }
            
            let teamsPlaying = [bettingMatchup.0, bettingMatchup.1.opponentID]
            return teamsPlaying.contains(matchup.0) && teamsPlaying.contains(matchup.1.opponentID)
        }
        
        if isMatchupAccountedFor {
            continue
        } else {
            bettingMatchups.append(patchPossibleDefectsInTeamID(matchup))
        }
    }
    
    bettingMatchups
        .map { CodableBettingMatchup(teamName: $0.0, game: $0.1) }
        .export(as: matchupsFileName)
    
    return bettingMatchups
}

func getUpcomingMatchups(from teams: [Team], tomorrow: Bool) -> [(String, Team.UpcomingGame)] {
    if VERBOSE_OUTPUT {
        print("\nProducing \(tomorrow ? "tomorrow's" : "today's") matchups...")
    }
    
    let matchups = teams.flatMap { team in team.games.upcoming.map { (team.teamID, $0) } }
    let teamIDs = teams.map { $0.teamID }
    
    var upcomingMatchups = [(String, Team.UpcomingGame)]()

    for matchup in matchups {
        let isCorrectDay = tomorrow ? Calendar.current.isDateInTomorrow(matchup.1.date) : Calendar.current.isDateInToday(matchup.1.date)
        let isCorrectForEvaluationMode = IRR_EVALUATION_MODE ? true : matchup.1.date > Date.now
        
        guard isCorrectDay && isCorrectForEvaluationMode && teamIDs.contains(matchup.1.opponentID) && teamIDs.contains(matchup.0) else {
            continue
        }
        
        let isMatchupAccountedFor = bettingMatchups.contains { bettingMatchup in
            guard Calendar.current.isDate(bettingMatchup.1.date, inSameDayAs: matchup.1.date) else { return false }
            
            let teamsPlaying = [bettingMatchup.0, bettingMatchup.1.opponentID]
            return teamsPlaying.contains(matchup.0) && teamsPlaying.contains(matchup.1.opponentID)
        }
        
        if isMatchupAccountedFor {
            continue
        } else {
            upcomingMatchups.append(patchPossibleDefectsInTeamID(matchup))
        }
    }
    
    return upcomingMatchups
}

// sometimes ESPN may change the team IDs when a new team is added
// this function will just enumerate manually all known cases
func patchPossibleDefectsInTeamID<T: Game>(_ matchup: (String, T)) -> (String, T) {
    let knownDefects = [
        ("MTU", "MTSU")
    ]
    
    for defect in knownDefects {
        if matchup.0 == defect.0 {
            return (defect.1, matchup.1)
        } else if matchup.1.opponentID == defect.0 {
            var newGame = matchup.1
            newGame.opponentID = defect.1
            
            return (matchup.0, newGame)
        }
    }
    
    return matchup
}


// MARK: - Spread Prediction

func predictTeamToCoverSpread(game: (String, Game), categories: [Category], matchedCategories: inout [String: Int]) -> (String, Double) {
    var teamToCoverSpread = game.0
    var finalRanking = 0.0
    
    let matchingCategories = categories.reduce([String: [Double]]()) { previous, current in
        guard current.isMember(game), let teamID = current.designatedTeam(game) else {
            return previous
        }
        
        if matchedCategories.keys.contains(current.name) {
            matchedCategories[current.name]! += 1
        } else {
            matchedCategories[current.name] = 1
        }
        
        var newPrevious = previous
        
        if newPrevious.keys.contains(teamID) {
            newPrevious[teamID]! += [Double(current.rating) * current.weight]
        } else {
            newPrevious[teamID] = [Double(current.rating) * current.weight]
        }
        
        return newPrevious
    }
    
    let teamARanking = matchingCategories[game.0].flatMap { Double($0.reduce(0, +)) / Double($0.count) } ?? 0
    let teamBRanking = matchingCategories[game.1.opponentID].flatMap { Double($0.reduce(0, +)) / Double($0.count) } ?? 0
    
    if teamARanking > teamBRanking {
        teamToCoverSpread = game.0
        finalRanking = teamARanking
    } else if teamBRanking > teamARanking {
        teamToCoverSpread = game.1.opponentID
        finalRanking = teamBRanking
    } else {
        teamToCoverSpread = game.1.venue.isHome ? game.0 : game.1.opponentID
        finalRanking = 50
    }
    
    return (teamToCoverSpread, finalRanking)
}

func trainModel(categories: [Category], bettingMatchups: [(String, Team.PreviousGame)]) -> Int {
    print("\nMeasuring prediction accuracy...")
    
    var matchedCategories = [String: Int]()
    
    let results: [Bool] = bettingMatchups.enumerated().map { index, game in
        let teamToCoverSpread = predictTeamToCoverSpread(game: game, categories: categories, matchedCategories: &matchedCategories).0
        
        if game.0 == teamToCoverSpread && game.1.didCoverSpread {
            if VERBOSE_OUTPUT {
                print("""
                      (\(index) of \(bettingMatchups.count)) ✅: \(game.0) vs. \(game.1.opponentID) on \(dateFormatter.string(from: game.1.date)) \
                      | (Result: \(game.0) \(game.1.line ?? 0))
                      """)
            }
            
            return true
        } else if game.1.opponentID == teamToCoverSpread && !game.1.didCoverSpread {
            if VERBOSE_OUTPUT {
                print("""
                      (\(index) of \(bettingMatchups.count)) ✅: \(game.0) vs. \(game.1.opponentID) on \(dateFormatter.string(from: game.1.date)) \
                      | (Result: \(game.1.opponentID) \(game.1.line ?? 0))
                      """)
            }
            
            return true
        } else {
            if VERBOSE_OUTPUT {
                print("""
                      (\(index) of \(bettingMatchups.count)) ❌: \(game.0) vs. \(game.1.opponentID) on \(dateFormatter.string(from: game.1.date)) \
                      | (Result: \(teamToCoverSpread == game.1.opponentID ? game.0 : game.1.opponentID) \(game.1.line ?? 0))
                      """)
            }
            
            return false
        }
    }
    
    /* // Uncomment to print out info on used categories
    print("\nCategory matchings:\n")
    
    matchedCategories.map { ($0.key, $0.value) }.sorted { $0.1 > $1.1 }.forEach {
        print("\($0.0): \($0.1)")
    }*/
    
    return Int((Double(results.filter { $0 }.count) / Double(bettingMatchups.count)) * 100)
}

func getUpcomingPredictions(tomorrow: Bool) -> [(String, Double)] {
    getUpcomingMatchups(from: teams, tomorrow: tomorrow)
        .lazy
        .map {
            var matchedCategories = [String: Int]()
            let prediction = predictTeamToCoverSpread(game: $0, categories: categories, matchedCategories: &matchedCategories)
            return (prediction.0, prediction.1)
        }
        .sorted { $0.1 > $1.1 }
}

func exportUpcomingPredictions(_ upcomingPredictions: [(String, Double)], tomorrow: Bool) {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "MM-dd"
    
    let dateString = dateFormatter.string(from: tomorrow ? (Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now) : .now)
    
    guard !upcomingPredictions.isEmpty else {
        dateFormatter.dateFormat = "MM/dd"
        return print("\n\(SPORT_MODE.league) No upcoming predictions for \(dateString)")
    }
    
    print("\n\(SPORT_MODE.league) Upcoming Predictions:")
    
    let exportableUpcomingPredictions = upcomingPredictions
        .map { Prediction(teamToCoverSpread: $0.0, probabilityPercentage: $0.1) }
        .removeDuplicates()
    
    exportableUpcomingPredictions.forEach { print($0.printString) }
    
    let fileName = "predictions-\(dateString).json"
    exportableUpcomingPredictions.export(as: fileName)
}

func isCorrectPrediction(game: (String, Team.PreviousGame), teamToCoverSpread: String) -> Bool {
    (game.0 == teamToCoverSpread && game.1.didCoverSpread) || (game.1.opponentID == teamToCoverSpread && !game.1.didCoverSpread)
}


// MARK: - Inverted Round Robin

func getInvertedRoundRobin(of upcomingGames: [(String, Team.UpcomingGame)], numberOfBets: Int, outputOrder: [String], excludeList: [String], locks: [String]) -> CodableRoundRobin {
    print("\nProducing Inverted Round Robin...\n")
    
    let predictionSortedByRanking: [(String, Int)] = upcomingGames
        .lazy
        .compactMap {
            if excludeList.contains($0.0) || excludeList.contains($0.1.opponentID) {
                return nil
            }
            
            var matchedCategories = [String: Int]()
            let prediction = predictTeamToCoverSpread(game: $0, categories: categories, matchedCategories: &matchedCategories)
            return (prediction.0, Int(prediction.1))
        }
        .sorted { $0.1 > $1.1 }
    
    let predictionsTeamsOnly: [String] = predictionSortedByRanking.map { $0.0 }
    let basePredictions: [String] = Array<String>(predictionsTeamsOnly.removeDuplicates().prefix(20))
    
    let predictionsRow = [[String]](repeating: basePredictions, count: 10)
    var predictionsTable = [[[String]]](repeating: predictionsRow, count: numberOfBets / 10)
    
    let flipPatterns = getFlipPatterns(forBetslipOfCount: basePredictions.count)
    
    for (index, column) in predictionsTable.enumerated() {
        var currentColumn = column
        
        for (betIndex, betslip) in column.enumerated() {
            var flippedBetslip = betslip
            
            if !(index == 0 && betIndex == 0) {
                repeat {
                    let flipPattern = flipPatterns[Int.random(in: 0..<flipPatterns.count)]
                    var newBetslip = Array(betslip.reversed())
                    newBetslip.enumerated().forEach { newBetslip[$0] = flipPattern[$0] ? "not \($1)" : $1 }
                    
                    flippedBetslip = Array(newBetslip.reversed())
                } while predictionsTable.flatMap({ $0 }).contains(flippedBetslip)
            }
            
            if !outputOrder.isEmpty {
                flippedBetslip = flippedBetslip.sorted(using: outputOrder)
            }
            
            currentColumn[betIndex] = flippedBetslip
        }
        
        predictionsTable[index] = currentColumn
    }
    
    let codableBetslips: [CodableRoundRobin.Betslips] = predictionsTable
        .flatMap { $0 }
        .enumerated()
        .map { index, picks in
            CodableRoundRobin.Betslips(pickName: "Betslip #\(index + 1)", picks: picks)
        }
    
    return CodableRoundRobin(betslips: codableBetslips, originalBetslip: basePredictions)
}

func exportInvertedRoundRobin(_ invertedRoundRobin: CodableRoundRobin) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    
    print("\nToday's Inverted Roundrobin:\n")
    
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "MM-dd"
    
    let fileName = "invertedRoundRobin-\(dateFormatter.string(from: .now)).json"
    invertedRoundRobin.export(as: fileName)
    
    print(String(data: try! encoder.encode(invertedRoundRobin), encoding: .utf8)!)
    print("\nSuccessful exported today's inverted round robin as \(fileName)")
}

func evaluateCurrentInvertedRoundRobin(results: [String]) {
    print("\nEvaluation of today's inverted round robin:\n")
    
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "MM-dd"
    
    let matchupsFileName = "invertedRoundRobin-\(dateFormatter.string(from: .now)).json"
    
    guard let codableRoundRobin: CodableRoundRobin = FileManager.default.getDecodedFileIfExists(fileName: matchupsFileName, todayOnly: false) else {
        fatalError("No file found for today's evaluation or file couldn't be decoded")
    }
    
    let codableRoundRobins = codableRoundRobin.betslips.map { $0.picks }
    
    let todaysResults = results
        .sorted(using: codableRoundRobins.first!)
        .reversed()

    let bestResult: (Int, Int) = codableRoundRobins
        .enumerated()
        .map { index, matches in
            (index + 1, todaysResults.compactMap { matches.contains($0) ? $0 : nil }.count)
        }
        .sorted { $0.1 > $1.1 }
        .first!

    print("Best result: Betslip #\(bestResult.0) with \(bestResult.1) out of \(todaysResults.count) chosen correctly")
    
    let winningFlipPattern = Array(todaysResults)
        .sorted(using: codableRoundRobin.originalBetslip)
        .reversed()
        .map { $0.contains("not ") }
    
    let allFlipPatterns = getFlipPatterns(forBetslipOfCount: results.count)
    let indexOfWinningFlipPattern = allFlipPatterns.firstIndex(of: winningFlipPattern)!
    
    print("Winning Flip Pattern is #\(indexOfWinningFlipPattern) of \(allFlipPatterns.count) for a \(results.count) pick betslip")
}


// MARK: - Flip Patterns

func getFlipPatterns(forBetslipOfCount count: Int) -> [[Bool]] {
    let flipPatternsFileName = "flipPatterns-\(count).json"
    
    if let flipPatterns: [[Bool]] = FileManager.default.getDecodedFileIfExists(fileName: flipPatternsFileName, todayOnly: false) {
        return flipPatterns
    }
    
    if VERBOSE_OUTPUT {
        print("Producing flip pattern file for betslip with \(count) picks...")
    }
    
    var allPossibleFlipPatterns = [[Bool]]()
    
    (0..<(2 << count)).forEach { index in
        var flipPattern = (0..<count).map { _ in Int.random(in: 0...1) != 0 }
        
        let startDate = Date.now
        
        repeat {
            flipPattern = (0..<count).map { _ in Int.random(in: 0...1) != 0 }
        } while allPossibleFlipPatterns.contains(flipPattern)
        
        if VERBOSE_OUTPUT {
            print("Produced flip pattern #\(index) in \(Date.now.timeIntervalSince(startDate)) seconds")
        }
        
        allPossibleFlipPatterns.append(flipPattern)
    }
    
    allPossibleFlipPatterns.export(as: flipPatternsFileName)
    
    return allPossibleFlipPatterns
}
