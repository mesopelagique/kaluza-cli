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
            try! fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil) //swiftlint:disable:this force_try
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

import AsyncHTTPClient
import NIO
import NIOHTTP1
import NIOSSL

extension URL {

    /// download sync
    func download(to destinationURL: URL) -> Bool {
        var installed = false
        let httpClient = HTTPClient(eventLoopGroupProvider: .createNew) // XXX optimize using only one client
        defer {
            try? httpClient.syncShutdown()
        }
        do {
            let request = try HTTPClient.Request(url: self.absoluteString)
            let promise = httpClient.execute(request: request) // XXX maybe create HTTPClientResponseDelegate for big files and chunks
            let response: HTTPClient.Response = try promise.wait()
            if response.status == .ok {
                if let body = response.body, let bytes = body.getBytes(at: 0, length: body.readableBytes) {
                    try Data(bytes).write(to: destinationURL)
                    installed = true
                }
            }
        } catch {
            log(.error, "\(error)")
        }
        return installed
    }

}
