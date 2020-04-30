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
        guard var bashCommand = try execute(command: "/bin/bash", arguments: ["-l", "-c", "which \(commandName)"]) else { return "\(commandName) not found" }
        bashCommand = bashCommand.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        return try execute(command: bashCommand, arguments: arguments)
    }

    // MARK: Private

    static private func execute(command: String, arguments: [String] = []) throws -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        try process.run()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: String.Encoding.utf8)
        return output
    }
}
