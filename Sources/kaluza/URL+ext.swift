//
//  URL+ext.swift
//  kaluza
//
//  Created by phimage on 08/03/2020.
//  Copyright © 2020 phimage. All rights reserved.
//

import Foundation


extension URL {
    
    var isFileExists: Bool {
        return FileManager.default.fileExists(atPath: self.path)
    }
    
    var children: [URL] {
        return (try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: []) ) ?? []
    }
}
