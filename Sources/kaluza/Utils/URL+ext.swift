//
//  URL+ext.swift
//  kaluza
//
//  Created by phimage on 08/03/2020.
//  Copyright © 2020 phimage. All rights reserved.
//

import Foundation
import ZIPFoundation

let fileManager = FileManager.default
extension URL {

    var isFileExists: Bool {
        return fileManager.fileExists(atPath: self.path)
    }

    func remove() -> Bool {
        do {
            try fileManager.removeItem(at: self)
            return true
        } catch {
            log(.debug, "Failed to delete \(self.path): \(error)")
            return false
        }
    }

    var children: [URL] {
        return (try? fileManager.contentsOfDirectory(at: self, includingPropertiesForKeys: nil, options: []) ) ?? []
    }

    static var applicationSupportDirectory: URL {
        return fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    static var globalComponent: URL {
        let url = self.applicationSupportDirectory.appendingPathComponent("4D")
        if !url.isFileExists {
            try! fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return url.appendingPathComponent("kaluza.json")
    }

    static var appURL: URL {
        var url = URL(fileURLWithPath: "/Applications/4D.app")
        if url.isFileExists {
            return url
        }
        url = URL(fileURLWithPath: "/Applications/4D/4D.app")
        if url.isFileExists {
            return url
        }
        if  let founds = try? Bash.execute(commandName: "mdfind", arguments: ["-name", "4D.app"]),
            !founds.isEmpty, let path = founds.split(separator: "\n").first {
            return URL(fileURLWithPath: String(path))
        }
        log(.error, "4D app not found. /Applications/4D.app path used.")
        return URL(fileURLWithPath: "/Applications/4D.app")
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

    func unzip(to destinationURL: URL, delete: Bool = false) -> Bool {
        var unzipped = true

        do {
            try fileManager.unzipItem(at: self, to: destinationURL)
            unzipped = true
            if delete {
                _ = self.remove()
            }
        } catch {
            log(.error, "Failed to unzip \(self.path) to \(destinationURL.path):\(error)")
        }
        return unzipped
    }
}
