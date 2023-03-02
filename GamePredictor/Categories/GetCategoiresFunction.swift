//
//  GetCategoiresFunction.swift
//  GamePredictor
//
//  Created by Justin on 1/4/23.
//

import Foundation

// TODO: Then find which categories are most common in wrongly predicted games and figure out how to tweak them (does removing those improve overall prediction accuracy?, do they need weights?, weights based on number of samples?)

func getCategories() -> [Category] {
    print("\nGenerating categories...")
    
    var categoryGroups: [[Category]] = [
        getCategoryGroup(baseName: "More Offensive Rebounds Against Teams With Less Defensive Rebounds",
                         generalSize: doesMatchupHaveATeamWithMoreOffensiveReboundsAndDefensiveRebounds,
                         homeSize: doesMatchupHaveAHomeTeamWithMoreOffensiveReboundsAndDefensiveRebounds,
                         awaySize: doesMatchupHaveAnAwayTeamWithMoreOffensiveReboundsAndDefensiveRebounds,
                         generalDidMatch: didTeamWithMoreOffensiveAndDefensiveReboundsCoverTheSpread,
                         generalDesignatedTeam: getTeamNameWithMoreOffensiveAndDefensiveRebounds),
        
        getCategoryGroup(baseName: "Less Offensive Rebounds Against Teams With More Defensive Rebounds",
                         generalSize: doesMatchupHaveATeamWithLessOffensiveReboundsAndDefensiveRebounds,
                         homeSize: doesMatchupHaveAHomeTeamWithLessOffensiveReboundsAndDefensiveRebounds,
                         awaySize: doesMatchupHaveAnAwayTeamWithLessOffensiveReboundsAndDefensiveRebounds,
                         generalDidMatch: didTeamWithLessOffensiveAndDefensiveReboundsCoverTheSpread,
                         generalDesignatedTeam: getTeamNameWithLessOffensiveAndDefensiveRebounds),
        
        getCategoryGroup(baseName: "More Steals Against Team With More Turnovers",
                         generalSize: doesMatchupHaveATeamWithMoreStealsAndLessTurnovers,
                         homeSize: doesMatchupHaveAHomeTeamWithMoreStealsAndLessTurnovers,
                         awaySize: doesMatchupHaveAnAwayTeamWithMoreStealsAndLessTurnovers,
                         generalDidMatch: didTeamWithMoreStealsAndLessTurnoversCoverSpread,
                         generalDesignatedTeam: getTeamNameWithMoreStealsAndLessTurnovers),
        
        getCategoryGroup(baseName: "Less Steals Against Team With Less Turnovers",
                         generalSize: doesMatchupHaveATeamWithLessStealsAndMoreTurnovers,
                         homeSize: doesMatchupHaveAHomeTeamWithLessStealsAndMoreTurnovers,
                         awaySize: doesMatchupHaveAnAwayTeamWithLessStealsAndMoreTurnovers,
                         generalDidMatch: didTeamWithLessStealsAndMoreTurnoversCoverSpread,
                         generalDesignatedTeam: getTeamNameWithLessStealsAndMoreTurnovers),
        
        getCategoryGroup(baseName: "Better Offensive And Defensive Efficiency",
                         generalSize: doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency,
                         homeSize: { doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency($0) && doesHomeTeamHaveBetterOffensiveAndDefensiveEfficiency($0) },
                         awaySize: { doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency($0) && doesAwayTeamHaveBetterOffensiveAndDefensiveEfficiency($0) },
                         generalDidMatch: didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread,
                         generalDesignatedTeam: getTeamNameWithBetterOffensiveAndDefensiveEfficiency),
        
        getCategoryGroup(baseName: "Worse Offensive And Defensive Efficiency",
                         generalSize: doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency,
                         homeSize: { doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency($0) && doesHomeTeamHaveWorseOffensiveAndDefensiveEfficiency($0) },
                         awaySize: { doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency($0) && doesAwayTeamHaveWorseOffensiveAndDefensiveEfficiency($0) },
                         generalDidMatch: didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread,
                         generalDesignatedTeam: getTeamNameWithWorseOffensiveAndDefensiveEfficiency),
        
        getHomeAwayCategoryGroup(baseName: "In Primetime Matchup", size: { $0.1.coverage == .standardTV }),
        getHomeAwayCategoryGroup(baseName: "In Sports TV Matchup", size: { $0.1.coverage == .sportsTV }),
        getHomeAwayCategoryGroup(baseName: "In Matchup w/ No TV Coverage", size: { $0.1.coverage == nil }),
        getHomeAwayCategoryGroup(baseName: "In Matchup w/ Any TV Coverage", size: { [.standardTV, .sportsTV].contains($0.1.coverage) }),
        
        // this just means out of all games, which home teams and away teams covered the spread
        getHomeAwayCategoryGroup(baseName: "", size: { _ in true })
    ]
    
    if SPORT_MODE.isCollege {
        let customCategoryGroups: [[Category]] = [
            getCategoryGroup(baseName: "Better National Ranking When Both Opponents Are Nationally Ranked",
                             generalSize: doesMatchupHaveTwoNationallyRankedTeams,
                             homeSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && doesHomeTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam($0) },
                             awaySize: { doesMatchupHaveTwoNationallyRankedTeams($0) && doesAwayTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam($0) },
                             generalDidMatch: didTeamWithBetterNationalRankingCoverSpread,
                             generalDesignatedTeam: getTeamNameWithBetterNationalRanking),
            
            getCategoryGroup(baseName: "Worse National Ranking When Both Opponents Are Nationally Ranked",
                             generalSize: doesMatchupHaveTwoNationallyRankedTeams,
                             homeSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && doesHomeTeamHaveWorseNationalRankingThanNationallyRankedAwayTeam($0) },
                             awaySize: { doesMatchupHaveTwoNationallyRankedTeams($0) && doesAwayTeamHaveWorseNationalRankingThanNationallyRankedAwayTeam($0) },
                             generalDidMatch: didTeamWithWorseNationalRankingCoverSpread,
                             generalDesignatedTeam: getTeamNameWithWorseNationalRanking),
            
            getCategoryGroup(baseName: "Better Offensive Efficiency When Both Opponents Are Nationally Ranked",
                             generalSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && isComparisonNonEqual(.stat(.offensiveEfficiency), for: $0) },
                             homeSize: {
                                 doesMatchupHaveTwoNationallyRankedTeams($0)
                                    && isComparisonNonEqual(.stat(.offensiveEfficiency), for: $0)
                                    && isComparisonGreaterForHomeTeam(.stat(.offensiveEfficiency), for: $0)
                             },
                             awaySize: {
                                 doesMatchupHaveTwoNationallyRankedTeams($0)
                                    && isComparisonNonEqual(.stat(.offensiveEfficiency), for: $0)
                                    && isComparisonGreaterForAwayTeam(.stat(.offensiveEfficiency), for: $0)
                             },
                             generalDidMatch: { didTeamWithGreaterComparisonCoverSpread(.stat(.offensiveEfficiency), for: $0) },
                             generalDesignatedTeam: { getTeamNameWithGreaterComparison(.stat(.offensiveEfficiency), for: $0) }),
            
            getCategoryGroup(baseName: "Worse Offensive Efficiency When Both Opponents Are Nationally Ranked",
                             generalSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && isComparisonNonEqual(.stat(.offensiveEfficiency), for: $0) },
                             homeSize: {
                                 doesMatchupHaveTwoNationallyRankedTeams($0)
                                    && isComparisonNonEqual(.stat(.offensiveEfficiency), for: $0)
                                    && isComparisonLessForHomeTeam(.stat(.offensiveEfficiency), for: $0)
                             },
                             awaySize: {
                                 doesMatchupHaveTwoNationallyRankedTeams($0)
                                    && isComparisonNonEqual(.stat(.offensiveEfficiency), for: $0)
                                    && isComparisonLessForAwayTeam(.stat(.offensiveEfficiency), for: $0)
                             },
                             generalDidMatch: { didTeamWithLesserComparisonCoverSpread(.stat(.offensiveEfficiency), for: $0) },
                             generalDesignatedTeam: { getTeamNameWithLesserComparison(.stat(.offensiveEfficiency), for: $0) }),
            
            getCategoryGroup(baseName: "Better Defensive Efficiency When Both Opponents Are Nationally Ranked",
                             generalSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && isComparisonNonEqual(.stat(.defensiveEfficiency), for: $0) },
                             homeSize: {
                                 doesMatchupHaveTwoNationallyRankedTeams($0)
                                    && isComparisonNonEqual(.stat(.defensiveEfficiency), for: $0)
                                    && isComparisonGreaterForHomeTeam(.stat(.defensiveEfficiency), for: $0)
                             },
                             awaySize: {
                                 doesMatchupHaveTwoNationallyRankedTeams($0)
                                    && isComparisonNonEqual(.stat(.defensiveEfficiency), for: $0)
                                    && isComparisonGreaterForAwayTeam(.stat(.defensiveEfficiency), for: $0)
                             },
                             generalDidMatch: { didTeamWithGreaterComparisonCoverSpread(.stat(.defensiveEfficiency), for: $0) },
                             generalDesignatedTeam: { getTeamNameWithGreaterComparison(.stat(.defensiveEfficiency), for: $0) }),
            
            getCategoryGroup(baseName: "Worse Defensive Efficiency When Both Opponents Are Nationally Ranked",
                             generalSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && isComparisonNonEqual(.stat(.defensiveEfficiency), for: $0) },
                             homeSize: {
                                 doesMatchupHaveTwoNationallyRankedTeams($0)
                                    && isComparisonNonEqual(.stat(.defensiveEfficiency), for: $0)
                                    && isComparisonLessForHomeTeam(.stat(.defensiveEfficiency), for: $0)
                             },
                             awaySize: {
                                 doesMatchupHaveTwoNationallyRankedTeams($0)
                                    && isComparisonNonEqual(.stat(.defensiveEfficiency), for: $0)
                                    && isComparisonLessForAwayTeam(.stat(.defensiveEfficiency), for: $0)
                             },
                             generalDidMatch: { didTeamWithLesserComparisonCoverSpread(.stat(.defensiveEfficiency), for: $0) },
                             generalDesignatedTeam: { getTeamNameWithLesserComparison(.stat(.defensiveEfficiency), for: $0) }),
            
            getCategoryGroup(baseName: "National Ranking Against Unranked Opponent",
                             generalSize: doesMatchupHaveOneNationallyRankedAndOneUnrankedTeam,
                             homeSize: doesMatchupHaveOneNationallyRankedHomeTeamAndOneUnrankedTeam,
                             awaySize: doesMatchupHaveOneNationallyRankedAwayTeamAndOneUnrankedTeam,
                             generalDidMatch: didNationallyRankedTeamCoverSpreadOverUnrankedTeam,
                             generalDesignatedTeam: getNationallyRankedTeamName),
            
            getCategoryGroup(baseName: "Unranked Coming Off Big Loss Facing Ranked Opponent",
                             generalSize: doesMatchupHaveOneNationallyRankedAndOneUnrankedTeamComingOffBigLoss,
                             homeSize: doesMatchupHaveOneNationallyRankedAndOneUnrankedHomeTeamComingOffBigLoss,
                             awaySize: doesMatchupHaveOneNationallyRankedAndOneUnrankedAwayTeamComingOffBigLoss,
                             generalDidMatch: { !didNationallyRankedTeamCoverSpreadOverUnrankedTeam($0) },
                             generalDesignatedTeam: getUnrankedTeamName),
            
            getCategoryGroup(baseName: "Being In a Non-BIG Conference Facing Opponent in a BIG Conference",
                             generalSize: doesMatchupHaveTeamInNonBIGConferenceFacingTeamInBIGConference,
                             homeSize: doesMatchupHaveAHomeTeamInNonBIGConferenceFacingTeamInBIGConference,
                             awaySize: doesMatchupHaveAnAwayTeamInNonBIGConferenceFacingTeamInBIGConference,
                             generalDidMatch: didTeamInNonBIGConferenceCoverSpreadAgainstOpponentInBIGConference,
                             generalDesignatedTeam: getNameOfTeamInNonBIGConference),
            
            getCategoryGroup(baseName: "Being In a BIG Conference Facing Opponent in a Non-BIG Conference",
                             generalSize: doesMatchupHaveTeamInNonBIGConferenceFacingTeamInBIGConference,
                             homeSize: doesMatchupHaveAHomeTeamInABIGConferenceFacingTeamInANonBIGConference,
                             awaySize: doesMatchupHaveAnAwayTeamInABIGConferenceFacingTeamInNonBIGConference,
                             generalDidMatch: { !didTeamInNonBIGConferenceCoverSpreadAgainstOpponentInBIGConference($0) },
                             generalDesignatedTeam: getNameOfTeamInBIGConference),
            
            getHomeAwayCategoryGroup(baseName: "Both Teams Being Nationally Ranked", size: doesMatchupHaveTwoNationallyRankedTeams),
        ]
        
        categoryGroups += customCategoryGroups
    }
    
    let allCategories: [Category] = categoryGroups.flatMap { $0 } + getCategoriesForAllComparisons() + getOneOffCategories()
    let combinedCategories = getCategoryCombinations(from: allCategories)
    
    print("Total categories: \(combinedCategories.count)")
    return combinedCategories
}

private func getOneOffCategories() -> [Category] {
    var oneOffCategories: [Category] = [
        .init(name: "Away Team Covered Spread w/ Good Road Record Against Home Team With Bad Home Record\(SPORT_MODE.isCollege ? " (Both Conference And Non-Conference Games, Non-Neutral Venues)" : "")",
              isMember: { !$0.1.venue.isNeutral && doesMatchupHaveAnAwayTeamWithGoodRoadRecordAndHomeTeamWithBadHomeRecord($0) },
              didMatch: didAwayTeamCoverTheSpread,
              designatedTeam: getAwayTeamName,
              weight: 1),
        
        .init(name: "Home Team Covered Spread w/ Good Home Record Against Away Team With Bad Road Record\(SPORT_MODE.isCollege ? " (Both Conference And Non-Conference Games, Non-Neutral Venues)" : "")",
              isMember: { !$0.1.venue.isNeutral && doesMatchupHaveAHomeTeamWithGoodHomeRecordAndAwayTeamWithBadRoadRecord($0) },
              didMatch: didHomeTeamCoverTheSpread,
              designatedTeam: getHomeTeamName,
              weight: 1),
        
            .init(name: "Away Team Covered Spread w/ Good Road Record Against Home Team With Bad Home Record\(SPORT_MODE.isCollege ? " (Conference Games, Non-Neutral Venues)": "")",
              isMember: { !$0.1.venue.isNeutral && $0.1.isConferenceMatchup && doesMatchupHaveAnAwayTeamWithGoodRoadRecordAndHomeTeamWithBadHomeRecord($0) },
              didMatch: didAwayTeamCoverTheSpread,
              designatedTeam: getAwayTeamName,
              weight: 1),
        
        .init(name: "Home Team Covered Spread w/ Good Home Record Against Away Team With Bad Road Record\(SPORT_MODE.isCollege ? " (Conference Games, Non-Neutral Venues)": "")",
              isMember: { !$0.1.venue.isNeutral && $0.1.isConferenceMatchup && doesMatchupHaveAHomeTeamWithGoodHomeRecordAndAwayTeamWithBadRoadRecord($0) },
              didMatch: didHomeTeamCoverTheSpread,
              designatedTeam: getHomeTeamName,
              weight: 1),
        
        .init(name: "Away Team Covered Spread w/ Good Road Record Against Home Team With Bad Home Record\(SPORT_MODE.isCollege ? " (Non-Conference Games, Non-Neutral Venues)": "")",
              isMember: { !$0.1.venue.isNeutral && !$0.1.isConferenceMatchup && doesMatchupHaveAnAwayTeamWithGoodRoadRecordAndHomeTeamWithBadHomeRecord($0) },
              didMatch: didAwayTeamCoverTheSpread,
              designatedTeam: getAwayTeamName,
              weight: 1),
        
        .init(name: "Home Team Covered Spread w/ Good Home Record Against Away Team With Bad Road Record\(SPORT_MODE.isCollege ? " (Non-Conference Games, Non-Neutral Venues)": "")",
              isMember: { !$0.1.venue.isNeutral && !$0.1.isConferenceMatchup && doesMatchupHaveAHomeTeamWithGoodHomeRecordAndAwayTeamWithBadRoadRecord($0) },
              didMatch: didHomeTeamCoverTheSpread,
              designatedTeam: getHomeTeamName,
              weight: 1)
    ]
    
    if SPORT_MODE.isCollege {
        oneOffCategories.append(
            .init(name: "Covered Spread w/ Better Road Record Than Opponent When In Neutral Venue (Non-Conference Games, Neutral Venues)",
                  isMember: { $0.1.venue.isNeutral && areRoadRecordsNonEqual($0) },
                  didMatch: didTeamWithBetterRoadRecordCoverSpread,
                  designatedTeam: getTeamNameWithBetterRoadRecord,
                  weight: 1)
        )
    } else {
        oneOffCategories += [
            .init(name: "Covered Spread w/ On A Back-to-Back",
                  isMember: doesMatchupHaveOnlyOneTeamOnABackToBack,
                  didMatch: didTeamOnBackToBackCoverSpread,
                  designatedTeam: getTeamNameOnABackToBack,
                  weight: 1),
            
            .init(name: "Home Team Covered Spread w/ On A Back-to-Back",
                  isMember: doesMatchupHaveHomeTeamOnABackToBack,
                  didMatch: didTeamOnBackToBackCoverSpread,
                  designatedTeam: getTeamNameOnABackToBack,
                  weight: 1),
        
            .init(name: "Away Team Covered Spread w/ On A Back-to-Back",
                  isMember: doesMatchupHaveAwayTeamOnABackToBack,
                  didMatch: didTeamOnBackToBackCoverSpread,
                  designatedTeam: getTeamNameOnABackToBack,
                  weight: 1)
        ]
    }
    
    return oneOffCategories
}

func updateCategoryWeights() {
    categories = codableCategories.compactMap { codableCategory in
        guard let category = categories.first(where: { $0.name == codableCategory.name }) else {
            return nil
        }
        
        return Category(name: category.name,
                        isMember: category.isMember,
                        didMatch: category.didMatch,
                        designatedTeam: category.designatedTeam,
                        weight: codableCategory.weight)
    }
}
