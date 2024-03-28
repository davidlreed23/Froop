//
//  RootView.swift
//  FroopProof
//
//  Created by David Reed on 2/11/23.
//

import SwiftUI
import Kingfisher
import FirebaseAuth
import AVKit


struct RootView: View {
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 1
    @Environment(\.colorScheme) var colorScheme
    @StateObject var firebaseServices = FirebaseServices.shared
    @StateObject var froopManager = FroopManager.shared
    @StateObject var froopHistoryService = FroopHistoryService.shared
    @StateObject var appStateManager = AppStateManager.shared
    @StateObject var locationServices = LocationServices.shared
    @StateObject var notificationsManager = NotificationsManager.shared
    @StateObject var locationManager = LocationManager.shared
    @StateObject var printControl = PrintControl.shared
    @StateObject var froopDataController = FroopDataController.shared
    @StateObject var timeZoneManager = TimeZoneManager()
    @StateObject var mediaManager = MediaManager()
    @StateObject var locationSearchViewModel = LocationSearchViewModel()
    @StateObject var froopData = FroopData()
    @StateObject var invitationList: InvitationList = InvitationList(uid: FirebaseServices.shared.uid)
    @StateObject var changeView = ChangeView.shared
    @ObservedObject var friendData: UserData
    @ObservedObject var photoData = PhotoData()
    @ObservedObject var myData = MyData.shared
    @ObservedObject var confirmedFroopsList: ConfirmedFroopsList
//    @ObservedObject var versionChecker: VersionChecker = VersionChecker.shared
    @State var statusX: String = "pending"
    @State var selectedTab: Tab = .froop
    @State var froopTabPosition: Int = 1
    @State var areThereFriendRequests: Bool = false
    @State var uploadedMedia: [MediaData] = []
    @State var friendInviteList: [FriendInviteData] = []
    @State var globalChat: Bool = true
    @State var openGlobalChat: Bool = false
    @State var updateView: Bool = false
    var player: AVPlayer? {
        if let url = URL(string: froopManager.selectedFroopHistory.froop.froopIntroVideo) {
            return AVPlayer(url: url)
        } else {
            return nil
        }
    }

    private var selectedTabBinding: Binding<Tab> {
        Binding(
            get: { LocationServices.shared.selectedTab },
            set: { LocationServices.shared.selectedTab = $0 }
        )
    }
    
    var appDelegate: AppDelegate = AppDelegate()
    
    init(friendData: UserData, photoData: PhotoData, appDelegate: AppDelegate, confirmedFroopsList: ConfirmedFroopsList) {
        UITabBar.appearance().isHidden = false
        self.friendData = friendData
        self.photoData = photoData
        self.appDelegate = appDelegate
        self.confirmedFroopsList = confirmedFroopsList
    }
    
    var body: some View {
       if ProfileCompletionCurrentPage != 2 {
            
            OnboardingView(ProfileCompletionCurrentPage: $ProfileCompletionCurrentPage)
               .ignoresSafeArea()
            
        } else {
            NavigationView {
                ZStack {
                    Color.offWhite
                    VStack{
                        if LocationServices.shared.selectedTab == .froop {
                            FroopTabView(friendData: friendData, viewModel: MediaGridViewModel(), uploadedMedia: $uploadedMedia, thisFroop: Froop.emptyFroop(), froopTabPosition: $froopTabPosition, globalChat: $globalChat)
                                .tag(Tab.froop)
                        }
                    }
                    
                }
                .ignoresSafeArea()
                .navigationTitle("Froop")
                .foregroundColor(colorScheme == .dark ? .white : Color(red: 255/255 ,green: 255/255,blue: 255/255))
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(Color.black.opacity(0.8), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .navigationBarItems(
                    leading:
                        ZStack {
                            Image(systemName: "message.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .fontWeight(.thin)
                            Text("\(notificationsManager.totalUnreadMessages)")
                                .font(.system(size: 16))
                                .fontWeight(.light)
                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                .offset(y: -2)
                            //                                .offset(x: 15)
                                .opacity(notificationsManager.totalUnreadMessages > 0 ? 1.0 : 0.0)
                        }
                        .opacity(notificationsManager.totalUnreadMessages > 0 ? 1.0 : 0.25)
                       
                        .onTapGesture {
                            notificationsManager.openGlobalChat.toggle()
                        },
                    
                    trailing:
                        NavigationLink(destination: ProfileView(globalChat: $globalChat), label: {
                            ZStack {
                                KFImage(URL(string:  MyData.shared.profileImageUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 35, height: 35)
                                    .clipShape(Circle())
                                Text("\(friendInviteList.count)")
                                    .font(.system(size: 16))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                    .offset(y: -15)
                                    .offset(x: 15)
                                    .opacity(friendInviteList.count > 0 ? 1.0 : 0.0)
                                
                            }
                        })
                )
            }
            .onAppear {
                FriendViewController.shared.findFriendInvites(thisUser: Auth.auth().currentUser?.uid ?? "", statusX: statusX) { friendInviteList, error in
                    if let error = error {
                        PrintControl.shared.printErrorMessages("Error fetching friend invites: \(error.localizedDescription)")
                        return
                    }
                    self.friendInviteList = friendInviteList
                }
                PrintControl.shared.printStartUp("RootView Appear")
            }
            .alert(isPresented: $locationManager.showAlert) {
                Alert(title: Text("Geofence Alert"), message: Text(locationManager.alertMessage), dismissButton: .default(Text("OK")))
            }
            .onChange(of: myData.myFriends) { oldValue, newValue in
                if newValue != oldValue {
                    myData.processApprovedFriendRequests(forUID: Auth.auth().currentUser?.uid ?? "")
                }
            }
            
            .fullScreenCover(isPresented: $notificationsManager.openGlobalChat) {
            } content: {

                FroopGlobalMessagesView()
            }
            
        }
    }
}
