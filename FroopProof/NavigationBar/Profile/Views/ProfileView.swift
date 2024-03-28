//
//  ProfileView.swift
//  FroopProof
//
//  Created by David Reed on 8/9/23.
//

import SwiftUI
import Kingfisher
import UIKit
import Combine

struct ProfileView: View {
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
//    @ObservedObject var froopManager = FroopManager.shared
//    @ObservedObject var friendStore = FriendStore()
//    @ObservedObject var mediaManager = MediaManager()
    @ObservedObject var invitationList: InvitationList = InvitationList(uid: FirebaseServices.shared.uid)
    @ObservedObject var photoData = PhotoData()
    @State var statusX = "pending"
    @State var friendInviteList: [FriendInviteData] = []
    @State var locationSearchViewModel = LocationSearchViewModel()
    @State var areThereFriendRequests: Bool = false
    @State var profileTab: Int = 1
    @Binding var globalChat: Bool
    
    var uid = FirebaseServices.shared.uid
    var db = FirebaseServices.shared.db
    
    init(globalChat: Binding <Bool>) {
        UISegmentedControl.appearance().selectedSegmentTintColor = .white
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(red: 50/255, green: 46/255, blue: 62/255, alpha: 1.0)], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.gray], for: .normal)
    _globalChat = globalChat
    }
    
    
    var body: some View {
        VStack{
            ZStack (alignment: .top) {
                //                Color.offWhite
                Rectangle()
                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .opacity(1)
                    .offset(y: 0)
                    .frame(height: 160)
                    .ignoresSafeArea()
                    .onAppear {
                        TimerServices.shared.shouldCallupdateUserLocationInFirestore = false
                        TimerServices.shared.shouldCallAppStateTransition = false
                    }

                ZStack {
                    Picker("", selection: $profileTab) {
                        Text("My Profile").tag(0)
                        Text("My Friends").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .foregroundColor(.white)
                    .padding(.top, 35)
                    .padding(.bottom, 10)
                    .padding(.leading, 25)
                    .padding(.trailing, 25)
                    .frame(height: 50)
                   
                    .onChange(of: profileTab) { (oldValue, newValue) in
                        if newValue == 0 {
                            withAnimation {
                                dataController.profileToggle = true
//                                print(dataController.profileToggle)
                            }
                        } else {
                            withAnimation {
                                dataController.profileToggle = false
//                                print(dataController.profileToggle)
                            }
                        }
                    }
                }
                .onAppear {
                    if dataController.numberOfFriendRequests > 0 {
                        profileTab = 1
                    }
                }
                
                

                if profileTab == 0 {
                    ProfileListView(photoData: photoData)
                        .padding(.top, 160)
                        .ignoresSafeArea()
                } else {
                    MainFriendView(areThereFriendRequests: $areThereFriendRequests, timestamp: Date(), globalChat: $globalChat)
                        .padding(.top, 160)
                        .ignoresSafeArea()
                }
            }
            .navigationTitle(profileTab == 0 ? "Profile" : "Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(red: 50/255, green: 46/255, blue: 62/255), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        Spacer()
    }
}
