//
//  ProfileHeaderView.swift
//  FroopProof
//
//  Created by David Reed on 8/9/23.
//

import SwiftUI
import Kingfisher
import UIKit
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ProfileHeaderView: View {
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var chatManager = FroopChatNotificationsManager.shared
    @ObservedObject var globalChatManager = GlobalChatNotificationsManager.shared
    @ObservedObject var notificationsManager = NotificationsManager.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var inviteManager = InviteManager.shared
    @Binding var offsetY: CGFloat
    @Binding var selectedFriend: UserData
    @Binding var profileView: Bool
    var size: CGSize
    var safeArea: EdgeInsets
    @State private var selectedTab = 0
    @Binding var friendDetailOpen: Bool
    @State var chatViewOpen: Bool = false
    @Binding var globalChat: Bool
    var uid = FirebaseServices.shared.uid
    @State var friendInviteData: FriendInviteData = FriendInviteData(dictionary: [:])
    @State private var showFriendRequestSentAlert = false
    @State var unFriendAlert: Bool = false
    @State var conversationId: String = ""
    
    
    private var headerHeight: CGFloat {
        (size.height * 0.5) + safeArea.top
    }
    
    private var headerWidth: CGFloat {
        (size.width * 0.5)
    }
    
    private var minimumHeaderHeight: CGFloat {
        100 + safeArea.top
    }
    
    private var minimumHeaderWidth: CGFloat {
        0
    }
    
    private var progress: CGFloat {
        max(min(-offsetY / (headerHeight - minimumHeaderHeight), 1), 0)
    }
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                ZStack (alignment: .top) {
                    Rectangle()
                        .fill(Color(.white).gradient)
                    
                    Rectangle()
                        .fill(Color(.white).gradient)
                        .frame(height: 200 * (1 - progress))
                }
                
                VStack(alignment: .center) {
                    HStack {
                        Spacer()
                        if !inviteManager.isFriend(froopUserID: selectedFriend.froopUserID) && selectedFriend.froopUserID != uid {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 206/255, green: 206/255, blue: 206/255).opacity(0.25), Color(red: 255/255, green: 255/255, blue: 255/255)]), startPoint: .top, endPoint: .bottom))
                                    .frame(width: 100, height: 40)
                                    .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.2), radius: 7, x: 7, y: 7)
                                    .shadow(color: Color.white.opacity(0.7), radius: 7, x: -4, y: -4)
                                
                                Text("Remove Friend")
                                    .font(.system(size: 14))
                                    .fontWeight(.regular)
                                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                    .frame(alignment: .center)
                            }
                            .padding(.trailing, 5)
                            .opacity(inviteManager.isFriend(froopUserID: selectedFriend.froopUserID) && selectedFriend.froopUserID != uid ? 1.0 : 0.0)
                            .onTapGesture {
                                if inviteManager.isFriend(froopUserID: selectedFriend.froopUserID) && selectedFriend.froopUserID != uid {
                                    unFriendAlert = true
                                }
                            }
                        }
                        
                        ProfileImage(progress: progress, headerHeight: headerHeight, selectedFriend: $selectedFriend)
                        
                        if !inviteManager.isFriend(froopUserID: selectedFriend.froopUserID) && selectedFriend.froopUserID != uid {
                            if isFriendshipRequested(toUserID: selectedFriend.froopUserID) {
                                Text("Friendship Requested")
                                    .font(.system(size: 14))
                                    .fontWeight(.regular)
                                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                    .frame(alignment: .center)
                            } else {
                                
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 206/255, green: 206/255, blue: 206/255).opacity(0.25), Color(red: 255/255, green: 255/255, blue: 255/255)]), startPoint: .top, endPoint: .bottom))
                                        .frame(width: 100, height: 40)
                                        .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.2), radius: 7, x: 7, y: 7)
                                        .shadow(color: Color.white.opacity(0.7), radius: 7, x: -4, y: -4)
                                    
                                    Text("Add Friend")
                                        .font(.system(size: 14))
                                        .fontWeight(.regular)
                                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                        .frame(alignment: .center)
                                }
                                .onTapGesture {
                                    let timestamp = Date()
                                    sendFriendRequest(fromUserID: uid, toUserID: selectedFriend.froopUserID, friendRequest: friendInviteData, timestamp: timestamp) { result in
                                        switch result {
                                            case .success(let documentID):
                                                print("Friend request sent: \(documentID)")
                                            case .failure(let error):
                                                print("🚫Error sending friend request: \(error.localizedDescription)")
                                        }
                                    }
                                }
                                .padding(.leading, 5)
                            }
                        }
                        Spacer()
                    }
                    .padding(.top, 85)
                    .offset(y: 35)
                    .onTapGesture {
                        chatManager.printFroopConversationsAndMessages()
                    }
                    
                    HStack {
                        Spacer()
                        Text("\(selectedFriend.firstName) \(selectedFriend.lastName)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .opacity(0.8)
                            .frame(alignment: .leading)
                        //                            .moveText(progress, headerHeight, minimumHeaderHeight, headerWidth, minimumHeaderWidth)
                        Spacer()
                    }
                    .offset(y: 35)
                    
                    ZStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                print(globalChat)
                                if globalChat {
                                    notificationsManager.currentChatContext = .global
                                } else {
                                    notificationsManager.currentChatContext = .activeFroop(hostId: appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.froopUserID ?? "")
                                    
                                }
                                chatViewOpen = true
                            }) {
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 32))
                                    .fontWeight(.thin)
                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                    .opacity(0.8)
                            }
                            Spacer()
                        }
                        .offset(y: 25)
                        .frame(height: 50 - (1 * progress))
                        //                        .moveSymbols(progress, headerHeight, minimumHeaderHeight, headerWidth, minimumHeaderWidth)
                        .opacity(selectedFriend.froopUserID == "froop" ? 1 : 0)
                        
                        HStack (spacing: 45) {
                            Spacer()
                            Button(action: {
                                self.makePhoneCall(phoneNumber: selectedFriend.phoneNumber)
                            }) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 32))
                                    .fontWeight(.thin)
                                    .foregroundColor(.green)
                                    .opacity(0.8)
                            }
                            
                            Button(action: {
                                print(globalChat)
                                if globalChat {
                                    notificationsManager.currentChatContext = .global
                                    globalChatManager.findOrCreateConversation(with: selectedFriend.froopUserID) { conversationId in
                                        self.conversationId = conversationId
                                        globalChatManager.otherUserId = selectedFriend.froopUserID
                                        globalChatManager.selectedFriend = selectedFriend
                                        globalChatManager.conversationId = conversationId
                                        print("👀\(conversationId)")
                                        print("👀👀\(globalChatManager.conversationId)")
                                        print("🔆🔆notificationsManager's currentConverstion id:  \(globalChatManager.currentConversation?.id ?? "NO ID FOUND")")
                                        print("🔆🔆notificationsManager's currentConverstion id:  \(globalChatManager.conversationId)")

                                        chatViewOpen = true
                                    }
                                    
                                } else {
                                    notificationsManager.currentChatContext = .activeFroop(hostId: appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopHost ?? "")
                                    chatViewOpen = true
                                    
                                    print("Current Chat Context: \(String(describing: notificationsManager.currentChatContext))")
                                    print("selectedFriend: \(selectedFriend)")
                                    print("chatPartnerUID: \(selectedFriend.froopUserID)")
                                    print("Selected Conversation: \(selectedFriend)")
                                    
                                }
                                
                            }) {
                                Image(systemName: "text.bubble.fill")
                                    .font(.system(size: 32))
                                    .fontWeight(.thin)
                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                    .opacity(0.8)
                            }
                            
                            Button(action: {
                                self.sendTextMessage(phoneNumber: selectedFriend.phoneNumber)
                            }) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 32))
                                    .fontWeight(.thin)
                                    .foregroundColor(Color(red: 255/255, green: 49/255, blue: 97/255))
                                    .opacity(0.8)
                            }
                            Spacer()
                        }
                        .offset(y: 25)
                        .frame(height: 50 - (1 * progress))
                        //                        .moveSymbols(progress, headerHeight, minimumHeaderHeight, headerWidth, minimumHeaderWidth)
                        .opacity(selectedFriend.froopUserID == "froop" ? 0 : 1)
                    }
                    
                    HStack {
                        Spacer()
                        Text(selectedFriend.userDescription == "" ? ("Member since: \(formatDateToTimeZone(passedDate: selectedFriend.creationDate, timeZoneIdentifier: selectedFriend.timeZone))") : ("\(selectedFriend.userDescription)")).italic()
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .opacity(0.6)
                            .lineLimit(2)
                            .fontWeight(.light)
                            .italic()
                            .frame(height: 75 - (1 * progress), alignment: .center)
                            .ignoresSafeArea()
                        Spacer()
                    }
                    .offset(y: 10)
                    .padding(.leading, 25)
                    .padding(.trailing, 25)
                    .opacity(1.0 * (1 - progress))
                    
                    Spacer()
                    
                    Picker("", selection: $selectedTab) {
                        if selectedFriend.froopUserID == "froop" {
                            Text("Froops").tag(0)
                        } else {
                            Text("Froops").tag(0)
                            Text("Friends").tag(1)
                        }
                    }
                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.leading, 25 + (75 * progress))
                    .padding(.trailing, 25 + (75 * progress))
                    .frame(height: 50)
                    .onChange(of: selectedTab) { oldValue, newValue in
                        dataController.allSelected = 0
                        profileView = (newValue == 0) // profileView is true when Froops is selected, false otherwise
                    }
                    //                    .moveMenu(progress, headerHeight, minimumHeaderHeight, headerWidth, minimumHeaderWidth)
                    
                    
                }
                
                .padding(.top, safeArea.top)
                .padding(.bottom, 15)
            }
            .frame(height: (headerHeight + offsetY) < minimumHeaderHeight ? minimumHeaderHeight : (headerHeight + offsetY), alignment: .bottom)
            .offset(y: -offsetY)
        }
        .frame(height: headerHeight)
        
        .blurredSheet(.init(.ultraThinMaterial), show: $chatViewOpen) {
            chatViewOpen = false
        } content: {
            ZStack {

                VStack {
                    Spacer()
                    if globalChat {
                        ChatView(selectedFriend: $selectedFriend, conversationId: $conversationId)
                            .padding(.top, UIScreen.screenHeight / 15)
                            .ignoresSafeArea()
                    } else {
                        FroopChatView(selectedFriend: $selectedFriend, chatPartnerUID: selectedFriend.froopUserID, selectedConversation: $selectedFriend)
                            .ignoresSafeArea()
                    }
                }

                VStack {
                    ZStack{
                        VStack {
                            Rectangle()
                                .frame(height: UIScreen.screenHeight / 6.9)
                                .foregroundStyle(Color(red: 50/255, green: 46/255, blue: 62/255))
                            Spacer()
                        }
                        .ignoresSafeArea()
                        
                        VStack {
                            HStack {
                                ProfileImage4(userUrl: selectedFriend.profileImageUrl)
                                VStack (alignment: .leading){
                                    Text("CHATTING WITH")
                                        .font(.system(size: 12))
                                    
                                    Text("\(selectedFriend.firstName.uppercased()) \(selectedFriend.lastName.uppercased())")
                                        .font(.system(size: 20))
                                }
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .opacity(0.5)
                                .offset(y: 5)
                                Spacer()
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                                    .blendMode(.difference)
                                    .padding(.trailing, 25)
                                    .padding(.top, UIScreen.screenHeight * 0.01)
                                    .onTapGesture {
                                        dataController.allSelected = 0
                                        self.friendDetailOpen = false
                                        self.chatViewOpen = false
                                        print("CLEAR TAP MainFriendView 4")
                                    }
                            }
                            .padding(.top, UIScreen.screenHeight * 0.085)
                            .padding(.leading, 25)
                            .onTapGesture {
                                // Call the test print function on tap
                                FroopChatNotificationsManager.shared.printFroopConversationsAndMessages()
                            }
                            Spacer()
                            
                        }
                        //                        .frame(height: 100)
                    }
                    Spacer()
                }
                .ignoresSafeArea()
            }
        }
        .alert(isPresented: $showFriendRequestSentAlert) {
            Alert(title: Text("Friend Request Sent"), message: Text("Your friend request has been sent successfully."), dismissButton: .default(Text("OK")))
            
        }
        .alert(isPresented: $unFriendAlert) {
            Alert(
                title: Text("Remove \(selectedFriend.firstName) \(selectedFriend.lastName) from your Friend List"),
                message: Text("Removing friends from your Friends List will make it harder to view Froops where you both have attended.  Are you sure?"),
                primaryButton: .default(Text("Yes, I am sure.")) {
                    // Wrap asynchronous call in a Task
                    Task {
                        do {
                            try await unFriend(currentUserID: uid, friendUserID: selectedFriend.froopUserID)
                        } catch {
                            print("Failed to unfriend: \(error)")
                        }
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    func isFriendshipRequested(toUserID: String) -> Bool {
        let invitedFriends: [String] = UserDefaults.standard.array(forKey: "invitedFriends") as? [String] ?? []
        return invitedFriends.contains(toUserID)
    }
    
    func formatDateToTimeZone(passedDate: Date, timeZone: TimeZone) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM d, h:mm a"
        dateFormatter.timeZone = timeZone
        return dateFormatter.string(from: passedDate)
    }
    
    func formatDateToTimeZone(passedDate: Date, timeZoneIdentifier: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        
        if let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            formatter.timeZone = timeZone
        } else {
            print("Invalid time zone identifier")
            // Handle the case when the time zone identifier is invalid
            // For example, you might want to use the current time zone
            formatter.timeZone = TimeZone.current
        }
        
        return formatter.string(from: passedDate)
    }
    
    private func makePhoneCall(phoneNumber: String) {
        guard let phoneCallURL = URL(string: "tel://\(phoneNumber)") else { return }
        let application:UIApplication = UIApplication.shared
        if (application.canOpenURL(phoneCallURL)) {
            application.open(phoneCallURL, options: [:], completionHandler: nil)
        }
    }
    
    private func sendTextMessage(phoneNumber: String) {
        guard let smsURL = URL(string: "sms:\(phoneNumber)") else { return }
        UIApplication.shared.open(smsURL)
    }
    
    func sendFriendRequest(fromUserID: String, toUserID: String, friendRequest: FriendInviteData, timestamp: Date, completion: @escaping (Result<String, Error>) -> Void) {
        let friendRequestRef = db.collection("friendRequests").document()
        let documentID = friendRequestRef.documentID
        
        let friendRequest = FriendInviteData(dictionary: [
            "toUserID": toUserID,
            "fromUserID": fromUserID,
            "documentID": documentID,
            "status": "pending",
            "timestamp": timestamp
        ])
        
        friendRequestRef.setData(friendRequest.dictionary) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // Update invitedFriends array in UserDefaults
                var invitedFriends: [String] = UserDefaults.standard.array(forKey: "invitedFriends") as? [String] ?? []
                if !invitedFriends.contains(toUserID) {
                    invitedFriends.append(toUserID)
                    UserDefaults.standard.set(invitedFriends, forKey: "invitedFriends")
                }
                
                // Add friend request to user's friend request list
                let uidRef = db.collection("users").document(fromUserID)
                uidRef.updateData(["friendRequests": FieldValue.arrayUnion([friendRequestRef.documentID])])
                
                // Send push notification to recipient
                let senderName = "\(MyData.shared.firstName) \(MyData.shared.lastName)"
                let message = "\(senderName) sent you a friend request."
                let recipientID = friendRequest.toUserID
                NotificationsManager.sendPushNotification(to: recipientID, title: "Friend Request", body: message, data: ["message": "Hello, you have a friend request from: \(MyData.shared.firstName)!"])
                
                completion(.success(friendRequestRef.documentID))
                self.showFriendRequestSentAlert = true
            }
        }
    }
    
    
    
    func unFriend(currentUserID: String, friendUserID: String) async throws {
        // References to both users' friendList documents
        let currentUserFriendListRef = db.collection("users").document(currentUserID).collection("friends").document("friendList")
        let friendUserFriendListRef = db.collection("users").document(friendUserID).collection("friends").document("friendList")
        
        // Perform the updates in a batch to ensure both operations either succeed or fail together
        let batch = db.batch()
        
        // Remove the friend's UID from the current user's friendList
        batch.updateData(["friendUIDs": FieldValue.arrayRemove([friendUserID])], forDocument: currentUserFriendListRef)
        
        // Remove the current user's UID from the friend's friendList
        batch.updateData(["friendUIDs": FieldValue.arrayRemove([currentUserID])], forDocument: friendUserFriendListRef)
        
        // Commit the batch
        try await batch.commit()
        
        print("Successfully unfriended.")
    }
}

struct ProfileImage: View {
    
    var progress: CGFloat
    var headerHeight: CGFloat
    @Binding var selectedFriend: UserData
    
    var body: some View {
        GeometryReader {
            let rect = $0.frame(in: .global)
            let halfScaledHeight = (rect.height * 1) * 0.15
            let halfScaledWidth = (rect.width * 0.4) * 0.5
            let midY = rect.midY - rect.height / 2
            let midX = rect.midX - rect.width / 2
            let bottomPadding: CGFloat = 0
            let leadingPadding: CGFloat = 0
            let minimumHeaderHeight = 50
            let minimumHeaderWidth = 50
            let resizedOffsetY = (midY - (CGFloat(minimumHeaderHeight) - halfScaledHeight - bottomPadding))
            let resizedOffsetX = (midX - (CGFloat(minimumHeaderWidth) - halfScaledWidth - leadingPadding))
            ZStack {
                Circle()
                    .frame(width: (rect.width + 2) * 1, height: (rect.height + 2) * 1)
                    .foregroundStyle(.white)
                    .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.2), radius: 7, x: 0, y: -7)
                    .scaleEffect(1 - (progress * 0.6), anchor: .leading)
                    .offset(x: -resizedOffsetX * progress, y: -resizedOffsetY * progress)
                
                KFImage(URL(string: selectedFriend.profileImageUrl))
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: rect.width * 1, height: rect.height * 1)
                    .scaleEffect(1 - (progress * 0.6), anchor: .leading)
                    .offset(x: -resizedOffsetX * progress, y: -resizedOffsetY * progress)
            }
        }
        .frame(width: headerHeight * 0.35, height: headerHeight * 0.35)
    }
}

struct ProfileImage2: View {
    @ObservedObject var chatManager = GlobalChatNotificationsManager.shared
    
    var body: some View {
        KFImage(URL(string: chatManager.otherUserProfileImageUrl))
            .resizable()
            .scaledToFill()
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .frame(width: 50, height: 50)
    }
}



struct ProfileImage3: View {
    @ObservedObject var chatManager = GlobalChatNotificationsManager.shared
    @Binding var selectedFriend: UserData
    
    var body: some View {
        KFImage(URL(string: chatManager.otherUserProfileImageUrl))
            .resizable()
            .scaledToFill()
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .frame(width: 50, height: 50)
    }
}

struct ProfileImage4: View {
//    @ObservedObject var chatManager = GlobalChatNotificationsManager.shared
    let userUrl: String
    
    var body: some View {
        KFImage(URL(string: userUrl))
            .resizable()
            .scaledToFill()
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .frame(width: 50, height: 50)
    }
}
