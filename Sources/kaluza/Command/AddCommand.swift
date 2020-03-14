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
        let path = args[2]
        
        guard componentURL.isFileExists else {
            log(.error, "\(componentFileName) does not exists. Please init first.")
            return
        }
        
        guard var component = Component.read(from: componentURL) else {
            return
        }

        let dep = component.addCommand(path: path, dev: isDev)
        //dep.install(version: nil)
    }

}
extension Component {
    mutating func addCommand(path: String, dev: Bool = false, version: String? = nil) -> Dependency {
        var component = self
        let find = component.allDependencies.filter( { $0.path == path})
        if let installedDep = find.first {
            log(.info, "\(path) is already added")
            return installedDep
        }
        
        let newDependency = Dependency(path: path, version: version)
        if dev {
            if component.devDependencies == nil {
                component.devDependencies = []
            }
            component.devDependencies?.append(newDependency)
            
        } else {
            if component.dependencies == nil {
                component.dependencies = []
            }
            component.dependencies?.append(newDependency)
        }
        component.write(to: componentURL)
        
        return newDependency
    }
}
