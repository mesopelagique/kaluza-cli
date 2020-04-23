//
//  AddCommand.swift
//  kaluza
//
//  Created by phimage on 08/03/2020.
//  Copyright © 2020 phimage. All rights reserved.
//

import Foundation
import ArgumentParser

struct Add: ParsableCommand {

    static let configuration = CommandConfiguration(abstract: "Add dependencies without installing it")

    @Argument(help: "The dependency path: <githubname>/<githubrepo>(@<version).")
    var path: String

    @Flag(name: [.customShort("D"), .long], help: "Save as dev dependencies.")
    var saveDev: Bool
    @Flag(name: [.customShort("O"), .long], help: "Save as optional dependencies.")
    var saveOptional: Bool

    var dependencyType: DependencyType {
        return saveDev ? .dev: (self.saveOptional ? .optional : .standard)
    }

    @Flag(name: [.customShort("g"), .long], help: "Install to a global storage.")
    var global: Bool

    @Flag(help: "Show debug information.")
    var verbose: Bool

    var url: URL? {
        if global {
            let url: URL = .globalComponent
            if !url.isFileExists {
                Component().write(to: url)
            }
            return url
        } else {
            guard componentURL.isFileExists else {
                log(.error, "\(componentFileName) does not exists. Please init first.")
                return nil
            }
            return componentURL
        }
    }

    func run() {
        Level.isDebug = verbose
        guard let componentURL = url else {
            return
        }

        guard var component = Component.read(from: componentURL) else {
            return
        }

        _ = component.addCommand(path: path, type: dependencyType)
        component.write(to: componentURL)
    }

}
extension Component {
    mutating func addCommand(path: String, type: DependencyType = .standard) -> Dependency {
        let newDependency = Dependency(path: path)

        let find = self.allDependencies.filter({ $0.path == newDependency.path})
        if let installedDep = find.first {
            log(.info, "\(path) is already added")
            let findInType = self.allDependencies.filter({ $0.path == newDependency.path})
            if findInType.isEmpty {
                log(.error, "but not in wanted dependency type \(type)")
            }

            return installedDep
        }

        var dependencies = self.dependencies(for: type)
        dependencies.append(newDependency)
        self.setDependencies(dependencies, for: type)

        return newDependency
    }
}

extension JSONEncoder {
    static var component: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
