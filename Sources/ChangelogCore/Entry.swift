//
//  Entry.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/21/21.
//

import Foundation
import ArgumentParser

struct ChangelogEntry {
    let type: EntryType
    let text: String
    
    init(type: EntryType, text: String) {
        self.type = type
        self.text = text
    }
    
    init(contentsOf fileURL: URL) throws {
        let fileContents = try String(contentsOf: fileURL)
        var lines = fileContents.components(separatedBy: .newlines)
        let header = lines.removeFirst()
        
        guard let type = EntryType(title: header.components(separatedBy: .whitespaces).last) else {
            throw ChangelogError.malformattedEntry(atPath: fileURL.path)
        }
        
        self.type = type
        text = lines.joined(separator: "\n")
    }
}

/// A type of changelog change as defined by Keep a Changelog.
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
        EntryType.titles[self]!
    }
    
    private static let titles: [EntryType: String] = [
        .add: "Added",
        .change: "Changed",
        .deprecate: "Deprecated",
        .remove: "Removed",
        .fix: "Fixed",
        .security: "Security"
    ]
    private static var titlesToValues = Dictionary(uniqueKeysWithValues: titles.map({ ($1, $0) }))
    
    init(_ string: String) throws {
        guard let entryType = EntryType(rawValue: string) else {
            throw ValidationError("Valid types are \(EntryType.allCasesSentenceString).")
        }
        
        self = entryType
    }
    
    init?(title: String?) {
        guard let title = title,
              let entryType = EntryType.titlesToValues[title] else {
            return nil
        }
        
        self = entryType
    }
}
