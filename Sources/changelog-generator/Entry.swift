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
}
