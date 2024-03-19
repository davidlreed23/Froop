//
//  FroopTypeOrTemplate.swift
//  FroopProof
//
//  Created by David Reed on 6/18/23.
//

import SwiftUI
import iPhoneNumberField
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import UIKit


struct FroopTypeOrTemplate: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    // @ObservedObject var froopDataListener = FroopDataListener.shared
    @State private var mapState = MapViewState.noInput
    @ObservedObject var froopData: FroopData
    var onFroopNamed: (() -> Void)?
    @State private var showAlert = false
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @ObservedObject var froopTypeStore = FroopTypeStore()
    @State var searchText: String = ""
    @State var selectedFroopType: FroopType?
    
    // Add a state variable for the selected tab
    @State private var selectedTab = 0

    var body: some View {

            ZStack {
                Color.offWhite
                VStack {
                    Text("What kind of Froop do you want to create?")
                        .frame(maxWidth: 400)
                        .fontWeight(.semibold)
                        .font(.system(size: 26))
                        .multilineTextAlignment(.center)
                        .padding(.top, 25)
                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                        .padding(.leading, 25)
                        .padding(.trailing, 25)
                       
                    TextField("Search", text: $searchText)
                        .frame(maxWidth: 400)
                        .foregroundColor(colorScheme == .dark ? .white : Color(red: 50/255, green: 46/255, blue: 62/255))
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.trailing, 15)
                        .padding(.leading, 15)
                        
                    
                    // Add a Picker for the tabs
                    Picker("", selection: $selectedTab) {
                        Text("Select Type").tag(0)
                        Text("Saved Templates").tag(1)
                    }
                    .foregroundColor(colorScheme == .dark ? Color(red: 50/255, green: 46/255, blue: 62/255) : Color(red: 50/255, green: 46/255, blue: 62/255))
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                    
                    // Add a TabView for the content
                    TabView(selection: $selectedTab) {
                        FroopTypeView(froopData: froopData, searchText: $searchText)
                            .tag(0)
                        FroopSavedTemplates(froopData: froopData)
                            .tag(1)
                    }
                }
    
            }
        
    }
}

