//
//  PrintControl.shared.swift
//  FroopProof
//
//  Created by David Reed on 5/9/23.
//

import Foundation

//MARK: PrintControl is a singleton
//MARK: var PrintControl = PrintControl.shared
//MARK: usage:  PrintControl.shared.<property>("Logging in...")

class PrintControl: ObservableObject {
    static let shared = PrintControl()
    
    @Published var developer: String = ""
    @Published var froopCounter: Int = 0
    @Published var printAppDelegate: Bool = false
    @Published var printAppState: Bool = false
    @Published var printAppStateSetupListener: Bool = false
    @Published var printData: Bool = false
    @Published var printErrorMessages: Bool = false
    @Published var printExtensions: Bool = false
    @Published var printFirebaseOperations: Bool = false
    @Published var printForEach: Bool = false
    @Published var printFriend: Bool = false
    @Published var printFriendList: Bool = false
    @Published var printFroopCreation: Bool = false
    @Published var printFroopData: Bool = false
    @Published var printFroopDataController: Bool = false
    @Published var printFroopDetails: Bool = true
    @Published var printFroopHistoryServices: Bool = false
    @Published var printFroopManager: Bool = false
    @Published var printFroopUpdates: Bool = false
    @Published var printImage: Bool = false
    @Published var printInviteFriends: Bool = false
    @Published var printLists: Bool = false
    @Published var printListeners: Bool = false
    @Published var printLocationServices: Bool = false
    @Published var printLogin: Bool = false
    @Published var printMap: Bool = false
    @Published var printMediaManager: Bool = false
    @Published var printMyData: Bool = false
    @Published var printNotifications: Bool = false
    @Published var printPhotoPicker: Bool = false
    @Published var printProfile: Bool = false
    @Published var printSettings: Bool = false
    @Published var printStartUp: Bool = false
    @Published var printTime: Bool = false
    @Published var printTimeZone: Bool = false
    @Published var printUserData: Bool = false
    @Published var printUserDataUpdates: Bool = false
    @Published var printVersion: Bool = false


    
    private init() {}
    
    func printForEach(_ message: String) {
        if printExtensions {
            print(message)
        }
    }
    
    func printExtensions(_ message: String) {
        if printExtensions {
            print(message)
        }
    }
    
    func printSettings(_ message: String) {
        if printListeners {
            print(message)
        }
    }
    
    func printListeners(_ message: String) {
        if printListeners {
            print(message)
        }
    }
    
    func printData(_ message: String) {
        if printData {
            print(message)
        }
    }
    
    func printVersion(_ message: String) {
        if printVersion {
            print(message)
        }
    }
    
    func printFroopHistoryServices(_ message: String) {
        if printFroopHistoryServices {
            print(message)
        }
    }
    
    func printNotifications(_ message: String) {
        if printNotifications {
            print(message)
        }
    }
    
    func printStartUp(_ message: String) {
        if printStartUp {
            print(message)
        }
    }
    
    func printMap(_ message: String) {
        if printMap {
            print(message)
        }
    }
    
    func printFroopDataController(_ message: String) {
        if printFroopDataController {
            print(message)
        }
    }
    
    func printTimeZone(_ message: String) {
        if printTimeZone {
            print(message)
        }
    }
    
    func printImage(_ message: String) {
        if printImage {
            print(message)
        }
    }
    
    func printFroopData(_ message: String) {
        if printFroopData {
            print(message)
        }
    }
    
    func printMyData(_ message: String) {
        if printMyData {
            print(message)
        }
    }
    
    func printUserData(_ message: String) {
        if printUserData {
            print(message)
        }
    }
    
    func printMediaManager(_ message: String) {
        if printMediaManager {
            print(message)
        }
    }
    
    func printFroopManager(_ message: String) {
        if printFroopManager {
            print(message)
        }
    }
    
    func printFriend(_ message: String) {
        if printFriend {
            print(message)
        }
    }
    
    func printLists(_ message: String) {
        if printLists {
            print(message)
        }
    }
    
    func printTime(_ message: String) {
        if printTime {
            print(message)
        }
    }
    
    func printProfile(_ message: String) {
        if printProfile {
            print(message)
        }
    }
    
    func printPhotoPicker(_ message: String) {
        if printPhotoPicker {
            print(message)
        }
    }
    
    func printAppDelegate(_ message: String) {
        if printAppDelegate {
            print(message)
        }
    }
    
    func printLogin(_ message: String) {
        if printLogin {
            print(message)
        }
    }
    
    func printLocationServices(_ message: String) {
        if printLocationServices {
            print(message)
        }
    }
    
    func printFroopCreation(_ message: String) {
        if printFroopCreation {
            print(message)
        }
    }
    
    func printInviteFriends(_ message: String) {
        if printInviteFriends {
            print(message)
        }
    }
    
    func printFriendList(_ message: String) {
        if printFriendList {
            print(message)
        }
    }
    
    func printFroopDetails(_ message: String) {
        if printFroopDetails {
            print(message)
        }
    }
    
    func printFroopUpdates(_ message: String) {
        if printFroopUpdates {
            print(message)
        }
    }
    
    func printFirebaseOperations(_ message: String) {
        if printFirebaseOperations {
            print(message)
        }
    }
    
    func printErrorMessages(_ message: String, file: String = #file, line: Int = #line, function: String = #function) {
        if printPhotoPicker {
            let fileName = (file as NSString).lastPathComponent // To get just the file's name, not the whole path
            print("\(fileName):\(line) \(function) - \(message)")
        }
    }
    
    func printAppStateSetupListener(_ message: String) {
        if printAppStateSetupListener {
            print(message)
        }
    }
    
    func printAppState(_ message: String) {
        if printAppState {
            print(message)
        }
    }

    func printUserDataUpdates(_ message: String) {
        if printUserDataUpdates {
            print(message)
        }
    }
}
