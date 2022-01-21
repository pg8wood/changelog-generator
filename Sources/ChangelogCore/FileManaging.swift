//
//  FileManaging.swift
//  
//
//  Created by Patrick Gatewood on 1/20/22.
//

import Foundation

protocol FileManaging {
    func removeItem(at URL: URL) throws
    func fileExists(atPath path: String) -> Bool
    func createDirectory(
        at url: URL,
        withIntermediateDirectories createIntermediates: Bool,
        attributes: [FileAttributeKey: Any]?
    ) throws
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?,
        options mask: FileManager.DirectoryEnumerationOptions
    ) throws -> [URL]
}

extension FileManaging {
    func contentsOfDirectory(
        at url: URL,
        includingPropertiesForKeys keys: [URLResourceKey]?
    ) throws -> [URL] {
        try contentsOfDirectory(
            at: url,
            includingPropertiesForKeys:
                keys,
            options: []
        )
    }
}

extension FileManager: FileManaging { }
