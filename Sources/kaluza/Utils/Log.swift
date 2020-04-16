//
//  Log.swift
//  kaluza
//
//  Created by phimage on 08/03/2020.
//  Copyright © 2020 phimage. All rights reserved.
//

import Foundation
enum Level {
    case debug, info, error

    static var isDebug: Bool = false
}
func log(_ level: Level, _ message: String) {
    switch level {
    case .debug:
        if Level.isDebug {
            print("\(message)")
        }
    case .info:
      print("\(message)")
    case .error:
      fputs("Error: \(message)\n", stderr)
    }
}
