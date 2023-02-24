//
//  WebScraperModels.swift
//  GamePredictor
//
//  Created by Justin on 1/5/23.
//

import Foundation

struct TeamHeader: Decodable {
    let espnID: String
    let abbreviation: String
    let displayName: String
    let shortDisplayName: String
    let logoURL: URL
    let teamColor: String?
    let recordSummary: String
    let standingSummary: String
    let nationalRanking: Int?
    let location: String
    let links: String
    
    var conference: String {
        standingSummary.isEmpty ? "Independent" : standingSummary.components(separatedBy: " in ")[1]
    }
    
    var conferenceRanking: Int {
        let conferenceSubstring = standingSummary.components(separatedBy: " in ")[0]
        let onlyNumbersString = conferenceSubstring.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(onlyNumbersString) ?? 0
    }
    
    enum CodingKeys: String, CodingKey {
        case espnID = "id"
        case abbreviation = "abbrev"
        case displayName
        case shortDisplayName
        case logoURL = "logo"
        case teamColor
        case recordSummary
        case standingSummary
        case nationalRanking = "rank"
        case location
        case links
    }
}

struct PlayerHeader: Decodable {
    let birthPlace: String
    let position: Player.Position
    let status: Status
    let `class`: Player.Class
    let heightWeightString: String?
    let firstName: String
    let lastName: String
    let displayName: String
    let headshotURL: URL?
    let displayNumber: String?
    let teamShortName: String
    
    var number: Int {
        displayNumber.flatMap { Int($0.replace("#", with: "")) } ?? 0
    }
    
    var height: Player.Height? {
        guard
            let heightString = heightWeightString?.components(separatedBy: ", ")[0],
            let feet = Int(heightString.components(separatedBy: " ")[0].replace("'", with: "")),
            let inches = Int(heightString.components(separatedBy: " ")[1].replace("\"", with: ""))
        else { return nil }
        
        return .init(feet: feet, inches: inches)
    }
    
    var weight: Int? {
        guard let weightString = heightWeightString?.components(separatedBy: ", ")[1] else { return nil }
        return Int(weightString.replace(" lbs", with: ""))
    }
    
    var origin: Player.Origin {
        let stateList = [
            "AL", "AK", "AZ", "AR", "AS", "CA", "CO", "CT", "DE",
            "DC", "FL", "GA", "GU", "HI", "ID", "IL", "IN", "IA",
            "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS",
            "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC",
            "ND", "MP", "OH", "OK", "OR", "PA", "PR", "RI", "SC",
            "SD", "TN", "TX", "TT", "UT", "VT", "VA", "VI", "WA",
            "WA", "WV", "WI", "WY"
        ]
        
        if let lastBirthPlaceComponent = birthPlace.components(separatedBy: " ").last {
            return stateList.contains(lastBirthPlaceComponent) ? .local : .international
        } else {
            return .international
        }
    }
    
    var shortName: String {
        firstName.count == 2 ? displayName : firstName.prefix(1) + ". " + lastName
    }
    
    enum Status: String, Decodable {
        case active = "Active"
        case inactive = "Inactive"
    }
    
    enum CodingKeys: String, CodingKey {
        case birthPlace = "brthpl"
        case position = "pos"
        case status = "sts"
        case `class` = "exp"
        case heightWeightString = "htwt"
        case firstName = "fNm"
        case lastName = "lNm"
        case displayName = "dspNm"
        case headshotURL = "img"
        case displayNumber = "dspNum"
        case teamShortName = "tmSh"
    }
}

struct PlayerSeasonTeam: Decodable {
    let name: String
    let teamLinkPath: String?
    let logoURL: URL?
    
    var teamLink: URL? {
        guard let teamLinkPath = teamLinkPath else { return nil }
        return .init(string: "https://www.espn.com\(teamLinkPath)")!
    }
    
    enum CodingKeys: String, CodingKey {
        case name
        case teamLinkPath = "href"
        case logoURL = "logo"
    }
}

struct GameLogEntry: Decodable {
    let outcome: Outcome
    
    enum CodingKeys: String, CodingKey {
        case outcome = "res"
    }
    
    struct Outcome: Decodable {
        let gameURL: URL
        
        enum CodingKeys: String, CodingKey {
            case gameURL = "href"
        }
    }
}

struct FullPageBoxScore: Decodable {
    let page: Page
    
    var gameStripe: Page.Content.GamePackage.GameStripe {
        page.content.gamePackage.gameStripe
    }
    
    var gameInfo: Page.Content.GamePackage.GameInfo {
        page.content.gamePackage.gameInfo
    }
    
    var boxScore: [Page.Content.GamePackage.BoxScore] {
        page.content.gamePackage.boxScore
    }
    
    struct Page: Decodable {
        let content: Content
        
        struct Content: Decodable {
            let gamePackage: GamePackage
            
            struct GamePackage: Decodable {
                let gameStripe: GameStripe
                let gameInfo: GameInfo
                let boxScore: [BoxScore]
                
                struct GameStripe: Decodable {
                    let teams: [TeamResult]
                    let isConferenceMatchup: Bool
                    
                    struct TeamResult: Decodable {
                        let teamID: String?
                        let lineScores: [LineScore]
                        
                        struct LineScore: Decodable {
                            let displayValue: String
                        }
                        
                        enum CodingKeys: String, CodingKey {
                            case teamID = "abbrev"
                            case lineScores = "linescores"
                        }
                    }
                    
                    enum CodingKeys: String, CodingKey {
                        case teams = "tms"
                        case isConferenceMatchup = "isConferenceGame"
                    }
                }
                
                struct GameInfo: Decodable {
                    let attendance: Int
                    let venueCapacity: Int
                    let venueName: String
                    let venueLocation: VenueLocation
                    let tvCoverageStation: String
                    let gameLine: String?
                    let overUnder: Double?
                    let dateString: String
                    let referees: [Referee]
                    
                    struct VenueLocation: Decodable {
                        let city: String
                        let state: String
                    }
                    
                    struct Referee: Decodable {
                        let name: String
                        let position: String
                        
                        enum CodingKeys: String, CodingKey {
                            case name = "dspNm"
                            case position = "pos"
                        }
                    }
                    
                    enum CodingKeys: String, CodingKey {
                        case attendance = "attnd"
                        case venueCapacity = "cpcty"
                        case venueName = "loc"
                        case venueLocation = "locAddr"
                        case tvCoverageStation = "cvrg"
                        case gameLine = "lne"
                        case overUnder = "ovUnd"
                        case dateString = "dtTm"
                        case referees = "refs"
                    }
                }
                
                struct BoxScore: Decodable {
                    let team: Team
                    let stats: [Stats]
                    
                    struct Team: Decodable {
                        let teamID: String?
                        let name: String
                        let shortName: String
                        
                        enum CodingKeys: String, CodingKey {
                            case teamID = "abbrev"
                            case name = "dspNm"
                            case shortName = "nm"
                        }
                    }
                    
                    struct Stats: Decodable {
                        let players: [Player]?
                        let type: StatTableType
                        
                        struct Player: Decodable {
                            let info: Info
                            let stats: [String]
                            
                            struct Info: Decodable {
                                let shortName: String
                                
                                enum CodingKeys: String, CodingKey {
                                    case shortName = "shrtNm"
                                }
                            }
                            
                            enum CodingKeys: String, CodingKey {
                                case stats
                                case info = "athlt"
                            }
                        }
                        
                        enum StatTableType: String, Decodable {
                            case starters
                            case bench
                            case totals
                        }
                        
                        enum CodingKeys: String, CodingKey {
                            case players = "athlts"
                            case type
                        }
                    }
                    
                    enum CodingKeys: String, CodingKey {
                        case team = "tm"
                        case stats
                    }
                }
                
                enum CodingKeys: String, CodingKey {
                    case gameStripe = "gmStrp"
                    case gameInfo = "gmInfo"
                    case boxScore = "bxscr"
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case gamePackage = "gamepackage"
            }
        }
    }
}

struct TeamSchedule: Decodable {
    let season: Int
    let seasonType: SeasonType
    let events: Events
    
    struct SeasonType: Decodable {
        let abbreviation: SeasonAbbreviation
        
        enum SeasonAbbreviation: String, Decodable {
            case regularSeason = "reg"
            case postseason = "post"
        }
    }
    
    struct Events: Decodable {
        let previous: [Event]
        let upcoming: [Event]
        
        struct Event: Decodable {
            let date: EventDate
            let time: EventTime
            let opponent: Opponent
            let broadcastInfo: [Broadcast]
            let result: EventResult
            let seasonType: SeasonType
            
            struct EventDate: Decodable {
                let dateString: String
                
                enum CodingKeys: String, CodingKey {
                    case dateString = "date"
                }
            }
            
            struct EventTime: Decodable {
                let link: String
            }
            
            struct Opponent: Decodable {
                let teamID: String?
                let shortName: String
                let homeAway: HomeAway
                let isNeutralVenue: Bool
                
                enum HomeAway: String, Decodable {
                    case home = "vs"
                    case away = "@"
                }
                
                enum CodingKeys: String, CodingKey {
                    case teamID = "abbrev"
                    case shortName = "shortDisplayName"
                    case homeAway = "homeAwaySymbol"
                    case isNeutralVenue = "neutralSite"
                }
            }
            
            struct Broadcast: Decodable {
                let station: String
                
                enum CodingKeys: String, CodingKey {
                    case station = "name"
                }
            }
            
            struct EventResult: Decodable {
                let didWin: Bool?
                let currentTeamScore: String?
                let opponentTeamScore: String?
                let overtimeInfo: String?
                
                enum CodingKeys: String, CodingKey {
                    case didWin = "winner"
                    case currentTeamScore
                    case opponentTeamScore
                    case overtimeInfo = "overtime"
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case date
                case time
                case opponent
                case broadcastInfo = "network"
                case result
                case seasonType
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case previous = "post"
            case upcoming = "pre"
        }
    }
}

struct TeamsList: Decodable {
    let columns: [Column]
    
    struct Column: Decodable {
        let groups: [Group]
        
        struct Group: Decodable {
            let conferenceName: String
            let teams: [Team]
            
            struct Team: Decodable {
                let teamName: String
                let teamLogo: URL
                let teamNumericID: String
                let links: [Link]
                
                struct Link: Decodable {
                    let linkType: LinkType
                    let linkPath: String
                    let linkDestinationType: LinkDestinationType
                    
                    enum LinkType: String, Decodable {
                        case clubhouse
                        case stats
                        case schedule
                        case roster
                        case tickets
                    }
                    
                    enum LinkDestinationType: Int, Decodable {
                        case `internal`
                        case external
                    }
                    
                    enum CodingKeys: String, CodingKey {
                        case linkType = "t"
                        case linkPath = "u"
                        case linkDestinationType = "e"
                    }
                }
                
                enum CodingKeys: String, CodingKey {
                    case teamName = "n"
                    case teamLogo = "p"
                    case teamNumericID = "id"
                    case links = "lk"
                }
            }
            
            enum CodingKeys: String, CodingKey {
                case conferenceName = "nm"
                case teams = "tms"
            }
        }
    }
}

struct NationalRanking: Codable {
    let week: Int
    let rankings: [Ranking]
    
    struct Ranking: Codable {
        let teamID: String
        let ranking: Int
    }
}

struct Rankings: Decodable {
    let ranks: [Rank]
    
    struct Rank: Decodable {
        let currentRank: Int
        let team: Team
        
        struct Team: Decodable {
            let teamID: String
            
            enum CodingKeys: String, CodingKey {
                case teamID = "abbrev"
            }
        }
    }
}
