//
//  FroopManager.swift
//  FroopProof
//
//  Created by David Reed on 4/15/23.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import SwiftUI
import UIKit
import Combine
import MapKit
import Kingfisher
import PhotosUI

class FroopManager: ObservableObject {
    static let shared = FroopManager()
    
    var froopHistoryService: FroopHistoryService {
        return FroopHistoryService.shared
    }
//    var selectedFroopHistory: FroopHistory {
//        return actualSelectedFroopHistory
//    }
    @ObservedObject var myData = MyData.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @Published var comeFrom = false
    @Published var videoThumbnail: UIImage = UIImage()
    @Published var videoUrl: String = ""
    
    @Published var selectedFroopUUID: String?
    @Published var selectedHost: UserData = UserData()
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var selectedFroopHistory: FroopHistory = defaultFroopHistory()
    
    @Published var updateFroopHistoryToggle: Bool = false
    @Published var invitedFriends: [UserData] = []
    @Published var confirmedFriends: [UserData] = []
    @Published var declinedFriends: [UserData] = []
    @Published var pendingFriends: [UserData] = []
   
    @Published var froopTypeCategory: String = ""
    @Published var froopsAndHosts: [FroopAndHost] = []
    @Published var froopDropPins: [FroopDropPin] = []
    
    @Published var froopHistory: [FroopHistory] = []
    
    @Published var froopHistoryCollection: [FroopHistory] = []
    
    @Published var isFroopFetchingComplete = true
    @Published var froopFeed: [FroopHostAndFriends] = []
    @Published var myFroopFeed: [FroopHostAndFriends] = []
    
    @Published var activeFroopHistories: [FroopHistory] = []
    @Published var chatEntered: Bool = false
    @Published var messageText: String = ""
    
    @Published var showVideoPlayer = false
    @Published var froopHolder: Froop = Froop(dictionary: [:])
    @Published var chatViewOpen: Bool = false
    @Published var userFriends: [UserData] = []
    @Published var froopMapOpen: Bool = false
    @Published var froopDetailOpen: Bool = false
    @Published var addFriendsOpen: Bool = false
    @Published var friendDetailOpen: Bool = false
    @Published var inviteExternalFriendsOpen: Bool = false
    @Published var froopHistoryFroop: Froop = Froop(dictionary: [:])
    @Published var froopHistoryHost: UserData = UserData()
    @Published var showData = false
    @Published var showChatView = false
    @Published var froopTemplates: [Froop] = []
    @Published var myUserData: UserData = UserData()
    @Published var areAllCardsExpanded: Bool = true
    @Published var hostedFroopCount: Int = 0
    @Published var archivedImages: [MediaData] = []
    @Published var archivedImageViewOpen = false
    @Published var archivedSelectedTab = 0
    @Published var numColumn = 3
    @Published var actualSelectedFroopHistory: FroopHistory
    @Published var activeConfirmedFriends: [UserData] = []
    @Published var showInviteUrlView: Bool = false
    @Published var froopInviteUrl: String = ""
    
    var appStateManager: AppStateManager {
        return AppStateManager.shared
    }
    
    var froopHistoryUpdateSubject = PassthroughSubject<Void, Never>()
    
    var getHostedFroopCount: [FroopHistory] {
        return froopHistory.filter { $0.froop.froopHost == uid }
    }
    
    var invitedListener: ListenerRegistration?
    var confirmedListener: ListenerRegistration?
    var declinedListener: ListenerRegistration?
    var froopListener: ListenerRegistration?
    var templateStoreListener: ListenerRegistration?
    var froopHistoryListener: ListenerRegistration?
    
    var db = FirebaseServices.shared.db
    let uid = FirebaseServices.shared.uid
    private let notificationCenter = FroopNotificationCenter()
    private var cancellables: Set<AnyCancellable> = []

    init() {
        actualSelectedFroopHistory = FroopManager.defaultFroopHistory()
        fetchUserData(for: uid) { result in
            switch result {
                case .success(let myUserData):
                    self.myUserData = myUserData
                    PrintControl.shared.printFroopManager("-------> Self.myUserData:  \(self.myUserData.firstName)")
                    PrintControl.shared.printFroopManager("-------> myUserData:  \(myUserData.firstName)")
                    
                case .failure(let error):
                    PrintControl.shared.printFroopManager("Error fetching user data: \(error.localizedDescription)")
            }
        }
        setupTemplateStoreListener()
        
        ListenerStateService.shared.froopUpdateSubject.sink { updatedFroop in
            // Find the matching FroopHistory in froopHistory and update it
            if let index = self.froopHistory.firstIndex(where: { $0.froop.froopId == updatedFroop.froopId }) {
                self.froopHistory[index].froop = updatedFroop
            }
        }.store(in: &cancellables)
        createFroopHistoryArray { froopHistory in
            PrintControl.shared.printFroopManager("froopHistory created \(froopHistory.count)")
        }
        
        Publishers.CombineLatest($froopHistory, $selectedFroopUUID)
            .sink { [weak self] updatedFroopHistory, updatedSelectedFroopUUID in
                if let strongSelf = self {
                    strongSelf.actualSelectedFroopHistory = updatedFroopHistory.first(where: { $0.froop.froopId == updatedSelectedFroopUUID }) ?? FroopManager.defaultFroopHistory()
                } else {
                    // Handle the case where self is nil if needed
                }
            }
            .store(in: &cancellables)
        
        froopHistoryUpdateSubject
            .sink { [weak self] in
                self?.handleFroopHistoryChanges()
                PrintControl.shared.printFroopManager("🤩🤔 .sink froopHistoryUpdateSubject is firing")
            }
            .store(in: &cancellables)
    }
    
    
    ///DATA FETCHING AND HANDLING
    
    func fetchUserData(for uid: String, completion: @escaping (Result<UserData, Error>) -> Void) {
        // Check if the uid is valid and not empty
        guard !uid.isEmpty else {
            let error = NSError(domain: "FroopManager", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Invalid or empty user ID provided."])
            completion(.failure(error))
            return
        }

        let usersRef = db.collection("users").document(uid)
        usersRef.getDocument { document, error in
            if let document = document, document.exists, let data = document.data() {
                if let user = UserData(dictionary: data) {
                    completion(.success(user))
                } else {
                    completion(.failure(NSError(domain: "FroopManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Error initializing UserData from document data."])))
                }
            } else if let error = error {
                completion(.failure(error))
            }
        }
    }
//
    func fetchAttendedFroops(for uid: String, completion: @escaping (Result<[FroopAndHost], Error>) -> Void) {
        let archivedFroopsRef = db.collection("users").document(uid).collection("myDecisions").document("froopLists").collection("myArchivedList")
        
        var froopsAndHosts: [FroopAndHost] = []
        
        archivedFroopsRef.getDocuments() { (querySnapshot, err) in
            if let err = err {
                PrintControl.shared.printFroopManager("Error fetching archived Froops: \(err.localizedDescription)")
                completion(.failure(err))
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                PrintControl.shared.printFroopManager("No documents found in archived Froops.")
                completion(.failure(NSError(domain: "FroopError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No documents found in archived Froops."])))
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            for document in documents {
                let data = document.data()
                
                if let froopHostUid = data["froopHost"] as? String, let froopId = data["froopId"] as? String {
                    dispatchGroup.enter()
                    
                    self.fetchUserData(for: froopHostUid) { (userResult: Result<UserData, Error>) in
                        switch userResult {
                            case .success(let froopHost):
                                PrintControl.shared.printFroopManager("Successfully fetched user data for \(froopHostUid)")
                                
                                self.fetchFroopData(froopId: froopId, froopHost: froopHostUid) { (froop) in
                                    if let froop = froop {
                                        PrintControl.shared.printFroopManager("Successfully fetched froop with ID \(froopId)")
                                        // Create FroopAndHost instance and append to an array
                                        let froopAndHost = FroopAndHost(froop: froop, host: froopHost)
                                        PrintControl.shared.printFroopManager("Created FroopAndHost object with froop ID: \(froopId) and host UID: \(froopHostUid)")
                                        froopsAndHosts.append(froopAndHost)
                                    } else {
                                        PrintControl.shared.printFroopManager("Failed to fetch froop with ID \(froopId)")
                                    }
                                    dispatchGroup.leave()
                                }
                            case .failure(let error):
                                PrintControl.shared.printFroopManager("Error fetching user data for froopHost: \(error)")
                                dispatchGroup.leave()
                        }
                    }
                } else {
                    PrintControl.shared.printFroopManager("Data missing in document: \(document.documentID). Cannot fetch froopHost or froopId.")
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                PrintControl.shared.printFroopManager("All async operations completed. Returning \(froopsAndHosts.count) FroopAndHost objects.")
                completion(.success(froopsAndHosts))
            }
        }
    }

    func fetchFriendLists(uid: String, completion: @escaping ([String]) -> Void) {
        PrintControl.shared.printFroopManager("fetchFriendList: uid:  \(uid))")
        let friendsRef = db.collection("users").document(uid).collection("friends").document("friendList")
        
        friendsRef.getDocument { document, error in
            if let document = document, document.exists {
                let userFriendUIDs = document.data()?["friendUIDs"] as? [String] ?? []
                PrintControl.shared.printFroopManager("First Function: fetchFriendLists: \(userFriendUIDs.description)")
                print("First Function: fetchFriendLists: \(userFriendUIDs.description)")

                // Append the current user's uid to the list
//                let currentUserUID = FirebaseServices.shared.uid
//                userFriendUIDs.append(currentUserUID)
                
                
                completion(userFriendUIDs)
            } else {
                completion([])
            }
        }
    }
    
    func fetchFroopData(fuid: String) {
        fetchAttendedFroops(for: fuid) { result in
            switch result {
                case .success(let fetchedFroops):
                    self.combineFroopAndHostWithFriends(froopAndHostArray: fetchedFroops) { combinedResult in
                        DispatchQueue.main.async {
                            switch combinedResult {
                                case .success(let froopHostAndFriendsArray):
                                    self.froopFeed = froopHostAndFriendsArray
                                    self.isFroopFetchingComplete = true
                                case .failure(let error):
                                    PrintControl.shared.printFroopManager("Failed to combine Froop and Host with Friends: \(error)")
                                    // Handle error accordingly
                            }
                        }
                    }
                case .failure(let error):
                    PrintControl.shared.printFroopManager("Failed to fetch attended Froops: \(error)")
            }
        }
    }

    func fetchFroopData(froopId: String, froopHost: String, completion: @escaping (Froop?) -> Void) {
        let froopRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
        
        froopRef.getDocument { (document, error) in
            if let error = error {
                PrintControl.shared.printFroopManager("Error fetching Froop data: \(error.localizedDescription)")
                completion(nil)
            } else if let document = document, document.exists, let data = document.data() {
                // After fetching the froop, fetch flight details
                let flightDetailsRef = froopRef.collection("flightDetails")
                flightDetailsRef.getDocuments { (snapshot, error) in
                    if let error = error {
                        PrintControl.shared.printFroopManager("Error fetching flight data: \(error.localizedDescription)")
                        completion(nil)
                    } else {
                        var flightDetails: [FlightDetail] = []
                        snapshot?.documents.forEach { document in
                            let flightDataDict = document.data()
                            if let flightDetail = FlightDetail(dictionary: flightDataDict) {
                                flightDetails.append(flightDetail)
                            }
                        }

                        // Use the fetched data
                        var froop = Froop(dictionary: data)
                        froop.flightData = flightDetails.first
                        FroopManager.shared.selectedFroopHistory.froop = froop
                        completion(froop)
                    }
                }
            } else {
                PrintControl.shared.printFroopManager("Document does not exist")
                completion(nil)
            }
        }
    }

    
    func fetchFriendsData(from friendUIDs: [String], completion: @escaping ([UserData]) -> Void) {
        
        let usersRef = db.collection("users")
        var friends: [UserData] = []
        
        let group = DispatchGroup()
        
        for friendUID in friendUIDs {
            group.enter()
            
            usersRef.document(friendUID).getDocument { document, error in
                if let document = document, document.exists, let data = document.data() {
                    if let friend = UserData(dictionary: data) {
                        friends.append(friend)
                        //print("Second Function: fetchFriendsData: \(friends.description)")
                    } else {
                        PrintControl.shared.printFroopManager("Error initializing UserData from document data.")
                    }
                } else if let error = error {
                    PrintControl.shared.printErrorMessages("Error getting document: \(error)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.userFriends = friends
            completion(friends)
        }
    }

    func fetchUserDataFor(uids: [String], completion: @escaping (Result<[UserData], Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var users: [UserData] = []
        
        for uid in uids {
            dispatchGroup.enter()
            AppStateManager.shared.getUserData(uid: uid) { result in
                switch result {
                    case .success(let userData):
                        users.append(userData)
                    case .failure(let error):
                        PrintControl.shared.printFroopManager("Failed to fetch user data: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(.success(users))
        }
    }
    
    func fetchConfirmedFriendData(for froop: Froop, completion: @escaping (Result<[UserData], Error>) -> Void) {
        fetchConfirmedFriends(for: froop) { result in
            switch result {
                case .success(let friendUIDs):
                    let dispatchGroup = DispatchGroup()
                    var friends: [UserData] = []
                    
                    for uid in friendUIDs {
                        dispatchGroup.enter()
                        
                        AppStateManager.shared.getUserData(uid: uid) { result in
                            switch result {
                                case .success(let userData):
                                    // Listen to this user's data and register the listener
                                    self.listenToUserDocument(userData: userData)
                                    
                                    friends.append(userData)
                                    
                                    // Assuming friends array is not being modified elsewhere concurrently
                                    let currentIndex = friends.count - 1 // Index of the last added element
                                    PrintControl.shared.printFroopManager("🔥🔥Friend Data added to friends array: \(friends[currentIndex].firstName)")
                                case .failure(let error):
                                    PrintControl.shared.printFroopManager("Failed to fetch user data: \(error)")
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        completion(.success(friends))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    func fetchConfirmedFriends(for froop: Froop, completion: @escaping (Result<[String], Error>) -> Void) {
        guard !froop.froopHost.isEmpty, !froop.froopId.isEmpty, !froop.froopHost.contains("/"), !froop.froopId.contains("/") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid froop details"])))
            return
        }
        
        let confirmedFriendsRef = db.collection("users").document(froop.froopHost).collection("myFroops").document(froop.froopId).collection("invitedFriends").document("confirmedList")
        
        confirmedFriendsRef.getDocument { document, error in
            if let document = document, document.exists {
                let confirmedFriendUIDs = document.data()?["uid"] as? [String] ?? []
                completion(.success(confirmedFriendUIDs))
                PrintControl.shared.printFroopManager("Confirmed 🧑🏻‍🌾👷🏻‍♀️ \(confirmedFriendUIDs.count)")
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Confirmed friends document does not exist"])))
            }
        }
    }
    
    func fetchInvitedFriendData(for froop: Froop, completion: @escaping (Result<[UserData], Error>) -> Void) {
        fetchInvitedFriends(for: froop) { result in
            switch result {
                case .success(let friendUIDs):
                    let dispatchGroup = DispatchGroup()
                    var friends: [UserData] = []
                    
                    for uid in friendUIDs {
                        dispatchGroup.enter()
                        AppStateManager.shared.fetchHostData(uid: uid) { result in
                            switch result {
                                case .success(let userData):
                                    // Listen to this user's data and register the listener
                                    friends.append(userData)
                                    
                                    // Assuming friends array is not being modified elsewhere concurrently
                                    let currentIndex = friends.count - 1 // Index of the last added element
                                    PrintControl.shared.printFroopManager("❄️🔥Friend Data added to friends array: \(friends[currentIndex].firstName)")
                                case .failure(let error):
                                    PrintControl.shared.printFroopManager("Failed to fetch user data: \(error)")
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        completion(.success(friends))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    func fetchInvitedFriends(for froop: Froop, completion: @escaping (Result<[String], Error>) -> Void) {
        guard !froop.froopHost.isEmpty, !froop.froopId.isEmpty, !froop.froopHost.contains("/"), !froop.froopId.contains("/") else {
            
            return
        }
        
        let invitedFriendsRef = db.collection("users").document(froop.froopHost).collection("myFroops").document(froop.froopId).collection("invitedFriends").document("inviteList")
        
        invitedFriendsRef.getDocument { document, error in
            if let document = document, document.exists {
                let invitedFriendUIDs = document.data()?["uid"] as? [String] ?? []
                completion(.success(invitedFriendUIDs))
                PrintControl.shared.printFroopManager("Invited 🧑🏻‍🌾👷🏻‍♀️ \(invitedFriendUIDs.count)")
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invited friends document does not exist"])))
            }
        }
    }
    
    func fetchDeclinedFriendData(for froop: Froop, completion: @escaping (Result<[UserData], Error>) -> Void) {
            fetchDeclinedFriends(for: froop) { result in
                switch result {
                    case .success(let friendUIDs):
                        let dispatchGroup = DispatchGroup()
                        var friends: [UserData] = []
                        
                        for uid in friendUIDs {
                            dispatchGroup.enter()
                            AppStateManager.shared.getUserData(uid: uid) { result in
                                switch result {
                                    case .success(let userData):
                                        friends.append(userData)
                                    case .failure(let error):
                                        PrintControl.shared.printFroopManager("Failed to fetch user data: \(error)")
                                }
                                dispatchGroup.leave()
                            }
                        }
                        
                        dispatchGroup.notify(queue: .main) {
                            completion(.success(friends))
                        }
                        
                    case .failure(let error):
                        completion(.failure(error))
                }
            }
        }
    
    func fetchDeclinedFriends(for froop: Froop, completion: @escaping (Result<[String], Error>) -> Void) {
        guard !froop.froopHost.isEmpty, !froop.froopId.isEmpty, !froop.froopHost.contains("/"), !froop.froopId.contains("/") else {
            
            return
        }
        
        let declinedFriendsRef = db.collection("users").document(froop.froopHost).collection("myFroops").document(froop.froopId).collection("invitedFriends").document("declinedList")
        
        declinedFriendsRef.getDocument { document, error in
            if let document = document, document.exists {
                let declinedFriendUIDs = document.data()?["uid"] as? [String] ?? []
                completion(.success(declinedFriendUIDs))
                PrintControl.shared.printFroopManager("Declined 🧑🏻‍🌾👷🏻‍♀️ \(declinedFriendUIDs.count)")
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Declined friends document does not exist"])))
            }
        }
    }
    
    func fetchPendingFriendData(for froop: Froop, completion: @escaping (Result<[UserData], Error>) -> Void) {
        fetchPendingFriends(for: froop) { result in
            switch result {
                case .success(let friendUIDs):
                    let dispatchGroup = DispatchGroup()
                    var friends: [UserData] = []
                    
                    for uid in friendUIDs {
                        dispatchGroup.enter()
                        AppStateManager.shared.fetchHostData(uid: uid) { result in
                            switch result {
                                case .success(let userData):
                                    // Listen to this user's data and register the listener
                                    friends.append(userData)
                                    
                                    // Assuming friends array is not being modified elsewhere concurrently
                                    let currentIndex = friends.count - 1 // Index of the last added element
                                    PrintControl.shared.printFroopManager("❄️🔥Friend Data added to friends array: \(friends[currentIndex].firstName)")
                                case .failure(let error):
                                    PrintControl.shared.printFroopManager("Failed to fetch user data: \(error)")
                            }
                            dispatchGroup.leave()
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) {
                        completion(.success(friends))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
            }
        }
    }
    
    func fetchPendingFriends(for froop: Froop, completion: @escaping (Result<[String], Error>) -> Void) {
        guard !froop.froopHost.isEmpty, !froop.froopId.isEmpty, !froop.froopHost.contains("/"), !froop.froopId.contains("/") else {
            
            return
        }
        
        let pendingFriendsRef = db.collection("users").document(froop.froopHost).collection("myFroops").document(froop.froopId).collection("invitedFriends").document("pendingList")
        
        pendingFriendsRef.getDocument { document, error in
            if let document = document, document.exists {
                let pendingFriendUIDs = document.data()?["uid"] as? [String] ?? []
                completion(.success(pendingFriendUIDs))
                PrintControl.shared.printFroopManager("Pending 🧑🏻‍🌾👷🏻‍♀️ \(pendingFriendUIDs.count)")
            } else if let error = error {
                completion(.failure(error))
            } else {
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Pending friends document does not exist"])))
            }
        }
    }
    
//    ///FROOP HISTORY
//    
    func createFroopHistoryArray(completion: @escaping ([FroopHistory]) -> Void) {
        let froops = FroopDataController.shared.myArchivedList + FroopDataController.shared.myInvitesList + FroopDataController.shared.myConfirmedList + FroopDataController.shared.myDeclinedList
        
        var froopHistory: [FroopHistory] = []
        let outerDispatchGroup = DispatchGroup()
        
        for froop in froops {
            outerDispatchGroup.enter()
            createSingleFroopHistory(for: froop) { history in
                if let history = history {
                    froopHistory.append(history)
                }
                outerDispatchGroup.leave()
            }
        }
        
        outerDispatchGroup.notify(queue: .main) {
            self.froopHistory = froopHistory
            AppStateManager.shared.fetchedFroops = froopHistory
            self.froopHistory = froopHistory  // Update histories in FroopHistoryService
            PrintControl.shared.printFroopManager("David asking: \(FroopManager.shared.froopHistory.count)")
            
            // Set up listeners for each FroopHistory's Froop
            for history in froopHistory {
                let froop = history.froop
                self.listenToFroopChanges(froopId: froop.froopId, froopHost: froop.froopHost) { result in
                    switch result {
                        case .success(let updatedFroop):
                            PrintControl.shared.printFroopManager("Updated Froop: \(updatedFroop)")
                            // Now, find this Froop in the froopHistory using froopId and update it
                            if let existingFroopIndex = self.froopHistory.firstIndex(where: { $0.froop.froopId == updatedFroop.froopId }) {
                                self.froopHistory[existingFroopIndex].froop = updatedFroop
                            } else {
                                PrintControl.shared.printFroopManager("Didn't find the Froop in froopHistory.")
                            }
                            
                        case .failure(let error):
                            PrintControl.shared.printFroopManager("Error listening to Froop changes: \(error)")
                    }
                }
                
            }
            self.froopHistoryService.evaluateFroopHistoryConditions()
            completion(froopHistory)
        }
        
    }
    
    func createSingleFroopHistory(for froop: Froop, completion: @escaping (FroopHistory?) -> Void) {
        PrintControl.shared.printFroopManager("Making a FroopHistory")
        guard !froop.froopHost.isEmpty else {
            PrintControl.shared.printFroopManager("Skipping froop with empty host.")
            completion(nil)
            return
        }
        let groupChatConversation = Conversation() // Create a new conversation or fetch existing one
        let groupChatMessages: [Message] = []
//        let froopGroupConversationAndMessages = ConversationAndMessages(conversation: groupChatConversation, messages: groupChatMessages, participants: [])
        
        var invited: [UserData] = []
        var confirmed: [UserData] = []
        var declined: [UserData] = []
        var pending: [UserData] = []
        
        let dispatchGroup = DispatchGroup()
        
//        let mediaData = FroopMediaData(
//            froopImages: froop.froopImages,
//            froopDisplayImages: froop.froopDisplayImages,
//            froopThumbnailImages: froop.froopThumbnailImages,
//            froopIntroVideo: froop.froopIntroVideo,
//            froopIntroVideoThumbnail: froop.froopIntroVideoThumbnail,
//            froopVideos: froop.froopVideos,
//            froopVideoThumbnails: froop.froopVideoThumbnails
//        )
        
        self.froopHistoryService.evaluateFroopHistoryConditions()
        
        dispatchGroup.enter()
        fetchInvitedFriendData(for: froop) { result in
            switch result {
                case .success(let friends):
                    invited = friends
                case .failure(let error):
                    PrintControl.shared.printFroopManager("Failed to fetch invited friends: \(error)")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchConfirmedFriendData(for: froop) { result in
            switch result {
                case .success(let friends):
                    confirmed = friends
                    PrintControl.shared.printFroopManager("🔥🔥🔥 Confirmed friends received in createSingleFroopHistory: \(confirmed.map { $0.firstName })")
                    
                case .failure(let error):
                    PrintControl.shared.printFroopManager("Failed to fetch confirmed friends: \(error)")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchDeclinedFriendData(for: froop) { result in
            switch result {
                case .success(let friends):
                    declined = friends
                case .failure(let error):
                    PrintControl.shared.printFroopManager("Failed to fetch declined friends: \(error)")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        fetchPendingFriendData(for: froop) { result in
            switch result {
                case .success(let friends):
                    pending = friends
                case .failure(let error):
                    PrintControl.shared.printFroopManager("Failed to fetch declined friends: \(error)")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            AppStateManager.shared.getUserData(uid: froop.froopHost) { result in
                switch result {
                    case .success(let hostData):
                        // Create the FroopHistory object
                        let history = FroopHistory(
                            froop: froop,
                            host: hostData,
                            invitedFriends: invited,
                            confirmedFriends: confirmed,
                            declinedFriends: declined,
                            pendingFriends: pending,
                            images: froop.froopImages,
                            videos: froop.froopVideos,
                            froopGroupConversationAndMessages: ConversationAndMessages(
                                conversation: Conversation(),
                                messages: [], participants: []),
                            froopMediaData: FroopMediaData(
                                froopImages: [],
                                froopDisplayImages: [],
                                froopThumbnailImages: [],
                                froopIntroVideo: "",
                                froopIntroVideoThumbnail: "",
                                froopVideos: [],
                                froopVideoThumbnails: []
                            )
                        )
                        
                        // Fetch group chat messages and update the FroopHistory object
                        self.fetchGroupChatMessages(for: froop.froopId, for: froop.froopHost) { messagesResult in
                            switch messagesResult {
                                case .success(let messages):
                                    // Update the FroopHistory object with the fetched messages
                                    history.froopGroupConversationAndMessages.messages = messages
                                    completion(history)
                                case .failure(let error):
                                    // Handle the error, e.g., log it or show an error message
                                    print("🚫Error fetching group chat messages: \(error)")
                                    completion(history) // Still return the FroopHistory without messages
                            }
                        }
                        
                    case .failure(let error):
                        // Handle the error, e.g., log it or show an error message
                        PrintControl.shared.printFroopManager("Failed to fetch user data: \(error)")
                        completion(nil)
                }
            }
        }
    }
    
    static func defaultFroopHistory() -> FroopHistory {
        let defaultFroop = Froop(dictionary: [:])
        let defaultHost = UserData()
        let defaultFriends: [UserData] = []
        let defaultImages: [String] = []
        let defaultVideos: [String] = []
        let defaultConversationAndMessages: ConversationAndMessages = ConversationAndMessages(conversation: Conversation(), messages: [], participants: [])
        let froopMediaData: FroopMediaData = FroopMediaData(
            froopImages: [],
            froopDisplayImages: [],
            froopThumbnailImages: [],
            froopIntroVideo: "",
            froopIntroVideoThumbnail: "",
            froopVideos: [],
            froopVideoThumbnails: []
        )

        return FroopHistory(
            froop: defaultFroop,
            host: defaultHost,
            invitedFriends: defaultFriends,
            confirmedFriends: defaultFriends,
            declinedFriends: defaultFriends,
            pendingFriends: defaultFriends,
            images: defaultImages,
            videos: defaultVideos,
            froopGroupConversationAndMessages: defaultConversationAndMessages,
            froopMediaData: froopMediaData
        )
    }
//    
//    
//    /// STATE MANAGEMENT
//    
//    func updateSelectedFroopHistory() {
//        selectedFroopHistory = froopHistory.first { $0.froop.froopId == selectedFroopUUID } ?? FroopManager.defaultFroopHistory()
//        }
//    
    private func handleFroopHistoryChanges() {
        AppStateManager.shared.appState = .active
//        print("handleFroopHistoryChanges Firing - \(AppStateManager.shared.appState)")
    }
    
    func listenToFroopChanges(froopId: String, froopHost: String, completion: @escaping (Result<Froop, Error>) -> Void) {
        let listenerKey = "froop_\(froopId)"
        
        if ListenerStateService.shared.shouldCreateListener(forKey: listenerKey) {
            let docRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
            
            let listener = docRef.addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    let fetchError = error ?? NSError(domain: "FroopManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred while fetching froop document."])
                    PrintControl.shared.printFroopManager("Error fetching document: \(fetchError.localizedDescription)")
                    completion(.failure(fetchError))
                    return
                }
                
                guard let data = document.data() else {
                    PrintControl.shared.printFroopManager("Document data was empty.")
                    completion(.failure(NSError(domain: "FroopManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Document data was empty."])))
                    return
                }
                
                let froop = Froop(dictionary: data)
                completion(.success(froop))
            }
            
            ListenerStateService.shared.registerListener(listener, forKey: listenerKey)
        }
    }

    func listenToUserDocument(userData: UserData) {
        let listenerKey = "user_\(userData.froopUserID)"

        if ListenerStateService.shared.shouldCreateListener(forKey: listenerKey) {
            let docRef = Firestore.firestore().collection("users").document(userData.froopUserID)

            let listener = docRef.addSnapshotListener { [weak self] (documentSnapshot, error) in
                guard let self = self else { return }
                guard let document = documentSnapshot, let data = document.data() else {
                    PrintControl.shared.printFroopManager("Error fetching or processing user document: \(String(describing: error))")
                    return
                }

                // Update the user's data
                if let updatedUserData = UserData(dictionary: data) {
                    // 1. Update host data if there's a match
                    for (index, historyItem) in self.froopHistory.enumerated() {
                        if historyItem.host.froopUserID == updatedUserData.froopUserID {
                            self.froopHistory[index].host = updatedUserData
                        }
                        
                        // 2. Update confirmedFriends data if there's a match
                        for (friendIndex, friend) in historyItem.confirmedFriends.enumerated() {
                            if friend.froopUserID == updatedUserData.froopUserID {
                                self.froopHistory[index].confirmedFriends[friendIndex] = updatedUserData
                            }
                        }
                    }
                    // Any additional processing can go here
                }
            }

            // Register the listener with the ListenerStateService
            ListenerStateService.shared.registerListener(listener, forKey: listenerKey)
        }
    }

    func fetchGroupChatMessages(for froopId: String, for hostId: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        // Define the reference to the group chat messages in the database
        let messagesRef = db.collection("users").document(hostId).collection("myFroops").document(froopId).collection("chats").document("froopGroupChat").collection("messages")
        
        // Fetch the messages
        messagesRef.getDocuments { snapshot, error in
            if let error = error {
                // Handle the error, e.g., pass it to the completion handler
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                // Handle the case where there are no messages (or an error occurred)
                completion(.success([]))
                return
            }

            // Parse the documents into Message objects
            let messages = documents.compactMap { document -> Message? in
                        let data = document.data()
                        return Message(dictionary: data, id: document.documentID)
                    }

            // Pass the fetched messages to the completion handler
            completion(.success(messages))
        }
    }
    
    func refreshGroupChatMessages(for froopId: String, for hostId: String) {
        // Define the reference to the group chat messages in the database
        let messagesRef = db.collection("users").document(hostId).collection("myFroops").document(froopId).collection("chats").document("froopGroupChat").collection("messages")

        // Fetch the latest messages
        messagesRef.getDocuments { snapshot, error in
            if let error = error {
                // Handle the error appropriately
                print("🚫Error fetching group chat messages: \(error)")
                return
            }

            guard let documents = snapshot?.documents else {
                // Handle the case where there are no messages or an error occurred
                print("No messages found or an error occurred.")
                return
            }

            // Parse the documents into Message objects
            let messages = documents.compactMap { document -> Message? in
                let data = document.data()
                return Message(dictionary: data, id: document.documentID)
            }

            // Update the FroopHistory object with the fetched messages
            DispatchQueue.main.async {
                if let index = AppStateManager.shared.currentFilteredFroopHistory.firstIndex(where: { $0.froop.froopId == froopId }) {
                    AppStateManager.shared.currentFilteredFroopHistory[index].froopGroupConversationAndMessages.messages = messages
                }
            }
        }
    }


    
    /// MEDIA AND DOCUMENT HANDLING
    
    func addCurrentUserToHiddenArray(froopUserID: String, froopId: String) async throws {
        print("add")
        print(froopUserID)
        print(froopId)
        let userRef = db.collection("users").document(froopUserID)
        let froopRef = userRef.collection("myFroops").document(froopId)

        let uidToAdd = FirebaseServices.shared.uid

        // Add the current user's UID to the hidden array
        try await froopRef.updateData([
            "hidden": FieldValue.arrayUnion([uidToAdd])
        ])
    }
    
    func removeCurrentUserFromHiddenArray(froopUserID: String, froopId: String) async throws {
        print("remove")
        print(froopUserID)
        print(froopId)

        let userRef = db.collection("users").document(froopUserID)
        let froopRef = userRef.collection("myFroops").document(froopId)

        let uidToRemove = FirebaseServices.shared.uid

        // Remove the current user's UID from the hidden array
        try await froopRef.updateData([
            "hidden": FieldValue.arrayRemove([uidToRemove])
        ])
    }
    
    func filterFroopsWithoutImages(from froops: [Froop]) -> [Froop] {
        return froops.filter { !$0.froopImages.isEmpty }
    }
    
    func createFroopAndHostArray(from froops: [Froop], and hosts: [UserData]) -> [FroopAndHost] {
        var froopAndHostArray: [FroopAndHost] = []
        
        for froop in froops {
            if let host = hosts.first(where: { $0.froopUserID == froop.froopHost }) {
                let froopAndHost = FroopAndHost(froop: froop, host: host)
                froopAndHostArray.append(froopAndHost)
            }
        }
        
        return froopAndHostArray
    }
    
    func combineFroopAndHostWithFriends(froopAndHostArray: [FroopAndHost], completion: @escaping (Result<[FroopHostAndFriends], Error>) -> Void) {
        var froopHostAndFriendsArray: [FroopHostAndFriends] = []
        let dispatchGroup = DispatchGroup()
        
        for froopAndHost in froopAndHostArray {
            dispatchGroup.enter()
            fetchConfirmedFriendData(for: froopAndHost.froop) { result in
                switch result {
                    case .success(let friends):
                        let froopHostAndFriends = FroopHostAndFriends(FH: froopAndHost, friends: friends)
                        froopHostAndFriendsArray.append(froopHostAndFriends)
                    case .failure(let error):
                        PrintControl.shared.printFroopManager("Failed to fetch confirmed friend data: \(error)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(.success(froopHostAndFriendsArray))
        }
    }
    
    func addMediaURLAndAssetIdentifierToDocument(froopHost: String, froopId: String, mediaURL: URL, assetIdentifier: String, isImage: Bool) {
        PrintControl.shared.printFroopManager("-FroopManager: Function: addMediaURLAndAssetIdentifierToDocument is firing!")
        
        let userRef = db.collection("users").document(froopHost)
        let froopsRef = userRef.collection("myFroops").document(froopId)
        
        let mediaField = isImage ? "froopImages" : "froopVideos"
        let assetIdField = isImage ? "imageAssetIdentifiers" : "videoAssetIdentifiers"
        
        // Begin a batch update
        let batch = db.batch()
        
        // Update the media URLs
        batch.updateData([
            mediaField: FieldValue.arrayUnion([mediaURL.absoluteString])
        ], forDocument: froopsRef)
        
        // Update the asset identifiers
        batch.updateData([
            assetIdField: FieldValue.arrayUnion([assetIdentifier])
        ], forDocument: froopsRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                PrintControl.shared.printFroopManager("Error updating document: \(error)")
            } else {
                PrintControl.shared.printFroopManager("Document successfully updated with media URL and asset identifier")
            }
        }
    }
//    
    func addMediaURLsToDocument(froopHost: String, froopId: String, fullsizeImageUrl: URL, displayImageUrl: URL, thumbnailImageUrl: URL, isImage: Bool) {
        let froopRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
        
        froopRef.updateData([
            "froopImages": FieldValue.arrayUnion([fullsizeImageUrl.absoluteString]),
            "froopDisplayImages": FieldValue.arrayUnion([displayImageUrl.absoluteString]),
            "froopThumbnailImages": FieldValue.arrayUnion([thumbnailImageUrl.absoluteString])
        ]) { err in
            if let err = err {
                PrintControl.shared.printFroopManager("Error updating document: \(err)")
            } else {
                PrintControl.shared.printFroopManager("Document successfully updated")
            }
        }
    }
    
    func addVideoAndThumbnailURLToDocument(froopHost: String, froopId: String, videoUrl: URL, thumbnailUrl: URL) {
           let froopRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
           
           froopRef.updateData([
               "froopVideos": FieldValue.arrayUnion([videoUrl.absoluteString]),
               "froopVideoThumbnails": FieldValue.arrayUnion([thumbnailUrl.absoluteString])
           ]) { err in
               if let err = err {
                   print("🚫Error updating document with video and thumbnail URLs: \(err)")
               } else {
                   print("Document successfully updated with video and thumbnail URLs")
               }
           }
       }
    
    func addVideoURLToDocument(froopHost: String, froopId: String, videoUrl: URL) {
        let froopRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
        
        froopRef.updateData([
            "froopVideos": FieldValue.arrayUnion([videoUrl.absoluteString])
        ]) { err in
            if let err = err {
                PrintControl.shared.printFroopManager("Error updating document with video URL: \(err)")
            } else {
                PrintControl.shared.printFroopManager("Document successfully updated with video URL")
            }
        }
    }
    

    func removeListeners() {
        PrintControl.shared.printFroopManager("removing frooplistener for \(selectedFroopHistory.froop.froopName)")
        froopListener?.remove()
        PrintControl.shared.printFroopManager("removing invitedList listener for \(selectedFroopHistory.froop.froopName)")
        invitedListener?.remove()
        PrintControl.shared.printFroopManager("removing confirmedList listener for \(selectedFroopHistory.froop.froopName)")
        confirmedListener?.remove()
        PrintControl.shared.printFroopManager("removing declinedList listener for \(selectedFroopHistory.froop.froopName)")
        declinedListener?.remove()
    }

    func setupTemplateStoreListener() {
        let userDocumentRef = db.collection("users").document(uid)
        let templatesCollectionRef = userDocumentRef.collection("templates")
        let listenerKey = "templateStoreListener"
        
        if ListenerStateService.shared.shouldCreateListener(forKey: listenerKey) {
            // Assigning the listener to the templates collection
            let listener = templatesCollectionRef.addSnapshotListener { [weak self] (querySnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    PrintControl.shared.printFroopManager("Error fetching templates: \(error.localizedDescription)")
                    return
                }

                guard let querySnapshot = querySnapshot else {
                    PrintControl.shared.printFroopManager("Error: Query snapshot is nil.")
                    return
                }

                // Map the documents to Froop objects
                let templates = querySnapshot.documents.compactMap { document -> Froop? in
                    let data = document.data()
                    return Froop(dictionary: data)
                }

                // Update the froopTemplates array
                DispatchQueue.main.async {
                    self.froopTemplates = templates
                }
            }
            
            // Register the listener with the ListenerStateService
            ListenerStateService.shared.registerListener(listener, forKey: listenerKey)
        }
    }

    /// UTILITY AND MISC>
    
    func saveFroopAsTemplate(froopId: String, completion: @escaping (Error?) -> Void) {
        let userUid = FirebaseServices.shared.uid
        let froopRef = db.collection("users").document(userUid).collection("myFroops").document(selectedFroopHistory.froop.froopId)
        let templateRef = db.collection("users").document(userUid).collection("templates").document(selectedFroopHistory.froop.froopId)

        // Fetch the froop document
        froopRef.getDocument { documentSnapshot, error in
            if let error = error {
                completion(error)
                return
            }

            guard var copiedFroopData = documentSnapshot?.data() else {
                completion(NSError(domain: "FroopManager", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Froop document not found."]))
                return
            }

            // Fetch confirmed friends list
            froopRef.collection("invitedFriends").document("confirmedList").getDocument { snapshot, error in
                if let error = error {
                    completion(error)
                    return
                }

                let confirmedFriends = snapshot?.data()?["uid"] as? [String] ?? []
                copiedFroopData["froopInvitedFriends"] = confirmedFriends

                // Update properties for template
                copiedFroopData["froopThumbnailImages"] = []
                copiedFroopData["froopVideos"] = []
                copiedFroopData["froopImages"] = []
                copiedFroopData["froopDisplayImages"] = []
                copiedFroopData["froopCreationTime"] = Date()
                copiedFroopData["froopDate"] = Date()
                copiedFroopData["froopStartTime"] = Date()
                copiedFroopData["froopEndTime"] = Date().addingTimeInterval(60 * 60) // Adds 1 hour
                copiedFroopData["template"] = true

                // Copy froop data with updated properties to the templates collection
                templateRef.setData(copiedFroopData) { error in
                    completion(error)
                }
            }
        }
    }
    
    func saveFroopDropPins(froopHost: String, froopId: String, completion: @escaping (Error?) -> Void) {
        let froopDocRef = db.collection("users").document(froopHost).collection("myFroops").document(froopId)
        let annotationCollectionRef = froopDocRef.collection("annotations")
        
        let dispatchGroup = DispatchGroup()
        
        for froopDropPin in froopDropPins {
            dispatchGroup.enter()
            let documentId = froopDropPin.id.uuidString
            annotationCollectionRef.document(documentId).getDocument { (document, error) in
                if let error = error {
                    completion(error)
                    dispatchGroup.leave()
                    return
                }
                
                if let document = document, document.exists {
                    // Document already exists, skipping
                    dispatchGroup.leave()
                } else {
                    // Document does not exist, create a new one
                    do {
                        let froopDropPinData = froopDropPin.dictionary
                        annotationCollectionRef.document(documentId).setData(froopDropPinData) { error in
                            if let error = error {
                                completion(error)
                            }
                            dispatchGroup.leave()
                        }
                    }
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(nil)
        }
    }
    
    //
    //    func fetchFroopsFromIds(uid: String, templateStore: [String], completion: @escaping (Result<[Froop], Error>) -> Void) {
    //        let userFroopsCollectionRef = db.collection("users").document(uid).collection("myFroops")
    //
    //        var froopsArray = [Froop]()
    //        let dispatchGroup = DispatchGroup()
    //
    //        for froopId in templateStore {
    //            dispatchGroup.enter()
    //
    //            userFroopsCollectionRef.document(froopId).getDocument { (document, error) in
    //                if let error = error {
    //                    completion(.failure(error))
    //                    return
    //                } else if let document = document, document.exists {
    //                    let data = document.data() ?? [:]
    //                    let froop = Froop(dictionary: data)
    //                    froopsArray.append(froop)
    //                }
    //
    //                dispatchGroup.leave()
    //            }
    //        }
    //
    //        dispatchGroup.notify(queue: .main) {
    //            completion(.success(froopsArray))
    //        }
    //    }
    //
    //
    //    func fetchUserArchivedFroops(for uid: String, completion: @escaping ([Froop]) -> Void) {
    //        var allFroops: [Froop] = []
    //
    //        let archivedFroopsRef = db.collection("users").document(uid).collection("myDecisions").document("froopLists").collection("myArchivedList")
    //
    //        archivedFroopsRef.getDocuments() { (querySnapshot, err) in
    //            if let err = err {
    //                PrintControl.shared.printErrorMessages("Error getting documents: \(err)")
    //                completion([]) // returning an empty array in case of error
    //            } else {
    //                for document in querySnapshot!.documents {
    //                    let data = document.data()
    //                    let froop = Froop(dictionary: data)
    //                    allFroops.append(froop)
    //
    //                }
    //                completion(allFroops)
    //            }
    //        }
    //    }
    //
    //    func getUserFroops(uid: String, completion: @escaping (Result<[Froop], Error>) -> Void) {
    //        let froopsCollectionRef = db.collection("users").document(uid).collection("myFroops")
    //
    //        froopsCollectionRef.getDocuments { (querySnapshot, error) in
    //            if let error = error {
    //                completion(.failure(error))
    //            } else if let querySnapshot = querySnapshot {
    //                var froopsArray = [Froop]()
    //                for document in querySnapshot.documents {
    //                    let data = document.data()
    //                    let froop = Froop(dictionary: data)
    //                    froopsArray.append(froop)
    //                }
    //                completion(.success(froopsArray))
    //            } else {
    //                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No documents found in the collection"])
    //                completion(.failure(error))
    //            }
    //        }
    //    }
    //
    //
    //    func fetchFroops(for userFriends: [UserData], completion: @escaping ([FroopAndHost]) -> Void) {
    //        var allFroops: [Froop] = []
    //        let dispatchGroup = DispatchGroup()
    //
    //        for userFriend in userFriends {
    //            dispatchGroup.enter()
    //            let friendUID = userFriend.froopUserID
    //            let froopsRef = db.collection("users").document(friendUID).collection("myFroops")
    //
    //            froopsRef.getDocuments() { (querySnapshot, err) in
    //                if let err = err {
    //                    PrintControl.shared.printErrorMessages("Error getting documents: \(err)")
    //                } else {
    //                    for document in querySnapshot!.documents {
    //                        let data = document.data()
    //                        let froop = Froop(dictionary: data)
    //                        allFroops.append(froop)
    //                    }
    //                }
    //                dispatchGroup.leave()
    //            }
    //        }
    //
    //        dispatchGroup.notify(queue: .main) {
    //            let froopsWithImages = self.filterFroopsWithoutImages(from: allFroops)
    //            let froopAndHostArray = self.createFroopAndHostArray(from: froopsWithImages, and: userFriends)
    //            completion(froopAndHostArray)
    //        }
    //    }
    //
    //
    //    func updateFroopState(_ state: FroopState, for froopHistory: FroopHistory) {
    //        PrintControl.shared.printFroopManager("-FroopManager: Function: updateFroopState is firing!")
    //        PrintControl.shared.printFroopManager("Froop State Change to \(state) for \(froopHistory.froop.froopId) with name: \(froopHistory.froop.froopName) starting at \(froopHistory.froop.froopStartTime)")
    //
    //        switch state {
    //            case .froopPreGame:
    //                setActiveFroopHistory(froopHistory)
    //                notificationCenter.notifyStatusChanged(froopHistory)
    //                // startMediaScanForActiveFroop()
    //            default:
    //                break
    //        }
    //    }
    //
    //    func setActiveFroopHistory(_ froopHistory: FroopHistory) {
    //        PrintControl.shared.printFroopManager("-FroopManager: Function: setActiveFroop firing")
    //        if let index = activeFroopHistories.firstIndex(where: { $0.froop.froopId == froopHistory.froop.froopId }) {
    //            activeFroopHistories[index] = froopHistory
    //        }
    //    }
    //
    //    func addActiveFroopHistory(froopHistory: FroopHistory) {
    //        PrintControl.shared.printFroopManager("-FroopManager: Function: addActiveFroop firing")
    //        activeFroopHistories.append(froopHistory)
    //    }
    //
    //    func removeActiveFroopHistory(froopId: String) {
    //        PrintControl.shared.printFroopManager("-FroopManager: Function: removeActiveFroop firing")
    //        activeFroopHistories.removeAll { $0.froop.froopId == froopId }
    //    }
    //
    //
    //    /// GROUP CHAT AND MESSAGING
    //
    //    func postToFroopGroupChat(content: String) {
    //        guard !content.isEmpty else { return }
    //
    //        let froopId = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopId  ?? "" // Hardcoded Froop ID
    //        let hostId = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.froopUserID ?? ""          // Hardcoded Host ID
    //        let groupChatRef = db.collection("users").document(hostId)
    //                             .collection("myFroops").document(froopId)
    //                             .collection("chats").document("froopGroupChat")
    //                             .collection("messages")
    //
    //        // Add message to the group chat
    //        groupChatRef.addDocument(data: [
    //            "senderId": uid,
    //            "text": content,
    //            "timestamp": FieldValue.serverTimestamp()
    //        ]) { error in
    //            if let error = error {
    //                print("🚫Error sending message to group chat: \(error)")
    //                return
    //            }
    //            print("Message posted to group chat successfully")
    //        }
    //    }
    //
    //
    //    /// NOTIFICATIONS AND LISTENER MANAGEMENT
    //
    //    func subscribeToNotifications(_ delegate: FroopNotificationDelegate) {
    //        PrintControl.shared.printFroopManager("-FroopManager: Function: subscribeToNotifications firing")
    //        notificationCenter.delegate = delegate
    //    }
    //
    //    func unsubscribeFromNotifications() {
    //        PrintControl.shared.printFroopManager("-FroopManager: Function: unauvaxeivwDeomNotifications firing")
    //        notificationCenter.delegate = nil
    //    }
    //
    //
    //    func printLocationData (froopLocation: CLLocationCoordinate2D, userLocation: CLLocationCoordinate2D) {
    //        PrintControl.shared.printFroopManager("Froop Location: \(String(describing: self.selectedFroopHistory.froop.froopLocationCoordinate ?? CLLocationCoordinate2D()))")
    //        PrintControl.shared.printFroopManager("User Location: \(String(describing: self.myData.coordinate))")
    //    }
    //
    //
    //
    //    func listenToUserDataChanges(uid: String, completion: @escaping (Result<UserData, Error>) -> Void) {
    //        let listenerKey = "user_\(uid)"
    //
    //        if ListenerStateService.shared.shouldCreateListener(forKey: listenerKey) {
    //            let docRef = db.collection("users").document(uid)
    //
    //            let listener = docRef.addSnapshotListener { documentSnapshot, error in
    //                guard let document = documentSnapshot else {
    //                    let fetchError = error ?? NSError(domain: "FroopManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred while fetching user document."])
    //                    PrintControl.shared.printFroopManager("Error fetching user document: \(fetchError.localizedDescription)")
    //                    completion(.failure(fetchError))
    //                    return
    //                }
    //
    //                guard let data = document.data() else {
    //                    PrintControl.shared.printFroopManager("User document data was empty.")
    //                    // Return an error to the completion handler if needed
    //                    completion(.failure(NSError(domain: "FroopManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "User document data was empty."])))
    //                    return
    //                }
    //
    //                if let user = UserData(dictionary: data) {
    //                    completion(.success(user))
    //                } else {
    //                    let conversionError = NSError(domain: "FroopManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error converting dictionary to UserData."])
    //                    PrintControl.shared.printFroopManager(conversionError.localizedDescription)
    //                    completion(.failure(conversionError))
    //                }
    //            }
    //
    //            ListenerStateService.shared.registerListener(listener, forKey: listenerKey)
    //        }
    //    }
    //
    
}




struct FroopAndHost: Identifiable, Equatable {
    let id = UUID() // This is a unique identifier for each FroopAndHost
    let froop: Froop
    let host: UserData
    
    static func == (lhs: FroopAndHost, rhs: FroopAndHost) -> Bool {
        return lhs.id == rhs.id
    }
}

struct FroopHostAndFriends : Identifiable, Equatable {
    let id = UUID()
    let FH: FroopAndHost
    let friends: [UserData]
    
    static func == (lhs: FroopHostAndFriends, rhs: FroopHostAndFriends) -> Bool {
        return lhs.id == rhs.id
    }
}




