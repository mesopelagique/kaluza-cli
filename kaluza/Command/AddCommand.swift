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
        addCommand(path: args[2], dev: isDev)
    }

    static func addCommand(path: String, dev: Bool = false, version: String? = nil) {
        guard componentURL.isFileExists else {
            log(.error, "No \(componentFileName) file. Do an init before")
            return
        }
        
        guard var component = Component.read(from: componentURL) else {
            return
        }
        
        guard component.allDependencies.filter( { $0.path == path}).isEmpty else {
            log(.error, "\(path) is already added")
            return
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
        
    }
}

