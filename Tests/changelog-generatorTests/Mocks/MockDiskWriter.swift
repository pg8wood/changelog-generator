//
//  File.swift
//  
//
//  Created by Patrick Gatewood on 1/20/22.
//

import Foundation
@testable import ChangelogCore

struct MockDiskWriter: DiskWriting {
    var writeHook: ((String, String) throws -> Void) = { _, _ in }
    
    func write(_ string: String, toFile path: String) throws {
       try writeHook(string, path)
    }
}
