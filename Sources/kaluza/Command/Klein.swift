//
//  Klein.swift
//  
//
//  Created by phimage on 25/04/2020.
//

import Foundation
import ArgumentParser

struct Klein: ParsableCommand {

    static let configuration = CommandConfiguration(abstract: "Install kaluza component")
    let path = "mesopelagique/Kaluza"

    @Flag(help: "Prevents using 4dz binaries.")
    var noBin: Bool = false

    @Flag(name: [.customShort("g"), .long], help: "Install to a global storage.")
    var global: Bool = false

    @Flag(name: [.customShort("f"), .long], help: "Force (for git command).")
    var force: Bool = false

    @Flag(help: "Show debug information.")
    var verbose: Bool = false

    var dependencyType: DependencyType {
        return .dev
    }

    var url: URL? {
        if global {
            let url: URL = .globalComponent
            if !url.isFileExists {
                Component().write(to: url)
            }
            return url
        } else {
            guard componentURL.isFileExists else {
                let url: URL = .globalComponent
                if !url.isFileExists {
                    Component().write(to: url)
                }
                return url
            }
            return componentURL
        }
    }

    func run() {
        Level.isDebug = verbose
        guard let componentURL = self.url else {
            return
        }
        guard var component = Component.read(from: componentURL) else {
            return
        }

        let binary = !noBin
        var dependencies: [Dependency]

        var warnIfInstalled = false

        dependencies = [component.addCommand(path: path, type: dependencyType)]

        component.write(to: componentURL)
        warnIfInstalled = true // warn only if install one package

        for dependency in dependencies {
            dependency.install(binary: binary, warnIfInstalled: warnIfInstalled, global: global, force: force)
        }
    }

}
