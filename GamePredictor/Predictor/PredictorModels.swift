//
//  PredictorModels.swift
//  GamePredictor
//
//  Created by Justin on 1/5/23.
//

import Foundation

struct CodableRoundRobin: Codable {
    let betslips: [Betslips]
    let originalBetslip: [String]
    
    struct Betslips: Codable {
        let pickName: String
        let picks: [String]
    }
    
}
