//
//  Upgrade.swift
//  
//
//  Created by phimage on 26/04/2020.
//

import Foundation
import ArgumentParser

struct Upgrade: ParsableCommand {

    static let configuration = CommandConfiguration(abstract: "Upgrade kaluza")
 
    let url = URL(string: "https://mesopelagique.github.io/kaluza-cli/install.sh")!
    
    func run() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("install-kaluza.sh")
        try? FileManager.default.removeItem(at: tempURL)
        guard url.download(to: tempURL) else {
            log(.error, "Failed to download the upgrade script")
            return
        }
        do {
            // TODO maybe process must be killed to be replaced
            if let output = try Bash.execute(commandName: "sh", arguments: [tempURL.path]) {
                log(.info, output)
            }
        } catch {
            log(.error, "\(error)")
        }
    }

}
