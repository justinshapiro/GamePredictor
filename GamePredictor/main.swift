//
//  main.swift
//  GamePredictor
//
//  Created by Justin on 12/14/22.
//

import Foundation

let CURRENT_SEASON_YEAR = 2023

let DISABLE_UPDATE = false
let TRAINING_MODE = false
let VERBOSE_OUTPUT = true
let ENABLE_INVERTED_ROUND_ROBIN = false
let IRR_EVALUATION_MODE = false

let teamURLs = getTeamURLs()
var teams = getAllTeams(from: teamURLs)
let nationalRankings = getNationalRankings()

let bettingMatchups = getBettingMatchups(from: teams)
var categories = getCategories()

var codableCategories = [CodableCategory]()
codableCategories = getCodableCategories(categories: categories)
updateCategoryWeights()

if TRAINING_MODE {
    let predictionAccuracy = trainModel(categories: categories, bettingMatchups: bettingMatchups)
    print("Overall Prediction Accuracy: \(predictionAccuracy)%")

    let recentDate = Calendar(identifier: .iso8601).date(byAdding: .day, value: -2, to: Date())!
    let recentMatchups = bettingMatchups.filter { $0.1.date >= recentDate }
    let recentPredictionAccuracy = trainModel(categories: categories, bettingMatchups: recentMatchups)
    print("\nRecent Prediction Accuracy: \(recentPredictionAccuracy)%\n")
}

let upcomingPredictions = getUpcomingPredictions(tomorrow: false)

print("\nUpcoming Predictions:")
upcomingPredictions
    .map { "\($0.0): \($0.1)% confidence" }
    .removeDuplicates()
    .forEach { print($0) }

if ENABLE_INVERTED_ROUND_ROBIN {
    if !IRR_EVALUATION_MODE {
        let todaysMatchups = getUpcomingMatchups(from: teams, tomorrow: false)
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
