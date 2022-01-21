//
//  DiskWriter.swift
//  
//
//  Created by Patrick Gatewood on 1/20/22.
//

import Foundation

protocol DiskWriting {
    func write(_ string: String, toFile path: String) throws
}

struct DiskWriter: DiskWriting {
    func write(_ string: String, toFile path: String) throws {
        try string.write(toFile: path, atomically: true, encoding: .utf8)
    }
}
