//
//  URL+ext.swift
//  kaluza
//
//  Created by phimage on 08/03/2020.
//  Copyright © 2020 phimage. All rights reserved.
//

import Foundation

let fileManager = FileManager.default
extension URL {

    var isFileExists: Bool {
        return fileManager.fileExists(atPath: self.path)
    }

    var children: [URL] {
        return (try? fileManager.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: []) ) ?? []
    }

    /// download sync
    func download(to destinationURL: URL) -> Bool {
        var installed = false

        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession.shared.downloadTask(with: self) { localURL, urlResponse, error in
            if let localURL = localURL, let urlResponse = urlResponse as? HTTPURLResponse, urlResponse.statusCode == 200 {
                do {
                    try FileManager.default.moveItem(at: localURL, to: destinationURL)
                    installed = true
                } catch {
                    log(.error, "\(error)")
                }
            } else if let error = error {
                log(.error, "\(error)")
                log(.debug, "\(String(describing: urlResponse))")
            } else {
                log(.debug, "\(String(describing: urlResponse))")
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        return installed
    }
}
