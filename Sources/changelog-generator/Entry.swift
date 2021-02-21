//
//  Entry.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/21/21.
//

import Foundation
import ArgumentParser

struct ChangelogEntry: Codable {
    let type: EntryType
    let text: String
}

enum EntryType: String, Codable, Comparable, ExpressibleByArgument, CaseIterable {
    static var allCasesSentenceString: String {
        allCases.map(\.rawValue).sentenceString
    }
    
    static func < (lhs: EntryType, rhs: EntryType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case addition
    case change
    case fix
    
    var title: String {
        switch self {
        case .addition: return "Added"
        case .change: return "Changed"
        case .fix: return "Fixed"
        }
    }
    
    init(_ string: String) throws {
        guard let entryType = EntryType(rawValue: string) else {
            throw ValidationError("Valid types are \(EntryType.allCasesSentenceString).")
        }
        
        self = entryType
    }
}

private extension BidirectionalCollection where Element: StringProtocol {
    var sentenceString: String {
        count <= 2 ?
            joined(separator: " and ") :
            dropLast().joined(separator: ", ") + ", and " + last!
    }
}
