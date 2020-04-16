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

    @Flag(help: "Generate it without having it ask any questions.")
    var force: Bool
    @Flag(help: "Generate it without having it ask any questions.")
    var yes: Bool

    func run() {
        guard !componentURL.isFileExists else {
            log(.error, "Already initialized. \(componentFileName) exists")
            return
        }
        var component = Component()
        component.dependencies = []
        component.name = findName(for: componentURL)
        let noQuestion = yes || force
        if !noQuestion {

            // TODO could ask user some information
            // package name: (toto) test
            //version: (1.0.0)
            //description:
            //entry point: (index.js)
            //git repository:
            //keywords:
            //author:
            //license: (ISC)
            //About to write to component.json:
            // output JSON
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

}
