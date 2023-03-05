//
//  main.swift
//  GamePredictor
//
//  Created by Justin on 12/14/22.
//

import Foundation

if CommandLine.arguments.contains("-h") || CommandLine.arguments.contains("--help") {
    print("""
          GamePredictor requires you to specify the league to predict as \"-l [league_name]\" or \"--league [league_name]\"
              - league_name needs to be one of the following values (not case-sensitive): \"NBA\", \"NCAAM\", \"NCAAW\"
          
          Optional flags you can pass to customize predictor behavior are as follows:\n\
              [-d, --disable_update]:                Does not pull the latest data on the teams and predicts using the latest downloaded data.
              [-t, --training_mode]:                 Update category weights based on incorrect predictions, and print out prediction accuracy.
              [-v, --verbose]:                       Prints verbose output predictor activity
              [-r, --enable-inverted-round-robin]:   Produces an Inverted Round Robin file with 100 combinations of spread sides based on original predictions.
              [-e, --evaluate-inverted-round-robin]: If an Inverted Round Robin was previously produced, this will cause the program to evaluate how well it did.
              [-w, --tomorrow]:                      Prints out predictions for the following day instead of the current day.
          """)
    
    exit(0)
}

guard let sportModeIndex = CommandLine.arguments.firstIndex(where: { ["-l", "--league"].contains($0) }) else {
    print("Must supply league value as -l")
    exit(8)
}

guard CommandLine.arguments.count - 1 >= sportModeIndex + 1 else {
    print("Must supply value for league (\"-l\", \"--league\") parameter")
    exit(8)
}

guard let sportModeValue = SportMode(leagueString: CommandLine.arguments[sportModeIndex + 1]) else {
    print("Invalid value for league (\"-l\", \"--league\") parameter. Valid values are \"NBA\", \"NCAAM\" and \"NCAAW\".")
    exit(34)
}

let SPORT_MODE = sportModeValue
let CURRENT_SEASON_YEAR = 2023

let DISABLE_UPDATE = CommandLine.arguments.contains("-d") || CommandLine.arguments.contains("--disable-update")
let TRAINING_MODE = CommandLine.arguments.contains("-t") || CommandLine.arguments.contains("--training-mode")
let VERBOSE_OUTPUT = CommandLine.arguments.contains("-v") || CommandLine.arguments.contains("--verbose")
let ENABLE_INVERTED_ROUND_ROBIN = CommandLine.arguments.contains("-r") || CommandLine.arguments.contains("--enable-inverted-round-robin")
let IRR_EVALUATION_MODE = CommandLine.arguments.contains("-e") || CommandLine.arguments.contains("--evaluate-inverted-round-robin")
let TOMORROW = CommandLine.arguments.contains("-w") || CommandLine.arguments.contains("--tomorrow")

print("Predicting \(SPORT_MODE.league)...\n")
sleep(2)

let teamURLs = getTeamURLs()
var teams = getAllTeams(from: teamURLs)

let nationalRankings = getNationalRankingsIfNeeded()
let bettingMatchups = getBettingMatchups(from: teams)
var categories = getCategories()

var codableCategories = [CodableCategory]()
codableCategories = getCodableCategories(categories: categories)
updateCategoryWeights()

if TRAINING_MODE {
    let predictionAccuracy = trainModel(categories: categories, bettingMatchups: bettingMatchups)
    print("\(SPORT_MODE.league) Overall Prediction Accuracy: \(predictionAccuracy)%")

    [(-7, "Week"), (-2, "Two Days"), (-1, "Day")].forEach {
        let recentDate = Calendar(identifier: .iso8601).date(byAdding: .day, value: $0.0, to: Date())!
        let recentMatchups = bettingMatchups.filter { $0.1.date >= recentDate }
        let recentPredictionAccuracy = trainModel(categories: categories, bettingMatchups: recentMatchups)
        print("\n\(SPORT_MODE.league) Last \($0.1) Prediction Accuracy: \(recentPredictionAccuracy)%\n")
    }
}

let upcomingPredictions = getUpcomingPredictions(tomorrow: TOMORROW)
exportUpcomingPredictions(upcomingPredictions, tomorrow: TOMORROW)

if ENABLE_INVERTED_ROUND_ROBIN {
    if !IRR_EVALUATION_MODE {
        let todaysMatchups = getUpcomingMatchups(from: teams, tomorrow: TOMORROW)
        let invertedRoundRobin = getInvertedRoundRobin(of: todaysMatchups,
                                                       numberOfBets: 100,
                                                       outputOrder: [],
                                                       excludeList: [],
                                                       locks: [])

        exportInvertedRoundRobin(invertedRoundRobin)
    } else {
        evaluateCurrentInvertedRoundRobin(results: [])
    }
}

print("") // always blank space at end of output
