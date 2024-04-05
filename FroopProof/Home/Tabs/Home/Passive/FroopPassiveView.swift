//
//  FroopPassiveView.swift
//  FroopProof
//
//  Created by David Reed on 5/18/23.
//

import SwiftUI
import UserNotifications
import FirebaseAuth
import FirebaseFirestore


struct FroopPassiveView: View {
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var timeZoneManager:TimeZoneManager = TimeZoneManager()
    
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var changeView = ChangeView()
    @ObservedObject var froopData = FroopData.shared

    @State var instanceFroop: FroopHistory
//    @State var selectedFriend: UserData = UserData()
    @State private var walkthroughScreen: NFWalkthroughScreen? = nil
    @State var showSheet = false
    @State var froopAdded = false
    @State private var sortedIndices: [Int] = []
    @State private var currentIndex: Int = 0
    @State private var now = Date()
    @State private var loadIndex = 0
    @State var friendDetailOpen: Bool = false
    @Binding var globalChat: Bool

    var walkthroughView: some View {
        walkthroughScreen
            .environmentObject(changeView)
            .environmentObject(froopData)
    }
    
    var body: some View {
        
        Text(froopManager.froopHistory.count == 0 ? "Your friend's Froops will show up here if they have decided to share them with their community." : "")
            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
            .font(.system(size: 20))
            .fontWeight(.regular)
            .frame(width: 300)
        
        ZStack (alignment: .top){
            Color.white
            VStack {
                UserDetailView(instanceFroop: instanceFroop, friendDetailOpen: $friendDetailOpen, globalChat: $globalChat)
                    .ignoresSafeArea()
                    .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight)
            }
        }
        .onAppear {
            globalChat = true
        }
        
        .fullScreenCover(isPresented: $friendDetailOpen) {
        } content: {
            ZStack {
                VStack {
                    Spacer()
                    FriendDetailView(globalChat: $globalChat)
                    //                        .ignoresSafeArea()
                }
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .blendMode(.difference)
                            .padding(.trailing, 40)
                            .padding(.top, UIScreen.screenHeight * 0.005)
                            .onTapGesture {
                                self.friendDetailOpen = false
                                print("CLEAR TAP MainFriendView 3")
                            }
                    }
                    .frame(alignment: .trailing)
                    Spacer()
                }
            }
        }
        
        .sheet(isPresented: $froopManager.showInviteUrlView) {
        } content: {
            ZStack {
                VStack {
                    CopyableTextView(url: froopManager.selectedFroopHistory.froop.inviteUrl)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .blendMode(.difference)
                            .padding(.trailing, 40)
                            .padding(.top, UIScreen.screenHeight * 0.005)
                            .onTapGesture {
                                froopManager.showInviteUrlView = false
                            }
                    }
                    .frame(alignment: .trailing)
                    Spacer()
                }
            }
        }
        
        if froopManager.showVideoPlayer {
            CustomVideoPlayerView(videoURLString: froopManager.selectedFroopHistory.froop.froopIntroVideo == "" ? froopManager.videoUrl : froopManager.selectedFroopHistory.froop.froopIntroVideo) {
                froopManager.showVideoPlayer = false
            }
        }
    }
    
    func eveningText () -> String {
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        var greeting: String
        if hour < 12 {
            greeting = "Good Morning"
        } else if hour < 17 {
            greeting = "Good Afternoon"
        } else {
            greeting = "Good Evening"
        }
        
        return greeting
    }
    func formatTime(creationTime: Date) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .hour, .day]
        formatter.unitsStyle = .abbreviated
        
        let currentTime = Date()
        let timeSinceCreation = currentTime.timeIntervalSince(creationTime)
        
        let formattedTime = formatter.string(from: timeSinceCreation) ?? ""
        
        return formattedTime
    }
    
}

struct CopyableTextView: View {
    @ObservedObject var froopManager = FroopManager.shared
    let url: String
    @State private var showCopyConfirmation: Bool = false

    var body: some View {
        ZStack {
            
        }
        Text("URL UNDER HERE")
        Text(froopManager.selectedFroopHistory.froop.inviteUrl)
            .foregroundColor(Color(red: 255/255, green: 49/255, blue: 97/255)) // Style as needed
            .onTapGesture {
                UIPasteboard.general.string = froopManager.selectedFroopHistory.froop.inviteUrl
                showCopyConfirmation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    // Hide confirmation after 2 seconds
                    showCopyConfirmation = false
                }
            }
            .overlay(
                Group {
                    if showCopyConfirmation {
                        Text("Copied!")
                            .font(.caption)
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .padding(8)
                            .background(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.25))
                            .clipShape(Capsule())
                            .transition(.scale.combined(with: .opacity))
                            .zIndex(1)
                    }
                }
            )
            .animation(.easeInOut, value: showCopyConfirmation)
    }
}
