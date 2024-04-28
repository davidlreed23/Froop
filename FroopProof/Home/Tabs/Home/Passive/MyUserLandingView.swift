//
//  MyUserPublicView.swift
//  FroopProof
//
//  Created by David Reed on 8/9/23.
//

import SwiftUI

struct MyUserPublicView: View {
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var froopManager = FroopManager.shared
    var size: CGSize
    var safeArea: EdgeInsets
    @State var friendsView: Bool = false
    @State var showNotificationSheet: Bool = false
    @Binding var friendDetailOpen: Bool
    //    @State private var offsetY: CGFloat = 0
    
    
    
    var body: some View {
        ZStack {
            Color.white
            ScrollViewReader { scrollProxy in
                ZStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 5) {
                            MyProfileHeaderView(size: size, safeArea: safeArea, showNotificationSheet: $showNotificationSheet)
                                .zIndex(1000)
                                .ignoresSafeArea(.all)
                            MyFroopsView(friendDetailOpen: $friendDetailOpen)
                                .transition(.opacity)
                        }
                        .id("SCROLLVIEW")
                        .background {
                            ScrollDetector { offset in
                                DispatchQueue.main.async {
                                    dataController.offsetY = -offset
                                }
                            } onDraggingEnd: { offset, velocity in
                                /// Resetting to Intial State, if not Completely Scrolled
                                let headerHeight = (size.height * 0.3) + safeArea.top
                                let minimumHeaderHeight = (size.height * 0.3) + safeArea.top
                                
                                let targetEnd = offset + (velocity * 45)
                                if targetEnd < (headerHeight - minimumHeaderHeight) && targetEnd > 0 {
                                    withAnimation(.interactiveSpring(response: 0.55, dampingFraction: 0.65, blendDuration: 0.65)) {
                                        scrollProxy.scrollTo("SCROLLVIEW", anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                    .sheet(isPresented: $showNotificationSheet, content: {
                        NotificationsSheetView()
                    })
                }
            }
        }
        .opacity(appStateManager.appState == .passive || !appStateManager.appStateToggle ? 1.0 : 0.0)
    }
}




