//
//  MyCardsView.swift
//  FroopProof
//
//  Created by David Reed on 8/9/23.
//


import SwiftUI
import Kingfisher
import AVKit

struct MyCardsView: View {

    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    // @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var froopTypeStore = FroopTypeStore.shared
    
    let currentUserId = FirebaseServices.shared.uid
    var db = FirebaseServices.shared.db
    let froopHostAndFriends: FroopHistory
    @State private var offset: CGFloat = 0
    @State private var isDragging = false
    @State private var hostFirstName: String = ""
    @State private var hostLastName: String = ""
    @State private var hostURL: String = ""
    @State private var showAlert = false
    @State private var selectedImageIndex = 0
    @State private var isMigrating = false
    @State private var isDownloading = false
    @State private var downloadedImages: [String: Bool] = [:]
    @State private var isImageSectionVisible: Bool = true
    @State private var froopTypeArray: [FroopType] = []
    @State private var thisFroopType: String = ""
    @Binding var friendDetailOpen: Bool
    @State private var selectedMediaIndex = 0 // To track the selected media index

    @State var openFroop: Bool = false

    init(froopHostAndFriends: FroopHistory, thisFroopType: String, friendDetailOpen: Binding <Bool>) {
        self.froopHostAndFriends = froopHostAndFriends
        _friendDetailOpen = friendDetailOpen
    }
    
    var body: some View {
        ZStack {
            VStack (){
                HStack {
                    KFImage(URL(string: froopHostAndFriends.host.profileImageUrl))
                        .placeholder {
                            ProgressView()
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50, alignment: .leading)
                        .clipShape(Circle())
                        .padding(.leading, 10)
                        .padding(.top, 5)
                    
                        .onTapGesture {
                            friendDetailOpen = true
                        }
                    VStack (alignment:.leading){
                        Text(froopHostAndFriends.froop.froopName)
                            .font(.system(size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? Color(red: 50/255, green: 46/255, blue: 62/255) : Color(red: 50/255, green: 46/255, blue: 62/255))
                            .multilineTextAlignment(.leading)
                            .offset(y: 6)
                        HStack (alignment: .center){
                            Text("Host:")
                                .font(.system(size: 14))
                                .fontWeight(.light)
                                .foregroundColor(colorScheme == .dark ? Color(red: 50/255, green: 46/255, blue: 62/255) : Color(red: 50/255, green: 46/255, blue: 62/255))
                                .multilineTextAlignment(.leading)
                            
                            Text(froopHostAndFriends.host.firstName)
                                .font(.system(size: 14))
                                .fontWeight(.light)
                                .foregroundColor(colorScheme == .dark ? Color(red: 50/255, green: 46/255, blue: 62/255) : Color(red: 50/255, green: 46/255, blue: 62/255))
                                .multilineTextAlignment(.leading)
                            
                            Text(froopHostAndFriends.host.lastName)
                                .font(.system(size: 14))
                                .fontWeight(.light)
                                .foregroundColor(colorScheme == .dark ? Color(red: 50/255, green: 46/255, blue: 62/255) : Color(red: 50/255, green: 46/255, blue: 62/255))
                                .multilineTextAlignment(.leading)
                                .offset(x: -5)
                        }
                        .offset(y: 6)
                        
                        Text("\(formatDate(for: froopHostAndFriends.froop.froopStartTime))")
                            .font(.system(size: 14))
                            .fontWeight(.thin)
                            .foregroundColor(colorScheme == .dark ? Color(red: 50/255, green: 46/255, blue: 62/255) : Color(red: 50/255, green: 46/255, blue: 62/255))
                            .multilineTextAlignment(.leading)
                            .padding(.top, 2)
                            .offset(y: -6)
                    }
                    .padding(.top, 5)
                    
                    Spacer()
                    
                }
                .background(Color(red: 251/255, green: 251/255, blue: 249/255))
//                .padding(.horizontal, 10)
                .padding(.bottom, 1)
                .frame(maxHeight: 60)

                ZStack {
                    Rectangle()
                        .frame(minWidth: UIScreen.main.bounds.width, maxWidth: UIScreen.main.bounds.width, minHeight: UIScreen.main.bounds.width * 1.3333, maxHeight: UIScreen.main.bounds.width * 1.3333)
                        .foregroundColor(.white)
                    TabView(selection: $selectedMediaIndex) {
                        // Check if there are video thumbnails to display
                        if !froopHostAndFriends.froop.froopVideoThumbnails.isEmpty {
                            ForEach(froopHostAndFriends.froop.froopVideos.indices, id: \.self) { index in
                                ZStack {
                                    KFImage(URL(string: froopHostAndFriends.froop.froopVideoThumbnails[safe: index] ?? ""))
                                        .resizable()
                                        .scaledToFit()
                                    Image(systemName: "play.circle")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.white)
                                        .frame(width: 50, height: 50)
                                }
                                .onTapGesture {
                                    froopManager.videoUrl = froopHostAndFriends.froop.froopVideos[safe: index] ?? ""
                                    froopManager.showVideoPlayer = true
                                    //playVideo(at: index)
                                }
                                .tag(index)
                            }
                        }
                        
                        // Check if there are display images to show
                        if !froopHostAndFriends.froop.froopDisplayImages.isEmpty {
                            ForEach(froopHostAndFriends.froop.froopDisplayImages.indices, id: \.self) { index in
                                KFImage(URL(string: froopHostAndFriends.froop.froopDisplayImages[safe: index] ?? ""))
                                    .resizable()
                                    .scaledToFit()
                                    .tag(index + froopHostAndFriends.froop.froopVideos.count) // Ensure unique tags across both images and videos
                            }
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                }

                //.matchedGeometryEffect(id: "ZStackAnimation", in: animation)
                //.transition(froopManager.areAllCardsExpanded ? .move(edge: .top) : .move(edge: .bottom))
                .background(Color(.white))
                
                Divider()
                    .padding(.top, 10)
            }
            
        }
        .onTapGesture {
            print("tap")
            for friend in froopHostAndFriends.confirmedFriends {
                
                print(friend.firstName)
            }
        }
    }
    
    func playVideo(at index: Int) {
        // Assume you have URLs for videos similar to how you have froopDisplayImages
        guard let videoURLString = froopHostAndFriends.froop.froopVideos[safe: index],
              let url = URL(string: videoURLString) else { return }
        // Present a video player
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        // Present the player view controller modally (requires UIViewControllerRepresentable or using UIKit integration)
        // Note: Implement this part based on your app's architecture, either via UIKit integration or another SwiftUI view
    }
    
    
    func formatDate(for date: Date) -> String {

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE MMM.dd.yyyy 'at' h:mm a"
        // Set the time zone to the current location's time zone
//        if let timeZone = TimeZoneManager.shared.userLocationTimeZone {
//            formatter.timeZone = timeZone
//        }
        return formatter.string(from: date)
    }
    
    var downloadButton: some View {
        // check if current user's id is in the friend list
        let isFriend = froopHostAndFriends.confirmedFriends.contains { $0.froopUserID == currentUserId }
        
        if isFriend {
            return AnyView(
                Button(action: {
                    isDownloading = true
                    downloadImage()
                }) {
                    if selectedImageIndex < froopHostAndFriends.froop.froopImages.count {
                        let imageKey = froopHostAndFriends.froop.froopImages[selectedImageIndex]
                        let isImageDownloaded = downloadedImages[imageKey] ?? false
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .frame(width: 36, height: 36)
                                .foregroundColor(isImageDownloaded ? .clear : Color(.white).opacity(0.7))
                            Image(systemName: "icloud.and.arrow.down")
                                .font(.system(size: 20))
                                .fontWeight(.thin)
                                .foregroundColor(isImageDownloaded ? .clear : Color(red: 249/255, green: 0/255, blue: 98/255))
                        }
                    } else {
                        // You may want to provide some default Image or other view when there's an error
                        EmptyView()
                    }
                }
                    .frame(width: 36, height: 36)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .disabled(isDownloading)
                    .padding()
            )
        } else {
            return AnyView(EmptyView())
        }
    }
    
    func downloadImage() {
        guard let url = URL(string: froopHostAndFriends.froop.froopImages[selectedImageIndex]) else { return }
        
        // Check if the image has already been downloaded
        if downloadedImages[froopHostAndFriends.froop.froopImages[selectedImageIndex]] == true {
            print("Image already downloaded")
            return
        }
        
        KingfisherManager.shared.retrieveImage(with: url) { result in
            switch result {
                case .success(let value):
                    UIImageWriteToSavedPhotosAlbum(value.image, nil, nil, nil)
                    downloadedImages[froopHostAndFriends.froop.froopImages[selectedImageIndex]] = true
                case .failure(let error):
                    print("🚫Error downloading image: \(error)")
            }
            isDownloading = false
        }
    }
}
