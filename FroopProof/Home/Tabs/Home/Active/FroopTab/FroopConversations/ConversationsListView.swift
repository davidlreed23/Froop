////
////  ConversationsListView.swift
////  FroopProof
////
////  Created by David Reed on 11/12/23.
////
//
//import SwiftUI
//
//struct ConversationsListView: View {
//    @ObservedObject var notificationsManager = NotificationsManager.shared
//    @State var userData: UserData = UserData()
//    @Binding var globalChat: Bool
//    // Extracting conversation titles and IDs
//    var conversations: [SimpleConversation] {
//        notificationsManager.conversationsAndMessages.map { conversationAndMessages in
//            SimpleConversation(id: conversationAndMessages.conversation.id, title: "Conversation with \(conversationAndMessages.conversation)") // Modify this to extract meaningful titles
//        }
//    }
//
//    var body: some View {
//        NavigationView {
//            List(conversations, id: \.id) { conversation in
//                NavigationLink(destination: ChatView(selectedFriend: $userData, chatPartnerUID: conversation.id)) {
//                    Text(conversation.title)
//                }
//            }
//            .navigationBarTitle("Conversations")
//        }
//    }
//}
//
//
