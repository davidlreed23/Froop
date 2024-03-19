//
//  Version.swift
//  FroopProof
//
//  Created by David Reed on 10/14/23.
//

import Foundation
import Firebase
import FirebaseFirestore
import SwiftUI

class VersionChecker: ObservableObject {
    static let shared = VersionChecker()
    @Published var versionCheck: Int = 31
    @Published var isLoadingVersion: Bool = true
    @Published var version = 31
    
    init() {
        checkVersion { [weak self] fetchedVersion in
            if let version = fetchedVersion {
                DispatchQueue.main.async {
                    self?.versionCheck = version
                    self?.isLoadingVersion = false
                }
            }
        }
    }
    
    func checkVersion(completion: @escaping (Int?) -> Void) {
        let docRef = Firestore.firestore().collection("versionControl").document("versionId")
            
        docRef.getDocument { (document, error) in
            if let error = error {
                PrintControl.shared.printVersion("Error fetching version: \(error.localizedDescription)")
                completion(nil)
            } else if let document = document, document.exists {
                let version = document.data()?["currentVersion"] as? Int
                PrintControl.shared.printVersion("Successfully fetched version: \(String(describing: version))") // Debug print
                completion(version)
            } else {
                PrintControl.shared.printVersion("Document does not exist")
                completion(nil)
            }
        }
    }
}
