//
//  FroopMessagesView.swift
//  FroopProof
//
//  Created by David Reed on 5/8/23.
//

import SwiftUI
import Photos
import FirebaseStorage
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Kingfisher
import SwiftUIBlurView

struct FroopGlobalMessagesView: View {
    @ObservedObject var chatManager = GlobalChatNotificationsManager.shared
    @ObservedObject var notificationsManager = NotificationsManager.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var locationManager = LocationManager.shared
    @State var bindingUserData: UserData = UserData()
    @State var chatViewOpen: Bool = false
    @State var selectedConversationAndMessages: ConversationAndMessages = ConversationAndMessages(conversation: Conversation(), messages: [], participants: [])
    @State var selectedFriend: UserData = UserData()
    @State var conversationId: String = ""
    @State var updateView: Bool = false
    
    var sortedConversations: [ConversationAndMessages] {
        notificationsManager.conversationsAndMessages.sorted { conversation1, conversation2 in
            guard let lastMessage1 = conversation1.messages.last,
                  let lastMessage2 = conversation2.messages.last else {
                return false
            }
            return lastMessage1.timestamp > lastMessage2.timestamp
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(sortedConversations, id: \.id) { conversationAndMessages in
                            GlobalChatCardView(conversationAndMessages: conversationAndMessages, chatViewOpen: $chatViewOpen, selectedFriend: $selectedFriend)
                                .onTapGesture {
                                    conversationId = conversationAndMessages.conversation.id
                                    self.chatViewOpen = true // Assuming you want to open the chat view here
                                }
                                .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255)
                                    .opacity(0.2), radius: 7, x: 7, y: 7)
                                .shadow(color: Color.white.opacity(0.7), radius: 7, x: -4, y: -4)
                        }
                    }
                    .padding(.top, 100)
                }
            }
            VStack {
                Rectangle()
                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .ignoresSafeArea()
                    .frame(height: 100)
                Spacer()
            }
            
            VStack {
                ZStack {
                    HStack {
                        Text("CURRENT")
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(0.15)
                            .frame(alignment: .trailing)
                            .offset(x: 10)
                        Spacer()
                            .frame(width: 90)
                        Text("MESSAGES")
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(0.15)
                            .frame(alignment: .leading)
                            .padding(.leading, 10)
                    }
                    .padding(.horizontal)
                    .offset(y: 15)
                    HStack {
                        Spacer()
                        KFImage(URL(string: MyData.shared.profileImageUrl))
                            .resizable()
                            .scaledToFill()
                            .frame(width: 75, height: 75)
                            .clipShape(.circle)
                          
                        Spacer()
                    }
                }
                .padding(.top, 35)
                Spacer()
            }
            
            VStack {
                HStack (alignment: .center){
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.trailing, 5)
                    Text("BACK")
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .onTapGesture {
                            NotificationsManager.shared.openGlobalChat.toggle()
                        }
                    Spacer()
                }
                .padding(.top, UIScreen.screenHeight * 0.01)
                .padding(.leading, 10)
                .frame(alignment: .trailing)
                Spacer()
            }
            
        }
        .background(.white)
        .onChange(of: notificationsManager.conversationsAndMessages) { oldValue, newValue in
                updateView.toggle()
                print("🆘 \(updateView)")
        }
        
        .blurredSheet(.init(.ultraThinMaterial), show: $chatViewOpen) {
            chatViewOpen = false
        } content: {
            ZStack {
                
                VStack {
                    ChatView(selectedFriend: $selectedFriend, conversationId: $conversationId) // Pass a binding to the state variable
                        .padding(.top, UIScreen.screenHeight / 15)
                        .ignoresSafeArea()
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
                                    Text("CHATTING WITH \(notificationsManager.totalUnreadMessages)")
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
                                    .padding(.trailing, 40)
                                    .padding(.top, UIScreen.screenHeight * 0.005)
                                    .onTapGesture {
                                        self.chatViewOpen = false
                                    }
                            }
                            .padding(.top, UIScreen.screenHeight * 0.085)
                            .padding(.leading, 25)
                            .onTapGesture {
                                // Call the test print function on tap
//                                chatManager.printGlobalConversationsAndMessages()
                            }
                            Spacer()
                            
                        }
                        //                        .frame(height: 100)
                    }
                    Spacer()
                }
                .ignoresSafeArea()

                
                VStack {
                    HStack {
                        Spacer()
                       

                    }
                    .frame(alignment: .trailing)
                    Spacer()
                }
                .ignoresSafeArea(.keyboard)
            }
        }
    }
}

