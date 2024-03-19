////
////  NonActiveMapView.swift
////  FroopProof
////
////  Created by David Reed on 8/16/23.
////
//
//import Combine
//import SwiftUI
//import MapKit
//import FirebaseFirestore
//import Kingfisher
//import CoreLocation
//import SwiftUIBlurView
//
//
//
//struct NonActiveMapView: View {
//    @ObservedObject var mapManager = MapManager.shared
//
//    @EnvironmentObject var locationSearchViewModel: LocationSearchViewModel
//    @EnvironmentObject var homeViewModel: HomeViewModel
//    
//    @ObservedObject var appStateManager = AppStateManager.shared
//    @ObservedObject var printControl = PrintControl.shared
//    @ObservedObject var locationServices = LocationServices.shared
//    // @ObservedObject var froopDataListener = FroopDataListener.shared
//    @ObservedObject var locationManager = LocationManager.shared
//    @ObservedObject var froopManager = FroopManager.shared
//    
//    
//    @Binding var mapState: MapViewState
//    @Binding var froopMapOpen: Bool
//    @Binding var globalChat: Bool
//
//    @State var instanceFroop: FroopHistory = FroopHistory(
//        froop: Froop(dictionary: [:]),
//        host: UserData(),
//        invitedFriends: [],
//        confirmedFriends: [],
//        declinedFriends: [],
//        images: [],
//        videos: [],
//        froopGroupConversationAndMessages: ConversationAndMessages(conversation: Conversation(), messages: [], participants: []), froopMediaData: FroopMediaData(
//            froopImages: [],
//            froopDisplayImages: [],
//            froopThumbnailImages: [],
//            froopIntroVideo: "",
//            froopIntroVideoThumbnail: "",
//            froopVideos: [],
//            froopVideoThumbnails: []
//        )
//    )
//    
//    var body: some View {
//        ZStack {
//            PassiveMapView(froopHistory: instanceFroop, globalChat: $globalChat)
//            
//        }
//    }
//}
