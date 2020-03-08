//
//  main.swift
//  kaluza
//
//  Created by phimage on 08/03/2020.
//  Copyright © 2020 phimage. All rights reserved.
//

import Foundation

let componentFileName = "component.json"
let componentURL = URL(fileURLWithPath: componentFileName)
let projectExtension = "4DProject"

func usage(_ commandLinePath: String) {
    let commandLineName = URL(fileURLWithPath: commandLinePath).lastPathComponent
    log(.info, "Usage: \(commandLineName) <command>")
    log(.info, "")
    log(.info, "where <command> is one of:")
    log(.info, "    \(CommandType.allCases.map({$0.rawValue}).joined(separator: ", "))")
    //log(.info, "- install")
}
let args = CommandLine.arguments
guard args.count > 1 else {
    usage(args[0])
    exit(1)
}

guard let commandType = CommandType(rawValue: args[1]) else {
    log(.error, "Unknown command \(args[1])")
    usage(args[0])
    exit(2)
}

commandType.command.run(args: args)
