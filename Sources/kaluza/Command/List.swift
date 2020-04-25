//
//  File.swift
//  
//
//  Created by phimage on 25/04/2020.
//

import Foundation
import ArgumentParser

struct List: ParsableCommand {

    static let configuration = CommandConfiguration(abstract: "List added components")

    @Flag(name: [.long], help: "Display only the dependency tree for packages in dependencies.")
    var prod: Bool
    @Flag(name: [.long], help: "Display only the dependency tree for packages in devDependencies.")
    var dev: Bool

    // @Flag(name: [.long], help: "Show more information")
    // var long: Bool

    @Flag(name: [.customShort("g"), .long], help: "List packages in the global install prefix instead of in the current project.")
    var global: Bool

    @Flag(help: " Show information in JSON format.")
     var json: Bool

    var url: URL? {
        if global {
            let url: URL = .globalComponent
            if !url.isFileExists {
                Component().write(to: url)
            }
            return url
        } else {
            guard componentURL.isFileExists else {
                return nil
            }
            return componentURL
        }
    }

    func run() {
        guard let componentURL = url else {
            if json {
                log(.info, "{}")
            } else {
                log(.info, "<empty>")
            }
            return
        }

        guard let component = Component.read(from: componentURL) else {
            return
        }

        var componentToDisplay = Component()
        if dev {
            componentToDisplay.devDependencies = component.devDependencies
        } else if prod {
            componentToDisplay.dependencies = component.dependencies
        } else {
            componentToDisplay.dependencies = component.dependencies
            componentToDisplay.devDependencies = component.devDependencies
        }
        if json {
            let encoder: JSONEncoder = .component
            do {
                log(.info, String(data: try encoder.encode(componentToDisplay), encoding: .utf8) ?? "<failed to encode>")
            } catch {
                log(.error, "<failed to encode>")
            }
        } else {
            if let dependencies = componentToDisplay.dependencies {
                for dependency in dependencies {
                    log(.info, dependency.path)
                }
            }
            if let dependencies = componentToDisplay.devDependencies {
                for dependency in dependencies {
                    log(.info, dependency.path)
                }
            }
            if componentToDisplay.dependencies == nil && componentToDisplay.devDependencies == nil {
                log(.info, "<empty>")
            }
        }
    }

}
