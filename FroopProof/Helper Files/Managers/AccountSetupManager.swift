//
//  AccountSetupManager.swift
//  FroopProof
//
//  Created by David Reed on 1/28/24.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class AccountSetupManager: ObservableObject { 
    static let shared = AccountSetupManager()
    @ObservedObject var myData = MyData.shared
    
    var db = FirebaseServices.shared.db
    var uid = Auth.auth().currentUser?.uid ?? ""

    func createUserAndCollections(uid: String, completion: @escaping (Error?) -> Void) {
        let userDocRef = db.collection("users").document(uid)
        
        createOrUpdateUserDocument(uid: uid) { error in
            guard error == nil else {
                completion(error)
                return
            }
            
            self.createUserSubcollections(for: userDocRef) { error in
                guard error == nil else {
                    completion(error)
                    return
                }
                
                self.createFroopDecisionsDocumentAndSubcollections(uid: uid) { error in
                    completion(error)
                }
            }
        }
    }
    
    func createOrUpdateUserDocument(uid: String, completion: @escaping (Error?) -> Void) {
        let userDocRef = db.collection("users").document(uid)
        let fcmToken = getUserFcmToken() ?? ""

        Task {
            do {
                let documentSnapshot = try await userDocRef.getDocument()
                if documentSnapshot.exists {
                    let data = ["froopUserID": uid, "fcmToken": fcmToken]
                    try await userDocRef.updateData(data)
                } else {
                    var data = MyData.shared.dictionary
                    data["froopUserID"] = uid
                    data["fcmToken"] = fcmToken
                    try await userDocRef.setData(data)
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    func createUserSubcollections(for userDocRef: DocumentReference, completion: @escaping (Error?) -> Void) {
        let collectionsInsideUser = ["myFroops", "froopDecisions"]
        let froopUID = "froop"
        let froopFriendRef = db.collection("users").document(froopUID).collection("friends").document("friendList")
       
        Task {
            do {
                for collection in collectionsInsideUser {
                    let newDocRef = userDocRef.collection(collection).document("placeholder")
                    // Check if "placeholder" document exists before setting data
                    let docSnapshot = try await newDocRef.getDocument()
                    if !docSnapshot.exists {
                        try await newDocRef.setData(["placeholder": "placeholder"])
                    }
                }
                
                // Creating the friendList document within the friends collection if it doesn't exist
                // Attempt to retrieve the friendList document first to check if it exists
                let friendListDocRef = userDocRef.collection("friends").document("friendList")
                let friendListSnapshot = try await friendListDocRef.getDocument()

                // Check if the document already exists
                if !friendListSnapshot.exists {
                    // Document does not exist, safe to set data without overwriting existing data
                    try await friendListDocRef.setData(["friendUIDs": ["froop"]])
                } else {
          
                }
                
                // Update Froop's friendList to include current user's UID without overwriting
                try await froopFriendRef.updateData(["friendUIDs": FieldValue.arrayUnion([uid])])
                
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    
    func createFroopDecisionsDocumentAndSubcollections(uid: String, completion: @escaping (Error?) -> Void) {
        let froopDecisionsDocRef = db.collection("froopDecisions").document(uid).collection("froopLists").document("placeholder")
        let collectionsInsideFroopLists = ["myArchivedList", "myConfirmedList", "myDeclinedList", "myInvitesList"]

        Task {
            do {
                // Check if "placeholder" document in "froopLists" exists before setting data
                let decisionsSnapshot = try await froopDecisionsDocRef.getDocument()
                if !decisionsSnapshot.exists {
                    try await froopDecisionsDocRef.setData(["placeholder": "placeholder"])
                }

                for collection in collectionsInsideFroopLists {
                    let newCollectionRef = froopDecisionsDocRef.collection(collection).document("placeholder")
                    // Check if "placeholder" document in each collection exists before setting data
                    let collectionSnapshot = try await newCollectionRef.getDocument()
                    if !collectionSnapshot.exists {
                        try await newCollectionRef.setData(["placeholder": "placeholder"])
                    }
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    
    func getUserFcmToken() -> String? {
        // Check if the user is authenticated
        guard let uid = Auth.auth().currentUser?.uid, !uid.isEmpty else {
            PrintControl.shared.printErrorMessages("User is not authenticated. Unable to retrieve fcmToken.")
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User is not authenticated. Unable to retrieve fcmToken."])
            Crashlytics.crashlytics().record(error: error) // Log error to Crashlytics
            return nil
        }
        
        // Get the FCM token from user defaults
        let fcmToken = UserDefaults.standard.value(forKey: "FCMTokenNotification") as? String
        return fcmToken
    }
}
