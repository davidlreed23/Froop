//
//  FroopSavedTemplates.swift
//  FroopProof
//
//  Created by David Reed on 6/18/23.
//

import SwiftUI

struct FroopSavedTemplates: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var changeView = ChangeView.shared
    @ObservedObject var froopData: FroopData
//    @State var froop = Froop(dictionary: [:])

    
    var body: some View {
        VStack {
            // Use a ScrollView if you want to manually manage the content
            // or a List if you want the built-in iOS features
            ScrollView {
                ForEach(froopManager.froopTemplates, id: \.froopId) { froop in
                    FroopCardView(froop: froop, froopData: froopData, froopDetailOpen: $froopManager.froopDetailOpen, invitedFriends: $froopManager.invitedFriends)
                }
            }
        }
    }
}
