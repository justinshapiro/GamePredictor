//
//  PredictorModels.swift
//  GamePredictor
//
//  Created by Justin on 1/5/23.
//

import Foundation

struct CodableBettingMatchup: Codable {
    let teamName: String
    let game: Team.PreviousGame
}

struct CodableRoundRobin: Codable {
    let betslips: [Betslips]
    let originalBetslip: [String]
    
    struct Betslips: Codable {
        let pickName: String
        let picks: [String]
    }
    
}

struct Prediction: Codable, Equatable {
    let teamToCoverSpread: String
    let probabilityPercentage: Double
    
    var printString: String {
        "\(teamToCoverSpread): \(probabilityPercentage)% confidence"
    }
}
