//
//  DetailsHeaderView.swift
//  Design_Layouts
//
//  Created by David Reed on 6/20/23.
//

import SwiftUI
import SwiftUIBlurView
import Kingfisher
import Firebase
import FirebaseAuth
import FirebaseFirestore
import Foundation
import MapKit
import EventKit
import FirebaseCrashlytics

struct DetailsHeaderView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopManager = FroopManager.shared
    @Binding var templateMade: Bool
    
    var timeUntilStart: String {
        let calendar = Calendar.current
        let now = Date()
        
        if froopManager.selectedFroopHistory.froop.froopStartTime > now {
            let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: froopManager.selectedFroopHistory.froop.froopStartTime)
            
            let days = components.day ?? 0
            let hours = components.hour ?? 0
            let minutes = components.minute ?? 0
            
            var timeUntilStart = "Starts in "
            
            if days > 9 {
                timeUntilStart += "\(days)d : "
            } else if days > 0 && days < 10 {
                timeUntilStart += "0\(days)d : "
            } else {
                timeUntilStart += "00d : "
            }
            
            
            if hours > 9 {
                timeUntilStart += "\(hours)h : "
            } else if hours > 0 && hours < 10 {
                timeUntilStart += "0\(hours)h : "
            } else {
                timeUntilStart += "00h : "
            }
            
            
            if minutes > 9 {
                timeUntilStart += "\(minutes)m"
            } else if minutes > 0 && minutes < 10 {
                timeUntilStart += "0\(minutes)m"
            } else {
                timeUntilStart += "00m"
            }
            
            
            return timeUntilStart.trimmingCharacters(in: .whitespaces)
        } else if froopManager.selectedFroopHistory.froop.froopEndTime < now {
            return "Froop has already started"
        } else {
            return "This Froop occured in the past"
        }
    }
    
    var body: some View {
        ZStack {
            ZStack {
                Rectangle()
                    .frame(height: 200)
                    .foregroundColor(colorScheme == .dark ? Color(red: 50/255, green: 46/255, blue: 62/255) : Color(red: 50/255, green: 46/255, blue: 62/255))
                if FirebaseServices.shared.uid == froopManager.selectedFroopHistory.host.froopUserID {
                    ZStack {
                        VStack {
                            HStack {
                                Spacer()
                                if templateMade {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(red: 50/255, green: 46/255, blue: 62/255))
                                            .frame(width: 70, height: 50)
                                            .shadow(color: Color.white.opacity(0.3), radius: 4, x: 4, y: 4)
                                            .shadow(color: Color(.black).opacity(1), radius: 4, x: -4, y: -4)
                                        VStack {
                                            Text("Made From")
                                                .font(.system(size: 12))
                                                .fontWeight(.light)
                                                .foregroundColor(.white)
                                            Text("Template")
                                                .font(.system(size: 12))
                                                .fontWeight(.light)
                                                .foregroundColor(.white)
                                        }
                                    }
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(red: 50/255, green: 46/255, blue: 62/255))
                                            .frame(width: 70, height: 50)
                                            .shadow(color: Color.white.opacity(0.1), radius: 4, x: 4, y: 4)
                                            .shadow(color: Color(.black).opacity(1), radius: 4, x: -4, y: -4)
                                        VStack {
                                            Text(froopManager.selectedFroopHistory.froop.template ? "" : "Create")
                                                .font(.system(size: 12))
                                                .fontWeight(.light)
                                                .foregroundColor(.white)
                                            Text(froopManager.selectedFroopHistory.froop.template ? "" : "Template")
                                                .font(.system(size: 12))
                                                .fontWeight(.light)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            Spacer()
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 15)
                        .onTapGesture {
                            //                        print("tapped")
                            templateMade = true
                            froopManager.saveFroopAsTemplate(froopId: "froopId") { error in
                                if let error = error {
                                    print("🚫Error copying froop to templates: \(error.localizedDescription)")
                                } else {
                                    print("Froop successfully copied to templates with confirmed friends.")
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                } else {
                    EmptyView()
                        .frame(height: 200)
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    ZStack {
                        Circle()
                            .frame(width: 75)
                            .foregroundColor(colorScheme == .dark ? .white : .white)
                        KFImage(URL(string: froopManager.selectedFroopHistory.host.profileImageUrl))
                            .placeholder {
                                ProgressView()
                            }
                            .resizable()
                            .scaledToFill()
                            .frame(width: 75, height: 75, alignment: .center)
                            .clipShape(Circle())
                    }
                    
                    VStack (alignment: .leading){
                        Text(froopManager.selectedFroopHistory.froop.froopName )
                            .foregroundColor(colorScheme == .dark ? .white: .white)
                            .font(.system(size: 24))
                        Text("Host: \(froopManager.selectedFroopHistory.host.firstName ) \(froopManager.selectedFroopHistory.host.lastName)")
                            .foregroundColor(colorScheme == .dark ? .white: .white)
                            .font(.system(size: 14))
                            .offset(y: 8)
                        Text(timeUntilStart)
                            .font(.system(size: 14))
                            .fontWeight(.regular)
                            .foregroundColor(.white).opacity(0.4)
                            .frame(alignment: .leading)
                            .offset(y: 8)
                        
                    }
                    .offset(y: -5)
                    .padding(.leading, 15)
                    
                    Spacer()
                }
                
            }
            .frame(maxHeight: 200)
            .padding(.bottom, 10)
            .padding(.trailing, 25)
            .padding(.leading, 25)
        }
    }
}


