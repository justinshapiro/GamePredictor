//
//  CategoryEntries.swift
//  GamePredictor
//
//  Created by Justin on 1/4/23.
//

import Foundation

// teams with more offensive rebounds vs. teams with less defensive rebounds
// teams that make free throws more
// teams with players that have improved over the last year

// TODO: Once category management is done, finish base set of categories, then make a way to programmatically generate all combinations of base categories with other base categories
// TODO: Then find which categories are most common in wrongly predicted games and figure out how to tweak them (does removing those improve overall prediction accuracy?, do they need weights?, weights based on number of samples?)

func getCategories() -> [Category] {
    let categoryGroups: [[Category]] = [
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
                         generalSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areOffensiveEfficienciesNonEqual($0) },
                         homeSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areOffensiveEfficienciesNonEqual($0) && doesHomeTeamHaveBetterOffensiveEfficiency($0) },
                         awaySize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areOffensiveEfficienciesNonEqual($0) && doesAwayTeamHaveBetterOffensiveEfficiency($0) },
                         generalDidMatch: didTeamWithBetterOffensiveEfficiencyCoverSpread,
                         generalDesignatedTeam: getTeamNameWithBetterOffensiveEfficiency),
        
        getCategoryGroup(baseName: "Worse Offensive Efficiency When Both Opponents Are Nationally Ranked",
                         generalSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areOffensiveEfficienciesNonEqual($0) },
                         homeSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areOffensiveEfficienciesNonEqual($0) && doesHomeTeamHaveWorseOffensiveEfficiency($0) },
                         awaySize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areOffensiveEfficienciesNonEqual($0) && doesAwayTeamHaveWorseOffensiveEfficiency($0) },
                         generalDidMatch: didTeamWithWorseOffensiveEfficiencyCoverSpread,
                         generalDesignatedTeam: getTeamNameWithWorseOffensiveEfficiency),
        
        getCategoryGroup(baseName: "Better Defensive Efficiency When Both Opponents Are Nationally Ranked",
                         generalSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areDefensiveEfficienciesNonEqual($0) },
                         homeSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areDefensiveEfficienciesNonEqual($0) && doesHomeTeamHaveBetterDefensiveEfficiency($0) },
                         awaySize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areDefensiveEfficienciesNonEqual($0) && doesAwayTeamHaveBetterDefensiveEfficiency($0) },
                         generalDidMatch: didTeamWithBetterDefensiveEfficiencyCoverSpread,
                         generalDesignatedTeam: getTeamNameWithBetterDefensiveEfficiency),
        
        getCategoryGroup(baseName: "Worse Defensive Efficiency When Both Opponents Are Nationally Ranked",
                         generalSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areDefensiveEfficienciesNonEqual($0) },
                         homeSize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areDefensiveEfficienciesNonEqual($0) && doesHomeTeamHaveWorseDefensiveEfficiency($0) },
                         awaySize: { doesMatchupHaveTwoNationallyRankedTeams($0) && areDefensiveEfficienciesNonEqual($0) && doesAwayTeamHaveWorseDefensiveEfficiency($0) },
                         generalDidMatch: didTeamWithWorseDefensiveEfficiencyCoverSpread,
                         generalDesignatedTeam: getTeamNameWithWorseDefensiveEfficiency),
        
        getCategoryGroup(baseName: "National Ranking Against Unranked Opponent",
                         generalSize: doesMatchupHaveOneNationallyRankedAndOneUnrankedTeam,
                         homeSize: doesMatchupHaveOneNationallyRankedHomeTeamAndOneUnrankedTeam,
                         awaySize: doesMatchupHaveOneNationallyRankedAwayTeamAndOneUnrankedTeam,
                         generalDidMatch: didNationallyRankedTeamCoverSpreadOverUnrankedTeam,
                         generalDesignatedTeam: getNationallyRankedTeamName),
        
        getCategoryGroup(baseName: "Better Offensive Efficiency",
                         generalSize: areOffensiveEfficienciesNonEqual,
                         homeSize: { areOffensiveEfficienciesNonEqual($0) && doesHomeTeamHaveBetterOffensiveEfficiency($0) },
                         awaySize: { areOffensiveEfficienciesNonEqual($0) && doesAwayTeamHaveBetterOffensiveEfficiency($0) },
                         generalDidMatch: didTeamWithBetterOffensiveEfficiencyCoverSpread,
                         generalDesignatedTeam: getTeamNameWithBetterOffensiveEfficiency),
        
        getCategoryGroup(baseName: "Worse Offensive Efficiency",
                         generalSize: areOffensiveEfficienciesNonEqual,
                         homeSize: { areOffensiveEfficienciesNonEqual($0) && doesHomeTeamHaveWorseOffensiveEfficiency($0) },
                         awaySize: { areOffensiveEfficienciesNonEqual($0) && doesAwayTeamHaveWorseOffensiveEfficiency($0) },
                         generalDidMatch: didTeamWithWorseOffensiveEfficiencyCoverSpread,
                         generalDesignatedTeam: getTeamNameWithWorseOffensiveEfficiency),
        
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
        
        getCategoryGroup(baseName: "Better Record Than Opponent",
                         generalSize: areTeamRecordsNonEqual,
                         homeSize: doesHomeTeamHaveBetterRecord,
                         awaySize: doesAwayTeamHaveBetterRecord,
                         generalDidMatch: didTeamWithBetterRecordCoverSpread,
                         generalDesignatedTeam: getTeamNameWithBetterRecord),
        
        getCategoryGroup(baseName: "Worse Record Than Opponent",
                         generalSize: areTeamRecordsNonEqual,
                         homeSize: doesHomeTeamHaveWorseRecord,
                         awaySize: doesAwayTeamHaveWorseRecord,
                         generalDidMatch: didTeamWithWorseRecordCoverSpread,
                         generalDesignatedTeam: getTeamNameWithWorseRecord),
        
        getCategoryGroup(baseName: "Better Conference Record Than Opponent",
                         generalSize: areTeamConferenceRecordsNonEqual,
                         homeSize: doesHomeTeamHaveBetterConferenceRecord,
                         awaySize: doesAwayTeamHaveBetterConferenceRecord,
                         generalDidMatch: didTeamWithBetterConferenceRecordCoverSpread,
                         generalDesignatedTeam: getTeamNameWithBetterConferenceRecord),
        
        getCategoryGroup(baseName: "Worse Conference Record Than Opponent",
                         generalSize: areTeamConferenceRecordsNonEqual,
                         homeSize: doesHomeTeamHaveWorseConferenceRecord,
                         awaySize: doesAwayTeamHaveWorseConferenceRecord,
                         generalDidMatch: didTeamWithWorseConferenceRecordCoverSpread,
                         generalDesignatedTeam: getTeamNameWithWorseConferenceRecord),
        
        getCategoryGroup(baseName: "More Combined Experience",
                         generalSize: areCombinedExperiencesNonEqual,
                         homeSize: doesHomeTeamHaveMoreCombinedExperience,
                         awaySize: doesAwayTeamHaveMoreCombinedExperience,
                         generalDidMatch: didTeamWithMoreCombinedExperienceCoverSpread,
                         generalDesignatedTeam: getTeamNameWithMoreCombinedExperience),
        
        getCategoryGroup(baseName: "Less Combined Experience",
                         generalSize: areCombinedExperiencesNonEqual,
                         homeSize: doesHomeTeamHaveLessCombinedExperience,
                         awaySize: doesAwayTeamHaveLessCombinedExperience,
                         generalDidMatch: didTeamWithLessCombinedExperienceCoverSpread,
                         generalDesignatedTeam: getTeamNameWithLessCombinedExperience),
        
        getCategoryGroup(baseName: "More Combined Experience Within The Top 5 Players",
                         generalSize: areTop5PlayersCombinedExperiencesNonEqual,
                         homeSize: doesHomeTeamHaveMoreCombinedExperienceInTheirTop5Players,
                         awaySize: doesAwayTeamHaveMoreCombinedExperienceInTheirTop5Players,
                         generalDidMatch: didTeamWithMoreCombinedExperienceInTheirTop5PlayersCoverSpread,
                         generalDesignatedTeam: getTeamNameWithMoreTop5CombinedExperience),
        
        getCategoryGroup(baseName: "Less Combined Experience Within The Top 5 Players",
                         generalSize: areTop5PlayersCombinedExperiencesNonEqual,
                         homeSize: doesHomeTeamHaveLessCombinedExperienceInTheirTop5Players,
                         awaySize: doesAwayTeamHaveLessCombinedExperienceInTheirTop5Players,
                         generalDidMatch: didTeamWithLessCombinedExperienceInTheirTop5PlayersCoverSpread,
                         generalDesignatedTeam: getTeamNameWithLessTop5CombinedExperience),
        
        getHomeAwayCategoryGroup(baseName: "Both Teams Being Nationally Ranked", size: doesMatchupHaveTwoNationallyRankedTeams),
        getHomeAwayCategoryGroup(baseName: "In Primetime Matchup", size: { $0.1.coverage == .standardTV }),
        getHomeAwayCategoryGroup(baseName: "In Sports TV Matchup", size: { $0.1.coverage == .sportsTV }),
        getHomeAwayCategoryGroup(baseName: "In Matchup w/ No TV Coverage", size: { $0.1.coverage == nil }),
        getHomeAwayCategoryGroup(baseName: "In Matchup w/ Any TV Coverage", size: { [.standardTV, .sportsTV].contains($0.1.coverage) }),
        
        // this just means out of all games, which home teams and away teams covered the spread
        getHomeAwayCategoryGroup(baseName: "", size: { _ in true })
    ]
    
    return categoryGroups.flatMap { $0 }
}

func getIndividualCategories() -> [Category] {
    let categories: [Category] = [
            .init(name: "Covered Spread w/ More Steals Against Team With More Turnovers (Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
                doesMatchupHaveATeamWithMoreStealsAndLessTurnovers(game)
            } didMatch: { game in
                didTeamWithMoreStealsAndLessTurnoversCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithMoreStealsAndLessTurnovers(game)
            },
            
            .init(name: "Covered Spread w/ More Steals Against Team With More Turnovers (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveATeamWithMoreStealsAndLessTurnovers(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithMoreStealsAndLessTurnoversCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithMoreStealsAndLessTurnovers(game)
            },
            
            .init(name: "Covered Spread w/ More Steals Against Team With More Turnovers (Non-Conference Games, Neutral Venues)") { game in
                doesMatchupHaveATeamWithMoreStealsAndLessTurnovers(game) && game.1.isConferenceMatchup && game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithMoreStealsAndLessTurnoversCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithMoreStealsAndLessTurnovers(game)
            },
            
            .init(name: "Covered Spread w/ More Steals Against Team With More Turnovers (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
                doesMatchupHaveATeamWithMoreStealsAndLessTurnovers(game) && !game.1.isConferenceMatchup
            } didMatch: { game in
                didTeamWithMoreStealsAndLessTurnoversCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithMoreStealsAndLessTurnovers(game)
            },
            
            .init(name: "Covered Spread w/ More Steals Against Team With More Turnovers (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveATeamWithMoreStealsAndLessTurnovers(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithMoreStealsAndLessTurnoversCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithMoreStealsAndLessTurnovers(game)
            },
        
            .init(name: "Covered Spread w/ Less Steals Against Team With Less Turnovers (Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
                doesMatchupHaveATeamWithLessStealsAndMoreTurnovers(game)
            } didMatch: { game in
                didTeamWithLessStealsAndMoreTurnoversCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithLessStealsAndMoreTurnovers(game)
            },
            
            .init(name: "Covered Spread w/ Less Steals Against Team With Less Turnovers (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveATeamWithLessStealsAndMoreTurnovers(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithLessStealsAndMoreTurnoversCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithLessStealsAndMoreTurnovers(game)
            },
            
            .init(name: "Covered Spread w/ Less Steals Against Team With Less Turnovers (Non-Conference Games, Neutral Venues)") { game in
                doesMatchupHaveATeamWithLessStealsAndMoreTurnovers(game) && game.1.isConferenceMatchup && game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithLessStealsAndMoreTurnoversCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithLessStealsAndMoreTurnovers(game)
            },
            
            .init(name: "Covered Spread w/ Less Steals Against Team With Less Turnovers (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
                doesMatchupHaveATeamWithLessStealsAndMoreTurnovers(game) && !game.1.isConferenceMatchup
            } didMatch: { game in
                didTeamWithLessStealsAndMoreTurnoversCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithLessStealsAndMoreTurnovers(game)
            },
            
            .init(name: "Covered Spread w/ Less Steals Against Team With Less Turnovers (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveATeamWithLessStealsAndMoreTurnovers(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithLessStealsAndMoreTurnoversCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithLessStealsAndMoreTurnovers(game)
            },
            
            .init(name: "Home Team Covered Spread w/ More Steals Against Away Team With More Turnovers (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAHomeTeamWithMoreStealsAndLessTurnovers(game) && !game.1.venue.isNeutral
            } didMatch: { game in
                didHomeTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
            
            .init(name: "Home Team Covered Spread w/ More Steals Against Away Team With More Turnovers (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAHomeTeamWithMoreStealsAndLessTurnovers(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didHomeTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
            
            .init(name: "Home Team Covered Spread w/ More Steals Against Away Team With More Turnovers (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAHomeTeamWithMoreStealsAndLessTurnovers(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didHomeTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
        
            .init(name: "Home Team Covered Spread w/ Less Steals Against Away Team With Less Turnovers (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAHomeTeamWithLessStealsAndMoreTurnovers(game) && !game.1.venue.isNeutral
            } didMatch: { game in
                didHomeTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
            
            .init(name: "Home Team Covered Spread w/ Less Steals Against Away Team With Less Turnovers (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAHomeTeamWithLessStealsAndMoreTurnovers(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didHomeTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
            
            .init(name: "Home Team Covered Spread w/ Less Steals Against Away Team With Less Turnovers (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAHomeTeamWithLessStealsAndMoreTurnovers(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didHomeTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
        
            .init(name: "Away Team Covered Spread w/ More Steals Against Home Team With More Turnovers (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAnAwayTeamWithMoreStealsAndLessTurnovers(game) && !game.1.venue.isNeutral
            } didMatch: { game in
                didAwayTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
            
            .init(name: "Away Team Covered Spread w/ More Steals Against Home Team With More Turnovers (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAnAwayTeamWithMoreStealsAndLessTurnovers(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didAwayTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
            
            .init(name: "Away Team Covered Spread w/ More Steals Against Home Team With More Turnovers (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAnAwayTeamWithMoreStealsAndLessTurnovers(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didAwayTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
        
            .init(name: "Away Team Covered Spread w/ Less Steals Against Home Team With Less Turnovers (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAnAwayTeamWithLessStealsAndMoreTurnovers(game) && !game.1.venue.isNeutral
            } didMatch: { game in
                didAwayTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
            
            .init(name: "Away Team Covered Spread w/ Less Steals Against Home Team With Less Turnovers (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAnAwayTeamWithLessStealsAndMoreTurnovers(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didAwayTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
            
            .init(name: "Away Team Covered Spread w/ Less Steals Against Home Team With Less Turnovers (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveAnAwayTeamWithLessStealsAndMoreTurnovers(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didAwayTeamCoverTheSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
            
            .init(name: "Covered Spread w/ Better National Ranking When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game)
            } didMatch: { game in
                didTeamWithBetterNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithBetterNationalRanking(game)
            },
            
            .init(name: "Covered Spread w/ Better National Ranking When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithBetterNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithBetterNationalRanking(game)
            },
            
            .init(name: "Covered Spread w/ Better National Ranking When Both Opponents Are Nationally Ranked (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && !game.1.isConferenceMatchup
            } didMatch: { game in
                didTeamWithBetterNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithBetterNationalRanking(game)
            },
            
            .init(name: "Covered Spread w/ Better National Ranking When Both Opponents Are Nationally Ranked (Non-Conference Games, Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithBetterNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithBetterNationalRanking(game)
            },
            
            .init(name: "Covered Spread w/ Better National Ranking When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithBetterNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithBetterNationalRanking(game)
            },
            
            .init(name: "Covered Spread w/ Worse National Ranking When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game)
            } didMatch: { game in
                didTeamWithWorseNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithWorseNationalRanking(game)
            },
            
            .init(name: "Covered Spread w/ Worse National Ranking When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithWorseNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithWorseNationalRanking(game)
            },
            
            .init(name: "Covered Spread w/ Worse National Ranking When Both Opponents Are Nationally Ranked (Non-Conference Games, Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithWorseNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithWorseNationalRanking(game)
            },
            
            .init(name: "Covered Spread w/ Worse National Ranking When Both Opponents Are Nationally Ranked (Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && !game.1.isConferenceMatchup
            } didMatch: { game in
                didTeamWithWorseNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithWorseNationalRanking(game)
            },
            
            .init(name: "Covered Spread w/ Worse National Ranking When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithWorseNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getTeamNameWithWorseNationalRanking(game)
            },
            
            .init(name: "Home Team Covered Spread w/ Better National Ranking When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesHomeTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game) && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithBetterNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
            
            .init(name: "Home Team Covered Spread w/ Better National Ranking When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesHomeTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game)
                    && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithBetterNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
            
            .init(name: "Home Team Covered Spread w/ Better National Ranking When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesHomeTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game)
                    && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithBetterNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
            
            .init(name: "Home Team Covered Spread w/ Worse National Ranking When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesHomeTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game) && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithWorseNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
            
            .init(name: "Home Team Covered Spread w/ Worse National Ranking When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesHomeTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game)
                    && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithWorseNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
            
            .init(name: "Home Team Covered Spread w/ Worse National Ranking When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesHomeTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game)
                    && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithWorseNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getHomeTeamName(game)
            },
            
            .init(name: "Away Team Covered Spread w/ Better National Ranking When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesAwayTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game) && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithBetterNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
            
            .init(name: "Away Team Covered Spread w/ Better National Ranking When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesAwayTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game)
                    && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithBetterNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
            
            .init(name: "Away Team Covered Spread w/ Better National Ranking When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesAwayTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game)
                    && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithBetterNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
            
            .init(name: "Away Team Covered Spread w/ Worse National Ranking When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesAwayTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game) && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithWorseNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
            
            .init(name: "Away Team Covered Spread w/ Worse National Ranking When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesAwayTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game)
                    && game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithWorseNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
            
            .init(name: "Away Team Covered Spread w/ Worse National Ranking When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
                doesMatchupHaveTwoNationallyRankedTeams(game) && doesAwayTeamHaveBetterNationalRankingThanNationallyRankedAwayTeam(game)
                    && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
            } didMatch: { game in
                didTeamWithWorseNationalRankingCoverSpread(game)
            } designatedTeam: { game in
                getAwayTeamName(game)
            },
         
         .init(name: "Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
     
         .init(name: "Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseDefensiveEfficiency(game)
         },

         .init(name: "Home Team Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterOffensiveEfficiency(game)
                 && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterOffensiveEfficiency(game)
                 && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterOffensiveEfficiency(game)
                 && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseOffensiveEfficiency(game)
                 && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseOffensiveEfficiency(game)
                 && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseOffensiveEfficiency(game)
                 && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
     
         .init(name: "Home Team Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterDefensiveEfficiency(game)
                 && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterDefensiveEfficiency(game)
                 && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterDefensiveEfficiency(game)
                 && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseDefensiveEfficiency(game)
                 && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseDefensiveEfficiency(game)
                 && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseDefensiveEfficiency(game)
                 && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },

         .init(name: "Away Team Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterOffensiveEfficiency(game)
                 && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterOffensiveEfficiency(game)
                 && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterOffensiveEfficiency(game)
                 && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseOffensiveEfficiency(game)
                 && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseOffensiveEfficiency(game)
                 && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseOffensiveEfficiency(game)
                 && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
     
         .init(name: "Away Team Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterDefensiveEfficiency(game)
                 && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterDefensiveEfficiency(game)
                 && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterDefensiveEfficiency(game)
                 && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseDefensiveEfficiency(game)
                 && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseDefensiveEfficiency(game)
                 && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseDefensiveEfficiency(game)
                 && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },

         .init(name: "Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
     
         .init(name: "Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Both Conference And Non-Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency When Both Opponents Are Nationally Ranked (Non-Conference Games, Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseDefensiveEfficiency(game)
         },
         .init(name: "Home Team Covered Spread When Both Teams Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread When Both Teams Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread When Both Teams Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread When Both Teams Are Nationally Ranked (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread When Both Teams Are Nationally Ranked (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread When Both Teams Are Nationally Ranked (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveTwoNationallyRankedTeams(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Covered Spread w/ National Ranking Against Unranked Opponent (Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesMatchupHaveOneNationallyRankedAndOneUnrankedTeam(game)
         } didMatch: { game in
             didNationallyRankedTeamCoverSpreadOverUnrankedTeam(game)
         } designatedTeam: { game in
             getNationallyRankedTeamName(game)
         },
         
         .init(name: "Covered Spread w/ National Ranking Against Unranked Opponent (Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesMatchupHaveOneNationallyRankedAndOneUnrankedTeam(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didNationallyRankedTeamCoverSpreadOverUnrankedTeam(game)
         } designatedTeam: { game in
             getNationallyRankedTeamName(game)
         },
         
         .init(name: "Covered Spread w/ National Ranking Against Unranked Opponent (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesMatchupHaveOneNationallyRankedAndOneUnrankedTeam(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didNationallyRankedTeamCoverSpreadOverUnrankedTeam(game)
         } designatedTeam: { game in
             getNationallyRankedTeamName(game)
         },
         
         .init(name: "Covered Spread w/ National Ranking Against Unranked Opponent (Non-Conference Games, Neutral Venues)") { game in
             doesMatchupHaveOneNationallyRankedAndOneUnrankedTeam(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didNationallyRankedTeamCoverSpreadOverUnrankedTeam(game)
         } designatedTeam: { game in
             getNationallyRankedTeamName(game)
         },
         
         .init(name: "Covered Spread w/ National Ranking Against Unranked Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveOneNationallyRankedAndOneUnrankedTeam(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didNationallyRankedTeamCoverSpreadOverUnrankedTeam(game)
         } designatedTeam: { game in
             getNationallyRankedTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ National Ranking Against Unranked Opponent (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveOneNationallyRankedHomeTeamAndOneUnrankedTeam(game)
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ National Ranking Against Unranked Opponent (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveOneNationallyRankedHomeTeamAndOneUnrankedTeam(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ National Ranking Against Unranked Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveOneNationallyRankedHomeTeamAndOneUnrankedTeam(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
     
         .init(name: "Away Team Covered Spread w/ National Ranking Against Unranked Opponent (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveOneNationallyRankedAwayTeamAndOneUnrankedTeam(game)
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ National Ranking Against Unranked Opponent (Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveOneNationallyRankedAwayTeamAndOneUnrankedTeam(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ National Ranking Against Unranked Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             doesMatchupHaveOneNationallyRankedAwayTeamAndOneUnrankedTeam(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive Efficiency (Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game)
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive Efficiency (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive Efficiency (Non-Conference Games, Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency (Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game)
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency (Non-Conference Games, Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Defensive Efficiency (Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game)
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Defensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Defensive Efficiency (Non-Conference Games, Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency (Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game)
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency (Non-Conference Games, Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive And Defensive Efficiency (Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveAndDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive And Defensive Efficiency (Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveAndDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive And Defensive Efficiency (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveAndDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive And Defensive Efficiency (Non-Conference Games, Neutral Venues)") { game in
             doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveAndDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Better Offensive And Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterOffensiveAndDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive And Defensive Efficiency (Both Conference And Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveAndDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive And Defensive Efficiency (Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveAndDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive And Defensive Efficiency (Non-Conference Games, Both Neutral And Non-Neutral Venues)") { game in
             doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveAndDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive And Defensive Efficiency (Non-Conference Games, Neutral Venues)") { game in
             doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveAndDefensiveEfficiency(game)
         },
         
         .init(name: "Covered Spread w/ Worse Offensive And Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseOffensiveAndDefensiveEfficiency(game)
         },

         .init(name: "Home Team Covered Spread w/ Better Offensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterOffensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Covered Spread w/ Better Offensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterOffensiveEfficiency(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Covered Spread w/ Better Offensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterOffensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Offensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseOffensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Offensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseOffensiveEfficiency(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Offensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseOffensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Better Defensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterDefensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Better Defensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterDefensiveEfficiency(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Better Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveBetterDefensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Defensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseDefensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Defensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseDefensiveEfficiency(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesHomeTeamHaveWorseDefensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Better Offensive And Defensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && doesHomeTeamHaveBetterOffensiveAndDefensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Better Offensive And Defensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && doesHomeTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Better Offensive And Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && doesHomeTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Offensive And Defensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && doesHomeTeamHaveWorseOffensiveAndDefensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Offensive And Defensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && doesHomeTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread w/ Worse Offensive And Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && doesHomeTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Better Offensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterOffensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Covered Spread w/ Better Offensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterOffensiveEfficiency(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Covered Spread w/ Better Offensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterOffensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Offensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseOffensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Offensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseOffensiveEfficiency(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Offensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areOffensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseOffensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Better Defensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterDefensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Better Defensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterDefensiveEfficiency(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Better Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveBetterDefensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Defensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseDefensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Defensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseDefensiveEfficiency(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             areDefensiveEfficienciesNonEqual(game) && doesAwayTeamHaveWorseDefensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Better Offensive And Defensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && doesAwayTeamHaveBetterOffensiveAndDefensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Better Offensive And Defensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && doesAwayTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Better Offensive And Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && doesAwayTeamHaveBetterOffensiveAndDefensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Offensive And Defensive Efficiency (Both Conference And Non-Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && doesAwayTeamHaveWorseOffensiveAndDefensiveEfficiency(game)
         } didMatch: { game in
             didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Offensive And Defensive Efficiency (Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && doesAwayTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread w/ Worse Offensive And Defensive Efficiency (Non-Conference Games, Non-Neutral Venues)") { game in
             doesEitherTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && doesAwayTeamHaveWorseOffensiveAndDefensiveEfficiency(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseOffensiveAndDefensiveEfficiencyCoverSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread (Conference Games, Non-Neutral Venues)") { game in
             game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread (Conference Games, Non-Neutral Venues)") { game in
             game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread (Non-Conference Games, Non-Neutral Venues)") { game in
             !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread (Non-Conference Games, Non-Neutral Venues)") { game in
             !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread (Conference Games, Non-Neutral Venues)") { game in
             game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread (Conference Games, Non-Neutral Venues)") { game in
             game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Home Team Covered Spread (Non-Conference Games, Non-Neutral Venues)") { game in
             !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Team Covered Spread (Non-Conference Games, Non-Neutral Venues)") { game in
             !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Covered Spread w/ Better Record Than Opponent (Non-Conference Games, Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterRecord(game)
         },

         .init(name: "Covered Spread w/ Better Record Than Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterRecord(game)
         },

         .init(name: "Covered Spread w/ Better Record Than Opponent (Conference Games, Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterRecord(game)
         },
         
         .init(name: "Covered Spread w/ Better Record Than Opponent (Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterRecord(game)
         },
         
         .init(name: "Covered Spread w/ Better Record Than Opponent (Both Conference and Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game)
         } didMatch: { game in
             didTeamWithBetterRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterRecord(game)
         },
         
         .init(name: "Covered Spread w/ Better Record Than Opponent (Both Conference and Non-Conference Games, Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterRecord(game)
         },
         
         .init(name: "Covered Spread w/ Better Record Than Opponent (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithBetterRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterRecord(game)
         },
         
         .init(name: "Covered Spread w/ Better Record Than Opponent (Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Record Than Opponent (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Record Than Opponent (Both Conference and Non-Conference Games, Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Record Than Opponent (Both Conference and Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game)
         } didMatch: { game in
             didTeamWithWorseRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Record Than Opponent (Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Record Than Opponent (Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Record Than Opponent (Conference Games, Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Record Than Opponent (Non-Conference Games, Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Record Than Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             areTeamRecordsNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseRecord(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Better Record Than Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveBetterRecord(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Better Record Than Opponent (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveBetterRecord(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Better Record Than Opponent (Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             doesHomeTeamHaveBetterRecord(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Better Record Than Opponent (Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveBetterRecord(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Worse Record Than Opponent (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveWorseRecord(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Worse Record Than Opponent (Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveWorseRecord(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Worse Record Than Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveWorseRecord(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Better Record Than Opponent (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveBetterRecord(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Better Record Than Opponent (Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveBetterRecord(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Better Record Than Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveBetterRecord(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Worse Record Than Opponent (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveWorseRecord(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Worse Record Than Opponent (Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveWorseRecord(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Worse Record Than Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveWorseRecord(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Covered Spread w/ Better Conference Record Than Opponent (Both Conference and Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamConferenceRecordsNonEqual(game)
         } didMatch: { game in
             didTeamWithBetterConferenceRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterConferenceRecord(game)
         },
         
         .init(name: "Covered Spread w/ Better Conference Record Than Opponent (Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamConferenceRecordsNonEqual(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterConferenceRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterConferenceRecord(game)
         },
         
         .init(name: "Covered Spread w/ Better Conference Record Than Opponent (Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamConferenceRecordsNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithBetterConferenceRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithBetterConferenceRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Conference Record Than Opponent (Both Conference and Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamConferenceRecordsNonEqual(game)
         } didMatch: { game in
             didTeamWithWorseConferenceRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseConferenceRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Conference Record Than Opponent (Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamConferenceRecordsNonEqual(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseConferenceRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseConferenceRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Conference Record Than Opponent (Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTeamConferenceRecordsNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithWorseConferenceRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseConferenceRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Conference Record Than Opponent (Non-Conference Games, Neutral Venues)") { game in
             areTeamConferenceRecordsNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseConferenceRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseConferenceRecord(game)
         },
         
         .init(name: "Covered Spread w/ Worse Conference Record Than Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             areTeamConferenceRecordsNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithWorseConferenceRecordCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithWorseConferenceRecord(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Better Conference Record Than Opponent (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveBetterConferenceRecord(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Better Conference Record Than Opponent (Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveBetterConferenceRecord(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Better Conference Record Than Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveBetterConferenceRecord(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Worse Conference Record Than Opponent (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveWorseConferenceRecord(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Worse Conference Record Than Opponent (Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveWorseConferenceRecord(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Worse Conference Record Than Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveWorseConferenceRecord(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Better Conference Record Than Opponent (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveBetterConferenceRecord(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Better Conference Record Than Opponent (Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveBetterConferenceRecord(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Better Conference Record Than Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveBetterConferenceRecord(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Worse Conference Record Than Opponent (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveWorseConferenceRecord(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Worse Conference Record Than Opponent (Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveWorseConferenceRecord(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Worse Conference Record Than Opponent (Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveWorseConferenceRecord(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Primetime Matchup (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .standardTV && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Primetime Matchup (Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .standardTV && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Primetime Matchup (Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .standardTV && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Primetime Matchup (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .standardTV && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Primetime Matchup (Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .standardTV && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Primetime Matchup (Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .standardTV && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Sports TV Matchup (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .sportsTV && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Sports TV Matchup (Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .sportsTV && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Sports TV Matchup (Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .sportsTV && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Sports TV Matchup (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .sportsTV && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Sports TV Matchup (Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .sportsTV && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Sports TV Matchup (Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == .sportsTV && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Matchup With No TV Coverage (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == nil && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Matchup With No TV Coverage (Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == nil && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Matchup With No TV Coverage (Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == nil && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Matchup With No TV Coverage (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == nil && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Matchup With No TV Coverage (Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == nil && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Matchup With No TV Coverage (Non-Conference Games, Non-Neutral Venues)") { game in
             game.1.coverage == nil && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Matchup With Any TV Coverage (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             [.standardTV, .sportsTV].contains(game.1.coverage) && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Matchup With Any TV Coverage (Conference Games, Non-Neutral Venues)") { game in
             [.standardTV, .sportsTV].contains(game.1.coverage) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread During Matchup With Any TV Coverage (Non-Conference Games, Non-Neutral Venues)") { game in
             [.standardTV, .sportsTV].contains(game.1.coverage) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Matchup With No TV Coverage (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             [.standardTV, .sportsTV].contains(game.1.coverage) && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Matchup With Any TV Coverage (Conference Games, Non-Neutral Venues)") { game in
             [.standardTV, .sportsTV].contains(game.1.coverage) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread During Matchup With Any TV Coverage (Non-Conference Games, Non-Neutral Venues)") { game in
             [.standardTV, .sportsTV].contains(game.1.coverage) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Covered Spread w/ More Combined Experience (Both Conference and Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areCombinedExperiencesNonEqual(game)
         } didMatch: { game in
             didTeamWithMoreCombinedExperienceCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithMoreCombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ More Combined Experience (Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areCombinedExperiencesNonEqual(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithMoreCombinedExperienceCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithMoreCombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ More Combined Experience (Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithMoreCombinedExperienceCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithMoreCombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ More Combined Experience (Non-Conference Games, Neutral Venues)") { game in
             areCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithMoreCombinedExperienceCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithMoreCombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ More Combined Experience (Non-Conference Games, Non-Neutral Venues)") { game in
             areCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithMoreCombinedExperienceCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithMoreCombinedExperience(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ More Combined Experience (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveMoreCombinedExperience(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ More Combined Experience (Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveMoreCombinedExperience(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ More Combined Experience (Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveMoreCombinedExperience(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ More Combined Experience (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveMoreCombinedExperience(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ More Combined Experience (Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveMoreCombinedExperience(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ More Combined Experience (Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveMoreCombinedExperience(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Covered Spread w/ Less Combined Experience (Both Conference and Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areCombinedExperiencesNonEqual(game)
         } didMatch: { game in
             didTeamWithLessCombinedExperienceCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithLessCombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ Less Combined Experience (Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areCombinedExperiencesNonEqual(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithLessCombinedExperienceCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithLessCombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ Less Combined Experience (Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithLessCombinedExperienceCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithLessCombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ Less Combined Experience (Non-Conference Games, Neutral Venues)") { game in
             areCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithLessCombinedExperienceCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithLessCombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ Less Combined Experience (Non-Conference Games, Non-Neutral Venues)") { game in
             areCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithLessCombinedExperienceCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithLessCombinedExperience(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Less Combined Experience (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveLessCombinedExperience(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Less Combined Experience (Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveLessCombinedExperience(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Less Combined Experience (Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveLessCombinedExperience(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Less Combined Experience (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveLessCombinedExperience(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Less Combined Experience (Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveLessCombinedExperience(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Less Combined Experience (Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveLessCombinedExperience(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Covered Spread w/ More Combined Experience Within The Top 5 Players (Both Conference and Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTop5PlayersCombinedExperiencesNonEqual(game)
         } didMatch: { game in
             didTeamWithMoreCombinedExperienceInTheirTop5PlayersCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithMoreTop5CombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ More Combined Experience Within The Top 5 Players (Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTop5PlayersCombinedExperiencesNonEqual(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithMoreCombinedExperienceInTheirTop5PlayersCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithMoreTop5CombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ More Combined Experience Within The Top 5 Players (Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTop5PlayersCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithMoreCombinedExperienceInTheirTop5PlayersCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithMoreTop5CombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ More Combined Experience Within The Top 5 Players (Non-Conference Games, Neutral Venues)") { game in
             areTop5PlayersCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithMoreCombinedExperienceInTheirTop5PlayersCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithMoreTop5CombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ More Combined Experience Within The Top 5 Players (Non-Conference Games, Non-Neutral Venues)") { game in
             areTop5PlayersCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithMoreCombinedExperienceInTheirTop5PlayersCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithMoreTop5CombinedExperience(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ More Combined Experience Within The Top 5 Players (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveMoreCombinedExperienceInTheirTop5Players(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ More Combined Experience Within The Top 5 Players (Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveMoreCombinedExperienceInTheirTop5Players(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ More Combined Experience Within The Top 5 Players (Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveMoreCombinedExperienceInTheirTop5Players(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ More Combined Experience Within The Top 5 Players (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveMoreCombinedExperienceInTheirTop5Players(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ More Combined Experience Within The Top 5 Players (Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveMoreCombinedExperienceInTheirTop5Players(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ More Combined Experience Within The Top 5 Players (Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveMoreCombinedExperienceInTheirTop5Players(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Covered Spread w/ Less Combined Experience Within The Top 5 Players (Both Conference and Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTop5PlayersCombinedExperiencesNonEqual(game)
         } didMatch: { game in
             didTeamWithLessCombinedExperienceInTheirTop5PlayersCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithLessTop5CombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ Less Combined Experience Within The Top 5 Players (Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTop5PlayersCombinedExperiencesNonEqual(game) && game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithLessCombinedExperienceInTheirTop5PlayersCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithLessTop5CombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ Less Combined Experience Within The Top 5 Players (Non-Conference Games, Both Neutral and Non-Neutral Venues)") { game in
             areTop5PlayersCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup
         } didMatch: { game in
             didTeamWithLessCombinedExperienceInTheirTop5PlayersCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithLessTop5CombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ Less Combined Experience Within The Top 5 Players (Non-Conference Games, Neutral Venues)") { game in
             areTop5PlayersCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup && game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithLessCombinedExperienceInTheirTop5PlayersCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithLessTop5CombinedExperience(game)
         },
         
         .init(name: "Covered Spread w/ Less Combined Experience Within The Top 5 Players (Non-Conference Games, Non-Neutral Venues)") { game in
             areTop5PlayersCombinedExperiencesNonEqual(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didTeamWithLessCombinedExperienceInTheirTop5PlayersCoverSpread(game)
         } designatedTeam: { game in
             getTeamNameWithLessTop5CombinedExperience(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Less Combined Experience Within The Top 5 Players (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveLessCombinedExperienceInTheirTop5Players(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Less Combined Experience Within The Top 5 Players (Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveLessCombinedExperienceInTheirTop5Players(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Home Teams That Covered Spread w/ Less Combined Experience Within The Top 5 Players (Non-Conference Games, Non-Neutral Venues)") { game in
             doesHomeTeamHaveLessCombinedExperienceInTheirTop5Players(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didHomeTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getHomeTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Less Combined Experience Within The Top 5 Players (Both Conference and Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveLessCombinedExperienceInTheirTop5Players(game) && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Less Combined Experience Within The Top 5 Players (Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveLessCombinedExperienceInTheirTop5Players(game) && game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         },
         
         .init(name: "Away Teams That Covered Spread w/ Less Combined Experience Within The Top 5 Players (Non-Conference Games, Non-Neutral Venues)") { game in
             doesAwayTeamHaveLessCombinedExperienceInTheirTop5Players(game) && !game.1.isConferenceMatchup && !game.1.venue.isNeutral
         } didMatch: { game in
             didAwayTeamCoverTheSpread(game)
         } designatedTeam: { game in
             getAwayTeamName(game)
         }
    ]
    
    return categories
}
