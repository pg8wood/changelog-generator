//
//  InteractiveCommandRunner.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/20/21.
//

import Foundation

enum InteractiveCommandRunner {
    /// Runs an interactive command using `posix_spawn`. This is currently necessary due to a bug in [Process.standardInput](https://developer.apple.com/documentation/foundation/process/1411576-standardinput)
    /// that prevents child processes from inherting the parent process' stdin, despite the documentation claiming so.
    ///
    /// See: [this Swift forums discussion](https://forums.swift.org/t/how-to-allow-process-to-receive-user-input-when-run-as-part-of-an-executable-e-g-to-enabled-sudo-commands/34357)
    static func runCommand(_ command: String, completion: (() throws -> Void)? = nil) rethrows {
        var pid: pid_t = 0
        let args = ["sh", "-c", command]
        let envs = ProcessInfo().environment.map { k, v in "\(k)=\(v)" }
        try withCStrings(args) { cArgs in
            try withCStrings(envs) { cEnvs in
                var status = posix_spawn(&pid, "/bin/sh", nil, nil, cArgs, cEnvs)
                if status == 0 {
                    if (waitpid(pid, &status, 0) != -1) {
                        try completion?()
                    } else {
                        throw RunCommandError.WaitPIDError
                    }
                } else {
                    throw RunCommandError.POSIXSpawnError(status)
                }
            }
        }
    }
    
    private static func withCStrings(_ strings: [String], scoped: ([UnsafeMutablePointer<CChar>?]) throws -> Void) rethrows {
        let cStrings = strings.map { strdup($0) }
        try scoped(cStrings + [nil])
        cStrings.forEach { free($0) }
    }
    
    enum RunCommandError: Error {
        case WaitPIDError
        case POSIXSpawnError(Int32)
    }
}
