//
//  Shell.swift
//  
//
//  Created by phimage on 26/04/2020.
//

import Foundation
import ArgumentParser

struct Shell: ParsableCommand {

    static let configuration = CommandConfiguration(abstract: "Interactive shell for test purpose")

    func run() {
        print("Welcome to kaluza version \(Version.current)")
        print("Type help for assistance")
        var line = 1
        print(" \(line)> ", terminator: "")
        var history: [String] = []
        if var input = readLine() {
            while !input.isExitCmd {
                history.append(input)
                if input.isPwdCmd {
                    print(FileManager.default.currentDirectoryPath)
                } else if input.isHistoryCmd {
                    for line in history where !line.isHistoryCmd {
                        print(line)
                    }
                } else if input.isVersionCmd {
                    print(Version.current)
                } else {
                    let arguments = input.split(separator: " ").map({String($0)})
                    do {
                        let command = try Kaluza.parseAsRoot(arguments)
                        try command.run()
                    } catch {
                        log(.info, Kaluza.fullMessage(for: error))
                        if "\(error)".contains("helpRequested") || "\(error)".contains("--help") { // private ;(
                            log(.info, "\nSHELL COMMANDS:")
                            log(.info, "  exit, quit, q".padding(toLength: 26, withPad: " ", startingAt: 0) +  "Quit this shell.")
                            log(.info, "  pwd".padding(toLength: 26, withPad: " ", startingAt: 0) + "Print current directory.")
                            log(.info, "  history, hist".padding(toLength: 26, withPad: " ", startingAt: 0) + "Print commands history.")
                            log(.info, "  version".padding(toLength: 26, withPad: " ", startingAt: 0) + "Print version.")
                        }
                    }
                }
                line+=1
                print(" \(line)> ", terminator: "")
                input = readLine() ?? ""
            }
        }
    }

}

fileprivate extension String {
    var isExitCmd: Bool {
        return self == "exit" || self == "quit" || self == "q"
    }
    var isPwdCmd: Bool {
        return self == "pwd"
    }
    var isHistoryCmd: Bool {
        return self == "history" || self == "hist"
    }
    var isVersionCmd: Bool {
        return self == "version" || self == "v"
    }
}
