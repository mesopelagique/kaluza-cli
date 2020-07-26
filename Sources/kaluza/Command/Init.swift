//
//  InitCommand.swift
//  kaluza
//
//  Created by phimage on 08/03/2020.
//  Copyright © 2020 phimage. All rights reserved.
//

import Foundation
import ArgumentParser

struct Init: ParsableCommand {

    static let configuration = CommandConfiguration(abstract: "Initialize by creating a component.json file")

    @Flag(name: [.short, .long], help: "Generate it without having it ask any questions.")
    var force: Bool = false
    @Flag(name: [.short, .long], help: "Generate it without having it ask any questions.")
    var yes: Bool = false
    @Flag(help: "Show debug information.")
    var verbose: Bool = false

    func run() {
        Level.isDebug = verbose
        guard !componentURL.isFileExists else {
            log(.error, "Already initialized. \(componentFileName) exists")
            return
        }
        var component = Component()
        component.dependencies = []
        component.name = findName(for: componentURL)
        component.gitRemote = Init.findGitRemote(for: componentURL)
        let noQuestion = yes || force
        if !noQuestion {
            // could ask user some information
            print("name: (\(component.name ?? "")):")
            if let name = readLine(), !name.isEmpty {
                component.name = name
            }
            //version: (1.0.0)
            //description:
            print("description:")
            if let description = readLine(), !description.isEmpty {
                component.description = description
            }
            //entry point: (index.js)
            //git repository:
            print("git repository: (\(component.gitRemote ?? ""))")
            if let gitRemote = readLine(), !gitRemote.isEmpty {
                component.gitRemote = gitRemote
            }
            //keywords:
            print("keywords:")
            if let keywords = readLine(), !keywords.isEmpty {
                component.keywords = keywords.components(separatedBy: " ")
            }
            //author:
            print("author:")
            if let author = readLine(), !author.isEmpty {
                component.author = author
            }
            //license: (ISC)
            print("About to write to component.json:")

            print(String(data: (try? JSONEncoder.component.encode(component)) ?? Data(), encoding: .utf8) ?? "")

            // Is this OK? (yes)
            print("Is this OK? (yes)")
            if let confirm = readLine() {
                if confirm != "yes" && confirm != "y" && !confirm.isEmpty {
                    print("Aborted")
                    return
                }
            }
        }
        component.write(to: componentURL)
        log(.debug, "Initialized. \(componentFileName) created.")
    }

    func findName(for url: URL) -> String? {
        let directory = url.deletingLastPathComponent()
        let project = directory.appendingPathComponent("Project", isDirectory: true)
        if let projectFile = project.children.filter({ $0.pathExtension == projectExtension }).first {
            return projectFile.deletingPathExtension().lastPathComponent
        } else {
            return directory.lastPathComponent
        }
    }

    static func findGitRemote(for url: URL) -> String? {
        do {
            var arguments = ["remote"]
            let outputs = try Bash.execute(commandName: "git", arguments: arguments) ?? ""
            log(.debug, outputs)
            for output in outputs.split(separator: "\n") {
                if !output.isEmpty {
                    arguments = ["remote", "get-url", output.replacingOccurrences(of: "\n", with: "")]
                    let output2 = try Bash.execute(commandName: "git", arguments: arguments) ?? ""
                    log(.debug, output2)
                    if output2.contains("http") {
                        return output2.replacingOccurrences(of: "\n", with: "")
                    }
                }
            }
        } catch {
            log(.error, "\(error)")
        }
        return nil
    }

}
