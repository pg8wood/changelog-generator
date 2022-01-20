//
//  MockFileManager.swift
//  
//
//  Created by Patrick Gatewood on 1/20/22.
//

import Foundation
@testable import ChangelogCore

struct MockFileManager: FileManaging {
    var removeItemHook: ((URL) throws -> Void ) = { _ in }
    var fileExistsHook: ((String) -> Bool) = { _ in true }
    var createDirectoryHook: ((URL, Bool, [FileAttributeKey: Any]?) throws -> Void) = { _, _, _ in }
    var contentsOfDirectoryHook: (
        (URL, [URLResourceKey]?, FileManager.DirectoryEnumerationOptions) throws -> [URL]
    ) = { _, _, _ in
        return []
    }
    
    func removeItem(at URL: URL) throws {
        try removeItemHook(URL)
    }
    
    func fileExists(atPath path: String) -> Bool {
        fileExistsHook(path)
    }
    
    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws {
        try createDirectoryHook(url, createIntermediates, attributes)
    }
    
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL] {
        try contentsOfDirectoryHook(url, keys, mask)
    }
}
