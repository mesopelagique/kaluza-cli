//
//  AddCommand.swift
//  kaluza
//
//  Created by phimage on 08/03/2020.
//  Copyright © 2020 phimage. All rights reserved.
//

import Foundation

struct AddCommand: Command {

    static func run(args: [String]) {
        guard args.count > 2 else {
            log(.error, "Need path as argument")
            usage(args[0])
            exit(2)
        }
        let isDev = args.contains("--save-dev") || args.contains("-S")
        let isOptional = args.contains("--save-optional") || args.contains("-O")
        let type: DependencyType = isDev ? .dev: (isOptional ? .optional : .standard)
        let path = args[2]

        guard componentURL.isFileExists else {
            log(.error, "\(componentFileName) does not exists. Please init first.")
            return
        }

        guard var component = Component.read(from: componentURL) else {
            return
        }

        _ = component.addCommand(path: path, type: type)
    }

}
extension Component {
    mutating func addCommand(path: String, type: DependencyType = .standard) -> Dependency {
        var component = self
        let find = component.allDependencies.filter({ $0.path == path})
        if let installedDep = find.first {
            log(.info, "\(path) is already added")
            let findInType = component.allDependencies.filter({ $0.path == path})
            if findInType.isEmpty {
                log(.error, "but not in wanted dependency type \(type)")
            }

            return installedDep
        }

        let newDependency = Dependency(path: path)
        var dependencies = component.dependencies(for: type)
        dependencies.append(newDependency)
        component.setDependencies(dependencies, for: type)

        component.write(to: componentURL)

        return newDependency
    }
}
