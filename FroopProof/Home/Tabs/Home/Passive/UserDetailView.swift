//
//  UserDetailView.swift
//  FroopProof
//
//  Created by David Reed on 2/16/23.
//

import SwiftUI
import UserNotifications

struct UserDetailView: View {
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopListStatus = HomeView2ViewModel()
    @ObservedObject var payManager = PayWallManager.shared

    @State private var mapState = MapViewState.locationSelected
    @State var showInviteView = false
    @State var profileView: Bool = true
    @State var detailFroopData: Froop = Froop(dictionary: [:])
    @State var selectedFroopUUID = FroopManager.shared.selectedFroopUUID
    @State var froopDetailsOpen = FroopManager.shared.froopDetailOpen
    @State var invitedFriends: [UserData] = []
    @State var instanceFroop: FroopHistory
    @State var froopAdded = false
    
    @Binding var friendDetailOpen: Bool
    @Binding var globalChat: Bool
    var uid = FirebaseServices.shared.uid
    
    
    var body: some View {
        ZStack {
            Color.white
            GeometryReader {
                let size = $0.size
                let safeArea = $0.safeAreaInsets
                
                MyUserPublicView(size: size, safeArea: safeArea, friendDetailOpen: $friendDetailOpen)
                    .ignoresSafeArea()
                
            }
        }
        
        .fullScreenCover(isPresented: $froopManager.froopDetailOpen) {
            
        } content: {
            ZStack (alignment: .top) {
                
                VStack {
                    Spacer()
                    switch froopListStatus.froopListStatus {
                            
                        case .invites:
                            EmptyView()
                            
                        case .confirmed:
                            FroopDetailsView(detailFroopData: $detailFroopData, froopAdded: $froopAdded, globalChat: $globalChat)
                            
                        case .declined:
                            FroopDetailsView(detailFroopData: $detailFroopData, froopAdded: $froopAdded, globalChat: $globalChat)
                            
                        case .archived:
                            FroopDetailsView(detailFroopData: $detailFroopData, froopAdded: $froopAdded, globalChat: $globalChat)
                            
                        case .pending:
                            FroopDetailsView(detailFroopData: $detailFroopData, froopAdded: $froopAdded, globalChat: $globalChat)
                            
                    }
                }
                .ignoresSafeArea()
                if payManager.showIAPView == false {
                    VStack {
                        Text("tap to close")
                            .font(.system(size: 18))
                            .fontWeight(.light)
                            .foregroundColor(.white).opacity(1)
                            .padding(.top, 20)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 24))
                            .foregroundColor(.white).opacity(1)
                        Spacer()
                    }
                    .opacity(froopManager.froopMapOpen ? 0 : 1.0)
                    .offset(y: -25)
                    .onTapGesture {
                        if appStateManager.appState == .active && froopManager.comeFrom {
                            froopManager.froopDetailOpen = false
                            locationServices.selectedTab = .froop
                            locationServices.selectedFroopTab = .info
                            froopManager.comeFrom = false
                        } else {
                            froopManager.froopDetailOpen = false
                            froopManager.froopListener?.remove()
                        }
                    }
                    .frame(alignment: .center)
                    .padding(.top, 10)
                }
            }
            .presentationDetents([.large])
        }
    }
}

