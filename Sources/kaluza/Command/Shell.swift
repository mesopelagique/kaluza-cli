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
        if var input = readLine() {
            while(!input.isExitCmd) {
                let arguments = input.split(separator: " ").map({String($0)})
                do {
                    let command = try Kaluza.parseAsRoot(arguments)
                    try command.run()
                } catch {
                    log(.error, Kaluza.fullMessage(for: error))
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
        return self == "exit" || self == "quit"
    }
}
