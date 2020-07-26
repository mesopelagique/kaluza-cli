//
//  Bash.swift
//  
//
//  Created by phimage on 23/04/2020.
//

import Foundation

final class Bash {

    // MARK: - CommandExecuting

    static func execute(commandName: String, arguments: [String] = []) throws -> String? {
        let response = try run(commandPath: try command(name: commandName), arguments: arguments)
        if !response.isSuccess {
            throw BashError.response(response)
        }
        return response.output
    }

    static func run(commandName: String, arguments: [String] = []) throws -> BashResponse {
        return try run(commandPath: try command(name: commandName), arguments: arguments)
    }

    // MARK: Private

    static private func command(name: String) throws -> String {
        // XXX maybe cache name -> path for performance
        guard let bashCommand = try run(commandPath: "/bin/bash", arguments: ["-l", "-c", "which \(name)"]).output else {
            throw BashError.commandNotFound(name)
        }
        return bashCommand.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }

    static private func run(commandPath: String, arguments: [String] = []) throws -> BashResponse {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: commandPath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        let errorPipe = Pipe()
        process.standardError = errorPipe
        try process.run()
        process.waitUntilExit()
  
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        let code = process.terminationStatus
        return BashResponse(output: output, error: error, code: code)
    }
}

struct BashResponse {
    var output: String?
    var error: String?
    var code: Int32

    var isSuccess: Bool {
        return code == 0
    }
}

enum BashError: Error {
    case response(BashResponse)
    case commandNotFound(String)
}
