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

/// A type of changelog change as defined by Keep a Changelog 1.0.0.
///
/// https://keepachangelog.com/en/1.0.0/
enum EntryType: String, Codable, Comparable, ExpressibleByArgument, CaseIterable {
    static var allCasesSentenceString: String {
        let names = allCases.map(\.rawValue)
        return ListFormatter.localizedString(byJoining: names)
    }
    
    static func < (lhs: EntryType, rhs: EntryType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case add
    case change
    case deprecate
    case remove
    case fix
    case security
    
    var title: String {
        switch self {
        case .add: return "Added"
        case .change: return "Changed"
        case .deprecate: return "Deprecated"
        case .remove: return "Removed"
        case .fix: return "Fixed"
        case .security: return "Security"
        }
    }
    
    init(_ string: String) throws {
        guard let entryType = EntryType(rawValue: string) else {
            throw ValidationError("Valid types are \(EntryType.allCasesSentenceString).")
        }
        
        self = entryType
    }
}
