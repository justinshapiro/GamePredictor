//
//  WebScraperHelperFunctions.swift
//  GamePredictor
//
//  Created by Justin on 1/5/23.
//

import Foundation

// MARK: - Get Webpage

var pageCache = [String: String]()

func getWebpage(from urlString: String, useCache: Bool = true) -> String {
    if useCache, let cachedValue = pageCache[urlString] {
        return cachedValue
    } else {
        let semaphore = DispatchSemaphore(value: 0)
        let session = URLSession(configuration: .default)
        let request = URLRequest(url: .init(string: urlString)!)
        
        var webpageData: Data?
        session.dataTask(with: request) { data, _, _ in
            webpageData = data
            semaphore.signal()
        }.resume()
        
        semaphore.wait()
        
        if let webpageData = webpageData, let result = String(data: webpageData, encoding: .utf8) {
            pageCache[urlString] = result
            return result
        } else {
            return getWebpage(from: urlString, useCache: useCache)
        }
    }
}


// MARK: - Teams

func getTeamURLs() -> [String] {
    let allTeamsURL = "https://www.espn.com/\(SPORT_MODE.espnPathIndicator)/teams"
    let allTeamsWebpage = getWebpage(from: allTeamsURL)
    
    let pageIndicator: String
    
    switch SPORT_MODE {
    case .collegeBasketball(let league):
        switch league {
        case .mens: pageIndicator = "Men"
        case .womens: pageIndicator = "Women"
        }
    case .nba:
        pageIndicator = "NBA Teams\""
    }
    
    let segment = allTeamsWebpage
        .components(separatedBy: "\"leagueTeams\"")[1]
        .components(separatedBy: "\"title\":\"\(pageIndicator)")[0]
        .dropFirst()
        .dropLast() + "}"
    
    let teamsList = try! JSONDecoder().decode(TeamsList.self, from: segment.data(using: .utf8)!)
    
    return teamsList.columns
        .lazy
        .map { $0.groups }
        .reduce([TeamsList.Column.Group](), +)
        .map { $0.teams }
        .reduce([TeamsList.Column.Group.Team](), +)
        .map { "https://www.espn.com/\(SPORT_MODE.espnPathIndicator)/team/_/id/\($0.teamNumericID)" }
}

func getAllTeams(from teamURLs: [String]) -> [Team] {
    teamURLs.map { teamURL in
        let teamID = teamURL.components(separatedBy: "/").last!
        
        if var team: Team = FileManager.default.getDecodedFileIfExists(fileName: "\(teamID).json", todayOnly: false) {
            let gamesPlayedSinceLastPull = team.games.upcoming.filter { $0.date < .now && !Calendar.current.isDateInToday($0.date) }
            
            if gamesPlayedSinceLastPull.isEmpty || DISABLE_UPDATE {
                return team
            } else {
                print("Updating team ID \(teamID)")
                
                let teamSchedule = getTeamSchedule(from: teamURL.replace("team/", with: "team/schedule/"))
                
                let newPreviousEvents = teamSchedule.events.previous
                    .lazy
                    .filter { event in gamesPlayedSinceLastPull.contains { $0.date == event.date.dateString.gameDate } }
                
                team.games.previous += newPreviousEvents.compactMap { getPreviousGame(from: $0, teamID: teamID) }
                
                // Additional games are added/cancelled and TV coverage and venue information is updated as the season goes on
                team.games.upcoming = teamSchedule.events.upcoming
                    .lazy
                    .filter { !$0.time.link.isEmpty && $0.opponent.teamID != nil }
                    .map { getUpcomingGame(from: $0) }
                    .filter { game in
                        !gamesPlayedSinceLastPull.contains { Calendar.current.isDate($0.date, inSameDayAs: game.date) && game.opponentID == $0.opponentID }
                    }
                
                let previousEventsURLs = newPreviousEvents.map { $0.time.link.replace("/game/", with: "/boxscore/") }
                
                let playerHeaders = getPlayerURLs(from: teamURL.replace("team/", with: "team/roster/")).compactMap {
                    getPlayerHeader(from: $0)
                }
                
                team.roster.enumerated().forEach { playerIndex, player in
                    if let currentSeasonIndex = player.seasons.firstIndex(where: { $0.seasonYear == CURRENT_SEASON_YEAR }) {
                        team.roster[playerIndex].seasons[currentSeasonIndex].gameLogs += previousEventsURLs.compactMap {
                            guard let playerHeader = playerHeaders.first(where: { $0.displayName == player.name }) else {
                                return nil
                            }
                            
                            return getPlayerGameLog(in: $0, playerShortName: playerHeader.shortName)
                        }
                    }
                }
                
                let teamHeader = getTeamInfo(from: teamURL)
                team.conferenceRanking = teamHeader.conferenceRanking
                team.nationalRanking = teamHeader.nationalRanking
                team.depthChart = getDepthChart(for: teamID) ?? team.depthChart
                
                team.export(as: "\(teamID).json")
                return team
            }
        } else {
            print("Fetching team ID \(teamID) fresh from ESPN")
            
            let teamHeader = getTeamInfo(from: teamURL)
            let playerURLs = getPlayerURLs(from: teamURL.replace("team/", with: "team/roster/"))
            let players = playerURLs.compactMap { getPlayer(from: $0) }
            let games = getGames(from: teamURL.replace("team/", with: "team/schedule/"), teamID: teamHeader.abbreviation)
            let depthChart = getDepthChart(for: teamID)

            let team = Team(teamID: teamHeader.abbreviation,
                            conference: teamHeader.conference,
                            conferenceRanking: teamHeader.conferenceRanking,
                            nationalRanking: teamHeader.nationalRanking,
                            roster: players,
                            games: games,
                            depthChart: depthChart)

            team.export(as: "\(teamID).json")
            
            return team
        }
    }
}

func getTeamInfo(from teamURL: String) -> TeamHeader {
    let webpage = getWebpage(from: teamURL)
    let teamHeaderString = webpage.substring(startingTerm: "\"teamHeader\"", endingAtFirst: "}")
    return try! JSONDecoder().decode(TeamHeader.self, from: teamHeaderString.data(using: .utf8)!)
}

func getTeamSchedule(from scheduleURL: String) -> TeamSchedule {
    let webpage = getWebpage(from: scheduleURL)
    var teamScheduleString = String(webpage
        .components(separatedBy: "\"teamSchedule\"")[1]
        .dropFirst()
        .components(separatedBy: "\"noData\"")[0]
        .dropLast())
    
    if teamScheduleString.contains("\"buttons\":") {
        teamScheduleString = String(teamScheduleString.components(separatedBy: "\"buttons\":")[0].dropLast())
        
        ["post", "pre"].forEach { scheduleID in
            let groupedScheduleString = teamScheduleString.components(separatedBy: "\"\(scheduleID)\":")[1]
            let replacementScheduleString = groupedScheduleString
                .components(separatedBy: "\"group\":")[1]
                .replacingOccurrences(of: scheduleID == "post" ? "}}]}]}" : "}]}]", with: scheduleID == "post" ? "}}]}" : "}]")
            
            teamScheduleString = teamScheduleString.replacingOccurrences(of: groupedScheduleString, with: replacementScheduleString)
        }
    }
    
    let teamSchedule = try! JSONDecoder().decode([TeamSchedule].self, from: teamScheduleString.data(using: .utf8)!)
    return teamSchedule.first { $0.seasonType.abbreviation == .regularSeason }!
}


// MARK: - Players

func getPlayerURLs(from rosterURL: String) -> [URL] {
    let baseURL = "https://www.espn.com/\(SPORT_MODE.espnPathIndicator)/player/_/id"
    let playerURLLocation = "href=\"\(baseURL)"
    var workingWebpage = getWebpage(from: rosterURL)
    var didFinishIterating = false
    var urls = [URL]()
    
    repeat {
        let urlSuffix = workingWebpage.substring(startingTerm: playerURLLocation, endingAtFirst: "\"").dropLast()
        let urlString = baseURL + "/" + urlSuffix
        
        if !urls.contains(where: { $0.absoluteString == urlString }) {
            urls.append(URL(string: urlString)!)
        }
        
        let splitIndex = workingWebpage.index(workingWebpage.range(of: urlString)!.upperBound, offsetBy: urlSuffix.count)
        workingWebpage = String(workingWebpage[splitIndex...])
        didFinishIterating = workingWebpage.range(of: playerURLLocation) == nil
    } while !didFinishIterating
    
    return urls
}

func getPlayerHeader(from playerURL: URL) -> PlayerHeader? {
    let playerWebpage = getWebpage(from: playerURL.absoluteString)
    
    guard playerWebpage.contains("\"brthpl\":"), playerWebpage.contains("\"exp\":") else { return nil }
    
    let playerHeaderString = playerWebpage.substring(startingTerm: "\"ath\"", endingAtFirst: "}")
    let playerHeader = try! JSONDecoder().decode(PlayerHeader.self, from: playerHeaderString.data(using: .utf8)!)
    
    guard !playerHeader.isUnknownClass, playerHeader.position != .notAvailabile else { return nil }
    
    return playerHeader
}

func getPlayer(from playerURL: URL) -> Player? {
    guard let playerHeader = getPlayerHeader(from: playerURL) else { return nil }
    
    let playerSeasons = getPlayerSeasons(from: playerURL, shortName: playerHeader.shortName)
    
    return Player(name: playerHeader.displayName,
                  number: playerHeader.number,
                  position: playerHeader.position,
                  height: playerHeader.height,
                  weight: playerHeader.weight,
                  yearsOfExperience: playerHeader.yearsOfExperience,
                  origin: playerHeader.origin,
                  seasons: playerSeasons)
}

func getPlayerGameLog(in boxScoreURL: String, playerShortName shortName: String) -> Player.Season.GameLog? {
    var boxScoreWebpage = getWebpage(from: boxScoreURL)
    
    guard !boxScoreWebpage.contains("\"desc\":\"Postponed\",\"det\":\"Postponed\"") &&
            !boxScoreWebpage.contains("\"desc\":\"Canceled\",\"det\":\"Canceled\"") &&
            !boxScoreWebpage.contains("\"desc\":\"Forfeit\",\"det\":\"Forfeit\"") &&
            
            // this occurs if ESPN data is corrupt where the game was played but the score is listed as 0-0 (only happens with college games)
            !(SPORT_MODE.isCollege && boxScoreWebpage.contains("\"desc\":\"Final\",\"det\":\"Final\"") && boxScoreWebpage.contains("\"score\":\"0\""))
    else { return nil }
    
    if !boxScoreWebpage.contains("['__espnfitt__']") {
        for offset in (0...9) {
            sleep(UInt32(2 + offset))
            boxScoreWebpage = getWebpage(from: boxScoreURL, useCache: false)
            
            if boxScoreWebpage.contains("['__espnfitt__']") {
                break
            }
        }
        
        guard boxScoreWebpage.contains("['__espnfitt__']") else { return nil }
    }
    
    let fullPageJSON = boxScoreWebpage
        .components(separatedBy: "['__espnfitt__']")[1]
        .components(separatedBy: ";</script>")[0]
        .dropFirst()
    
    let fullPageBoxScore = try! JSONDecoder().decode(FullPageBoxScore.self, from: fullPageJSON.data(using: .utf8)!)
    
    var boxScoreIndex: Int!
    var statIndex: Int!
    var playerIndex: Int!
    
    for (currentBoxScoreIndex, boxScore) in fullPageBoxScore.boxScore.enumerated() {
        for (currentStatIndex, stat) in boxScore.stats.enumerated() {
            let isPlayerStatRow: (FullPageBoxScore.Page.Content.GamePackage.BoxScore.Stats.Player) -> Bool = { player in
                if player.info.shortName.lowercased() == shortName.lowercased() {
                    return true
                } else {
                    let firstName = shortName.components(separatedBy: " ")[0]
                    
                    if firstName.count == 2 && !firstName.contains(".") {
                        let lastName = shortName.components(separatedBy: " ")[1]
                        let newShortName = firstName.prefix(1) + ". " + lastName
                        
                        return player.info.shortName.lowercased() == newShortName.lowercased()
                    } else if shortName.contains(" Jr.") {
                        let newShortName = shortName.replace(" Jr.", with: "")
                        return player.info.shortName.lowercased() == newShortName.lowercased()
                    } else if player.info.shortName.components(separatedBy: ".").count == 3 {
                        let lastName = shortName.components(separatedBy: " ")[1]
                        let playerInfoLastName = player.info.shortName.components(separatedBy: " ")[1]
                        
                        if lastName == playerInfoLastName && shortName.prefix(1) == player.info.shortName.prefix(1) {
                            return true
                        } else {
                            return false
                        }
                    } else {
                        return false
                    }
                }
            }
            
            if let currentPlayerIndex = stat.players?.firstIndex(where: isPlayerStatRow) {
                boxScoreIndex = currentBoxScoreIndex
                statIndex = currentStatIndex
                playerIndex = currentPlayerIndex
            }
        }
    }
    
    guard boxScoreIndex != nil && statIndex != nil && playerIndex != nil else { return nil }
    
    let playerBoxScore = fullPageBoxScore.boxScore[boxScoreIndex].stats[statIndex].players![playerIndex].stats
    
    guard !playerBoxScore.isEmpty else { return nil }
    
    return Player.Season.GameLog(date: fullPageBoxScore.gameInfo.dateString.gameDate,
                                 didStart: fullPageBoxScore.boxScore[boxScoreIndex].stats[statIndex].type == .starters,
                                 minutesPlayed: .init(playerBoxScore[0]) ?? 0,
                                 stats: .init(statsArray: playerBoxScore.boxScoreToStatsArray))
}

func getPlayerSeasons(from playerURL: URL, shortName: String) -> [Player.Season] {
    let statsURLString = playerURL.absoluteString.replace("_/id", with: "stats/_/id")
    var statsWebpage = getWebpage(from: statsURLString)
    
    guard !statsWebpage.contains("No available information.") else { return [] }
    
    if !statsWebpage.contains("\"stat\"") {
        for offset in (0...9) {
            sleep(UInt32(2 + offset))
            statsWebpage = getWebpage(from: statsURLString, useCache: false)
            
            if statsWebpage.contains("\"stat\"") {
                break
            }
        }
        
        guard statsWebpage.contains("\"stat\"") else { return [] }
    }
    
    let seasonTotalsString = SPORT_MODE.isCollege ? "Season Totals" : "Regular Season Totals"
    let jsonStatsSegment = statsWebpage.substring(startingTerm: "\"stat\"", endingAtFirst: "<")
    
    let seasonAveragesSegment: String
    if jsonStatsSegment.contains("\"\(seasonTotalsString)\"") {
        let seasonTotalsSegment = jsonStatsSegment.substring(startingTerm: "\"\(seasonTotalsString)\"", endingAtFirst: "<")
        seasonAveragesSegment = jsonStatsSegment.replace(seasonTotalsSegment, with: "")
    } else {
        seasonAveragesSegment = jsonStatsSegment
    }
    
    let discardSegment = seasonAveragesSegment.substring(startingTerm: "\"car\"", endingAtFirst: "}")
    
    let rowOnlySegment: String
    if jsonStatsSegment.contains("\"\(seasonTotalsString)\"") {
        rowOnlySegment = seasonAveragesSegment
            .replace(discardSegment, with: "")
            .replace(",\"car\":,{\"ttl\":\"\(seasonTotalsString)\",", with: "!")
    } else {
        rowOnlySegment = seasonAveragesSegment
            .replace(discardSegment, with: "")
            .replace(",\"car\":],", with: "!")
    }
    
    let statsOnlySegment = rowOnlySegment.substring(startingTerm: "\"row\"", endingAtFirst: "!")
    
    var statsSegmentString = statsOnlySegment
    
    repeat {
        let objectSegment = "{\"" + statsSegmentString.substring(startingTerm: "{", endingAtFirst: "}")
        
        if objectSegment.contains("\"name\"") {
            let playerSeasonTeam = try! JSONDecoder().decode(PlayerSeasonTeam.self, from: objectSegment.data(using: .utf8)!)
            statsSegmentString = statsSegmentString.replace(objectSegment, with: "\"" + playerSeasonTeam.name + "\"")
        } else {
            statsSegmentString = statsSegmentString.replace(objectSegment + ",", with: "")
        }
    } while statsSegmentString.contains("{")
    
    let finalStatsSegmentString = statsSegmentString.replace("!", with: "")
    let finalStatsSegment = try! JSONDecoder().decode([[String]].self, from: finalStatsSegmentString.data(using: .utf8)!)
    
    var currentYearBaseURLComponents = statsURLString.replace("stats", with: "gamelog").components(separatedBy: "/")
    currentYearBaseURLComponents.removeLast()
    currentYearBaseURLComponents += ["type", SPORT_MODE.espnPathIndicator, "year"]
    
    let currentYearBaseURL = currentYearBaseURLComponents.joined(separator: "/") + "/"
    
    return finalStatsSegment.compactMap { statsArray in
        guard statsArray.count == 20 else { return nil }
        
        let seasonYear = Int("20" + statsArray[0].suffix(2))!
        
        // only grab last 5 years worth of data for player
        guard seasonYear >= CURRENT_SEASON_YEAR - 5 else { return nil }
        
        let currentURL = currentYearBaseURL + "\(seasonYear)"
        var currentYearWebpage = getWebpage(from: currentURL)
        
        guard !currentYearWebpage.contains("No available information.") else { return nil }
        
        if !currentYearWebpage.contains("\"events\":") {
            for offset in (0...9) {
                sleep(UInt32(2 + offset))
                currentYearWebpage = getWebpage(from: currentURL, useCache: false)
                
                if currentYearWebpage.contains("\"events\":") {
                    break
                }
            }
            
            guard currentYearWebpage.contains("\"events\":") else { return nil }
        }
        
        let fullPageJSON = currentYearWebpage
            .components(separatedBy: "['__espnfitt__']")[1]
            .components(separatedBy: ";</script>")[0]
            .dropFirst()
        
        let fullPageGameLog = try! JSONDecoder().decode(FullPageGameLog.self, from: fullPageJSON.data(using: .utf8)!)
        
        typealias GameLogEntry = FullPageGameLog.Page.Content.Player.GameLog.Group.Table.GameLogEntry
        
        let gameLogEntries: [GameLogEntry] = fullPageGameLog.page.content.player.gameLog.groups.flatMap {
            $0.tables.compactMap { $0.events }.flatMap { $0 }
        }
        
        let gameBoxScoreURLs = gameLogEntries.map {
            $0.outcome.gameURL.absoluteString.replace("/game/", with: "/boxscore/")
        }
        
        let gameLogs: [Player.Season.GameLog] = gameBoxScoreURLs.compactMap {
            getPlayerGameLog(in: $0, playerShortName: shortName)
        }
        
        return Player.Season(seasonYear: seasonYear, teamID: statsArray[1], gameLogs: gameLogs)
    }
}


// MARK: - Games

func getPreviousGame(from event: TeamSchedule.Events.Event, teamID: String) -> Team.PreviousGame? {
    let boxScoreWebpage = getWebpage(from: event.time.link.replace("/game/", with: "/boxscore/"))
    
    guard !boxScoreWebpage.contains("\"desc\":\"Postponed\",\"det\":\"Postponed\"") &&
            !boxScoreWebpage.contains("\"desc\":\"Canceled\",\"det\":\"Canceled\"") &&
            !boxScoreWebpage.contains("\"desc\":\"Forfeit\",\"det\":\"Forfeit\"") &&
            
            // this occurs if ESPN data is corrupt where the game was played but the score is listed as 0-0
            !(SPORT_MODE.isCollege && boxScoreWebpage.contains("\"desc\":\"Final\",\"det\":\"Final\"") && boxScoreWebpage.contains("\"score\":\"0\""))
    else { return nil }
    
    let fullPageJSON = boxScoreWebpage
        .components(separatedBy: "['__espnfitt__']")[1]
        .components(separatedBy: ";</script>")[0]
        .dropFirst()
    
    let fullPageBoxScore = try! JSONDecoder().decode(FullPageBoxScore.self, from: fullPageJSON.data(using: .utf8)!)
    
    let venue: Venue
    if event.opponent.isNeutralVenue {
        venue = .neutral
    } else {
        venue = event.opponent.homeAway == .home ? .away : .home
    }
    
    let gameLine = fullPageBoxScore.gameInfo.gameLine.flatMap { lineString -> Double? in
        let components = lineString.components(separatedBy: " ")
        guard components.count == 2 else { return nil }
        
        if components[0] == teamID {
            return Double(components[1])!
        } else {
            return Double(components[1].replace("-", with: ""))!
        }
    }
    
    let seasonType: Team.SeasonType = event.seasonType.abbreviation == .regularSeason ? .regularSeason : .postseason
    
    guard
        let teamLineScores = fullPageBoxScore.gameStripe.teams.first(where: { $0.teamID != event.opponent.teamID })?.lineScores,
        let opponentLineScores = fullPageBoxScore.gameStripe.teams.first(where: { $0.teamID == event.opponent.teamID })?.lineScores
    else { return nil } // this could return nil if either team is non-D1 as ESPN doesn't keep good data on non D1 teams and usually those games don't have lines anyway
    
    let teamFirstHalfScore = Int(teamLineScores[0].displayValue)! + (SPORT_MODE.isFourQuarterGame ? Int(teamLineScores[1].displayValue)! : 0)
    let teamSecondHalfScore = SPORT_MODE.isFourQuarterGame ? Int(teamLineScores[2].displayValue)! + Int(teamLineScores[3].displayValue)! : Int(teamLineScores[1].displayValue)!
    let opponentFirstHalfScore = Int(opponentLineScores[0].displayValue)! + (SPORT_MODE.isFourQuarterGame ? Int(opponentLineScores[1].displayValue)! : 0)
    let opponentSecondHalfScore = SPORT_MODE.isFourQuarterGame ? Int(opponentLineScores[2].displayValue)! + Int(opponentLineScores[3].displayValue)! : Int(opponentLineScores[1].displayValue)!
    
    let firstHalfScore = Team.PreviousGame.GameScore.Score(teamPoints: teamFirstHalfScore,
                                                           opponentPoints: opponentFirstHalfScore)
    
    let secondHalfScore = Team.PreviousGame.GameScore.Score(teamPoints: teamSecondHalfScore,
                                                            opponentPoints: opponentSecondHalfScore)
    
    let overtimeScores: [Team.PreviousGame.GameScore.Score]?
    if teamLineScores.count > 2 {
        let teamOvertimeLineScores = Array(teamLineScores.dropFirst(2))
        let opponentOvertimeLineScores = Array(opponentLineScores.dropFirst(2))
        
        overtimeScores = teamOvertimeLineScores.enumerated().map { index, lineScore in
            Team.PreviousGame.GameScore.Score(teamPoints: .init(lineScore.displayValue)!,
                                              opponentPoints: .init(opponentOvertimeLineScores[index].displayValue)!)
        }
    } else {
        overtimeScores = nil
    }
    
    let score = Team.PreviousGame.GameScore(firstHalf: firstHalfScore,
                                            secondHalf: secondHalfScore,
                                            overtimePeriods: overtimeScores)
    
    let matchupWebpage = getWebpage(from: event.time.link.replace("/game/", with: "/matchup/"))
    
    let largestLead: String?
    if matchupWebpage.contains("\"n\":\"largestLead\"") {
        let components = matchupWebpage.components(separatedBy: "\"n\":\"largestLead\"")
        if let abbreviation = components.first(where: { $0.contains("abbrv") && !$0.contains("\"abbrv\":\"\(event.opponent.teamID!)\"") }) {
            let lead = abbreviation.substring(startingTerm: "\"d\"", endingAtFirst: ",").replace("\"", with: "").dropLast()
            largestLead = String(lead)
        } else {
            largestLead = nil
        }
    } else {
        largestLead = nil
    }
    
    return Team.PreviousGame(date: event.date.dateString.gameDate,
                             opponentID: event.opponent.teamID!,
                             venue: venue,
                             didWin: event.result.didWin == true,
                             score: score,
                             line: gameLine,
                             overUnder: fullPageBoxScore.gameInfo.overUnder,
                             coverage: .init(channel: fullPageBoxScore.gameInfo.tvCoverageStation),
                             attendance: fullPageBoxScore.gameInfo.attendance,
                             venueCapacity: fullPageBoxScore.gameInfo.venueCapacity,
                             referees: fullPageBoxScore.gameInfo.referees.map { $0.name },
                             largestLead: largestLead.flatMap { .init($0) },
                             isConferenceMatchup: fullPageBoxScore.gameStripe.isConferenceMatchup,
                             seasonType: seasonType)
}

func getUpcomingGame(from event: TeamSchedule.Events.Event) -> Team.UpcomingGame {
    let pregameWebpage = getWebpage(from: event.time.link)
    
    let venue: Venue
    if event.opponent.isNeutralVenue {
        venue = .neutral
    } else {
        venue = event.opponent.homeAway == .home ? .away : .home
    }
    
    let seasonType: Team.SeasonType = event.seasonType.abbreviation == .regularSeason ? .regularSeason : .postseason
    
    let channel: String?
    if pregameWebpage.contains("Coverage<!-- -->: <!-- -->") {
        channel = String(pregameWebpage.substring(startingTerm: "Coverage<!-- -->: <!-- --", endingAtFirst: "<").dropLast())
    } else {
        channel = nil
    }
    
    let capacity: String?
    if pregameWebpage.contains("Capacity<!-- -->: <!-- -->") {
        capacity = String(pregameWebpage.substring(startingTerm: "Capacity<!-- -->: <!-- --", endingAtFirst: "<").dropLast())
            .replace(",", with: "")
    } else {
        capacity = nil
    }
    
    let isConferenceMatchup = Bool("\(pregameWebpage.substring(startingTerm: "\"isConferenceGame\"", endingAtFirst: ",").dropLast())")!
    
    return Team.UpcomingGame(date: event.date.dateString.gameDate,
                             opponentID: event.opponent.teamID!,
                             venue: venue,
                             coverage: channel.flatMap { .init(channel: $0) },
                             venueCapacity: capacity.flatMap { .init($0) },
                             isConferenceMatchup: isConferenceMatchup,
                             seasonType: seasonType)
}

func getGames(from scheduleURL: String, teamID: String) -> Team.Games {
    let teamSchedule = getTeamSchedule(from: scheduleURL)
    
    let previousGames: [Team.PreviousGame] = teamSchedule.events.previous
        .filter { $0.opponent.teamID != nil }
        .compactMap { getPreviousGame(from: $0, teamID: teamID) }
    
    let upcomingGames: [Team.UpcomingGame] = teamSchedule.events.upcoming
        .lazy
        .filter { !$0.time.link.isEmpty && $0.opponent.teamID != nil }
        .map { getUpcomingGame(from: $0) }
    
    return Team.Games(previous: previousGames, upcoming: upcomingGames)
}


// MARK: - National Rankings

func getNationalRankingsIfNeeded() -> [NationalRanking] {
    guard SPORT_MODE.isCollege else { return [] }
    
    let rankingsFileName = "nationalRankings.json"
    var currentNationalRankings = FileManager.default.getDecodedFileIfExists(fileName: rankingsFileName, todayOnly: false) ?? [NationalRanking]()
    
    let rankingsBaseURL = "https://www.espn.com/\(SPORT_MODE.espnPathIndicator)/rankings/_/week/"
    let initialRankingsCount = currentNationalRankings.count
    var currentWeek = initialRankingsCount + 1
    var currentRankingsURL = rankingsBaseURL + "\(currentWeek)" + "/year/\(CURRENT_SEASON_YEAR)/seasontype/2"
    var currentRankingsWebpage = getWebpage(from: currentRankingsURL)
    
    guard !currentRankingsWebpage.contains("No Data Available") else {
        return currentNationalRankings
    }
    
    repeat {
        let rankingsJSON = ("{" + currentRankingsWebpage.substring(startingTerm: "\"rankings\":[", endingAtFirst: "]") + "}")
            .replacingOccurrences(of: "\"currentRank\":\"\"", with: "\"currentRank\":-1")
        
        let rankings = try! JSONDecoder().decode(Rankings.self, from: rankingsJSON.data(using: .utf8)!)
        
        let nationalRankings = rankings.ranks.map { NationalRanking.Ranking(teamID: $0.team.teamID, ranking: $0.currentRank) }
        let nationalRanking = NationalRanking(week: currentWeek, rankings: nationalRankings)
        currentNationalRankings.append(nationalRanking)
        
        currentWeek += 1
        currentRankingsURL = rankingsBaseURL + "\(currentWeek)" + "/year/\(CURRENT_SEASON_YEAR)/seasontype/2"
        currentRankingsWebpage = getWebpage(from: currentRankingsURL)
    } while !currentRankingsWebpage.contains("No Data Available")
    
    if currentNationalRankings.count > initialRankingsCount {
        currentNationalRankings.export(as: rankingsFileName)
    }
    
    return currentNationalRankings
}


// MARK: - Depth Chart

func getDepthChart(for teamID: String) -> [Team.DepthChart]? {
    guard !SPORT_MODE.isCollege else { return nil }
    
    let depthChartURL = "https://www.espn.com/\(SPORT_MODE.espnPathIndicator)/team/depth/_/id/\(teamID)"
    let depthChartWebpage = getWebpage(from: depthChartURL)
    
    guard depthChartWebpage.contains("dethTeamGroups") else { return nil }
    
    let depthChartSegment = depthChartWebpage
        .components(separatedBy: "dethTeamGroups")[1]
        .components(separatedBy: "glossary")[0]
        .dropFirst(3)
        .dropLast(3)
    
    let depthChartList = try! JSONDecoder().decode(DepthChartList.self, from: depthChartSegment.data(using: .utf8)!)
    
    return depthChartList.rows.map { positionChart in
        let starter = Team.DepthChart.PlayerWithStatus(name: positionChart[1].playerInfo!.name, status: positionChart[1].playerInfo!.status)
        
        let orderedBackups = positionChart.dropFirst(2).map {
            Team.DepthChart.PlayerWithStatus(name: $0.playerInfo!.name, status: $0.playerInfo!.status)
        }
        
        return Team.DepthChart(position: positionChart[0].position!,
                               starter: starter,
                               orderedBackups: orderedBackups)
    }
}
