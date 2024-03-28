//
//  MyFroopsView.swift
//  FroopProof
//
//  Created by David Reed on 5/18/23.
//

import SwiftUI

struct MyFroopsView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var timeZoneManager:TimeZoneManager = TimeZoneManager()
    
    @ObservedObject var myData = MyData.shared
    @ObservedObject var changeView = ChangeView()
    @ObservedObject var froopData = FroopData.shared
    @State var refresh = UUID()
    var uid = FirebaseServices.shared.uid
    
    @State private var froopFeed: [FroopHostAndFriends] = []
    @State private var walkthroughScreen: NFWalkthroughScreen? = nil
    @State var showSheet = false
    @State var froopAdded = false
    @State var showNFWalkthroughScreen = false
    @State private var currentIndex: Int = 0
    @State private var now = Date()
    @State private var loadIndex = 0
    @State private var isFroopFetchingComplete = false
    @State private var thisFroopType: String = ""
    @State var openFroop: Bool = false
    @State var showHidden: Bool = false
    @Binding var friendDetailOpen: Bool

    var heightOfOneCard: CGFloat {
        (UIScreen.main.bounds.width * 1.5) + 150
    }
    
    var estimatedHeightOfLazyVStack: CGFloat {
        CGFloat(sortedFroopsForSelectedFriend.count) * heightOfOneCard + 50.0
    }
    
    var estimatedHeightOfVStack: CGFloat {
        CGFloat(displayedFroops.count) * 100 + 50.0
    }
    
    @ViewBuilder
    var dynamicStack: some View {
        if froopManager.areAllCardsExpanded {
            LazyVStack (alignment: .leading, spacing: 0) {
                stackContent
            }
            .ignoresSafeArea()
            .onAppear {
                print("Number of froops in froopFeed: \(froopManager.froopFeed.count)")
            }
        } else {
            VStack (alignment: .leading, spacing: 0) {
                stackContent
            }
            .ignoresSafeArea()
            .onAppear {
                print("Number of froops in froopFeed: \(froopManager.froopFeed.count)")
            }
        }
    }

    var stackContent: some View {
        ForEach(sortedFroopsForSelectedFriend, id: \.self) { froopHistory in
            MyCardsView(froopHostAndFriends: froopHistory, thisFroopType: thisFroopType, friendDetailOpen: $friendDetailOpen)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Increment the current index when a card finishes loading
                        currentIndex += 1
                    }
                }
        }
    }
    
    var displayedFroops: [FroopHistory] {
        return froopManager.froopHistory.filter { froopHistory in
            switch froopHistory.froopStatus {
                case .invited, .confirmed, .archived, .memory:
                return true
            case .declined:
                return froopHistory.froop.froopHost == uid
            default:
                return false
            }
        }
    }
    
    var filteredFroopsForSelectedFriend: [FroopHistory] {
        return displayedFroops.filter {
            !$0.images.isEmpty &&
            ($0.host.froopUserID == froopManager.myData.froopUserID ||
             $0.confirmedFriends.contains(where: { $0.froopUserID == froopManager.myData.froopUserID }))
        }
    }
    
    var sortedFroopsForSelectedFriend: [FroopHistory] {
        return filteredFroopsForSelectedFriend.sorted(by: { $0.froop.froopStartTime > $1.froop.froopStartTime })
    }
    
    var sortedFroopsForUser: [FroopHistory] {
        let now = Date()
        let uid = FirebaseServices.shared.uid

        // Split into past and future events
        let pastFroops = displayedFroops.filter { $0.froop.froopEndTime < now && !$0.froop.hidden.contains(uid) }
        let futureFroops = displayedFroops.filter { $0.froop.froopEndTime >= now && !$0.froop.hidden.contains(uid) }
        
        // Sort past events from most recent to oldest
        let sortedPastFroops = pastFroops.sorted { $0.froop.froopEndTime > $1.froop.froopEndTime }
        
        // Sort future events from nearest to farthest
        let sortedFutureFroops = futureFroops.sorted { $0.froop.froopEndTime < $1.froop.froopEndTime }
        
        // Combine them with future events first
        return sortedFutureFroops + sortedPastFroops
    }
    
    var sortedHiddenFroopsForUser: [FroopHistory] {
        let now = Date()
        let uid = FirebaseServices.shared.uid

        // Split into past and future events
        let pastFroops = displayedFroops.filter { $0.froop.froopEndTime < now && $0.froop.hidden.contains(uid) }
        let futureFroops = displayedFroops.filter { $0.froop.froopEndTime >= now && $0.froop.hidden.contains(uid) }
        
        // Sort past events from most recent to oldest
        let sortedPastFroops = pastFroops.sorted { $0.froop.froopEndTime > $1.froop.froopEndTime }
        
        // Sort future events from nearest to farthest
        let sortedFutureFroops = futureFroops.sorted { $0.froop.froopEndTime < $1.froop.froopEndTime }
        
        // Combine them with future events first
        return sortedFutureFroops + sortedPastFroops
    }
    
    
    let hVTimer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()
    
    
    var timeUntilNextFroop: TimeInterval? {
        let nextFroops = FroopDataListener.shared.myConfirmedList.filter { $0.froopStartTime > now }
        guard let nextFroop = nextFroops.min(by: { $0.froopStartTime < $1.froopStartTime }) else {
            // There are no future Froops, so return nil
            return nil
        }
        return nextFroop.froopStartTime.timeIntervalSince(now)
    }
    
    var countdownText: String {
        if let timeUntilNextFroop = timeUntilNextFroop {
            // Use the formatDuration2 function from the timeZoneManager
            return "Next Froop in: \(timeZoneManager.formatDuration2(durationInMinutes: timeUntilNextFroop))"
        } else {
            if AppStateManager.shared.appState == .active {
                return "Froop In Progress!"
            }
            return "No Froops Scheduled"
        }
    }
    
    var walkthroughView: some View {
        walkthroughScreen
            .environmentObject(changeView)
            .environmentObject(froopData)
    }

    var body: some View {
        ZStack (alignment: .top){
            
            Rectangle()
                .frame(height: 1200)
                .foregroundColor(.white)
                .opacity(0.1)
                .onChange(of: froopManager.froopHistory) {
                    self.refresh = UUID()
                }
            
            if froopManager.areAllCardsExpanded {
                VStack {
                    if froopManager.isFroopFetchingComplete {
                        LazyVStack (alignment: .leading, spacing: 0) {
                            ForEach(sortedFroopsForSelectedFriend, id: \.self) { froopHistory in
                                MyCardsView(froopHostAndFriends: froopHistory, thisFroopType: thisFroopType, friendDetailOpen: $friendDetailOpen)
                                    .onAppear {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            // Increment the current index when a card finishes loading
                                            currentIndex += 1
                                        }
                                    }
                            }
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, 75)
            } else {
                VStack {
                    if froopManager.isFroopFetchingComplete {
                        VStack (alignment: .leading, spacing: 0) {
                            if LoadingManager.shared.froopHistoryLoaded {
                                ForEach(sortedFroopsForUser, id: \.self) { froopHistory in
                                    MyMinCardsView(froopHostAndFriends: froopHistory, thisFroopType: thisFroopType)
                                        .onAppear {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                // Increment the current index when a card finishes loading
                                                currentIndex += 1
                                            }
                                        }
                                }
                            }
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(.white).opacity(1)
                                    .frame(width: UIScreen.screenWidth * 0.9, height: 50)
                                    .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.2), radius: 4, x: 4, y: 4)
                                    .shadow(color: Color.white.opacity(0.9), radius: 4, x: -4, y: -4)
                                Text(showHidden ? sortedHiddenFroopsForUser.count == 0 ? "No Hidden Froops" : "Close Hidden View" : sortedHiddenFroopsForUser.count == 0 ? "No Hidden Froops" : "Show Hidden Froops")
                                    .font(.system(size: 18))
                                    .fontWeight(.light)
                                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.75))
                            }
                            .padding(.leading, UIScreen.screenWidth * 0.05)
                            .padding(.trailing, UIScreen.screenWidth * 0.05)
                            .padding(.top, UIScreen.screenWidth * 0.05)
                            .padding(.bottom, UIScreen.screenWidth * 0.05)
                            .onTapGesture {
                                showHidden.toggle()
                            }
                            
                            if sortedHiddenFroopsForUser.count > 0 {
                                if showHidden {
                                    ForEach(sortedHiddenFroopsForUser, id: \.self) { froopHistory in
                                        MyMinCardsView(froopHostAndFriends: froopHistory, thisFroopType: thisFroopType)
                                            .onAppear {
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                                    // Increment the current index when a card finishes loading
                                                    currentIndex += 1
                                                }
                                            }
                                    }
                                }
                            }
                        }
                    }
                    Spacer()
                }
//                .padding(.bottom, 75)
            }
            
        }
        .id(refresh)
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



