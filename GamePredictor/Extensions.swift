//
//  Extensions.swift
//  GamePredictor
//
//  Created by Justin on 12/19/22.
//

import Foundation

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mmZ"
    return formatter
}()

extension String {
    var gameDate: Date {
        dateFormatter.date(from: self)!
    }
    
    func substring(startingTerm: String, endingAtFirst character: Character) -> String {
        let startTermRange = range(of: startingTerm)!
        let startingBound = index(startTermRange.upperBound, offsetBy: 1)
        
        var endIndexFound = false
        var currentOffset = 1
        
        repeat {
            if String(self[index(startingBound, offsetBy: currentOffset)]) == String(character) {
                endIndexFound = true
            } else {
                currentOffset += 1
            }
        } while !endIndexFound
        
        let endingBound = index(startingBound, offsetBy: currentOffset)
        return String(self[startingBound...endingBound])
    }
    
    func replace(_ initialTerm: String, with replacementTerm: String) -> String {
        replacingOccurrences(of: initialTerm, with: replacementTerm)
    }
}

extension Sequence where Iterator.Element == String {
    var boxScoreToStatsArray: [String] {
        var newArray = ["", "", "", ""] + self
        newArray.insert("", at: 6)
        newArray.insert("", at: 8)
        newArray.insert("", at: 10)
        
        let steals = newArray[15]
        let blocks = newArray[16]
        let turnovers = newArray[17]
        let personalFouls = newArray[18]
        newArray[15] = blocks
        newArray[16] = steals
        newArray[17] = personalFouls
        newArray[18] = turnovers
        
        return newArray
    }
    
    func sorted(using array: [String]) -> [String] {
        sorted { teamA, teamB in
            let parsedTeamA = teamA.replacingOccurrences(of: "not ", with: "")
            let parsedTeamB = teamB.replacingOccurrences(of: "not ", with: "")
            
            guard let first = array.firstIndex(of: parsedTeamA) else { return false }
            guard let second = array.firstIndex(of: parsedTeamB) else { return true }

            return first < second
        }
    }
}

extension Encodable {
    func export(as name: String) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        
        let data = try! encoder.encode(self)
        let path = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GamePredictor")
            .appendingPathComponent("Data")
            .appendingPathComponent(SPORT_MODE.league)
            .appendingPathComponent(name)
        
        try! data.write(to: path)
    }
}

extension Array where Element: Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()

        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }

        return result
    }
}

extension FileManager {
    func directoryExists(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = true
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }
}
