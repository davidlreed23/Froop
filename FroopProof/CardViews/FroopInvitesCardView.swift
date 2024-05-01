//
//  FroopCardView.swift
//  FroopProof
//
//  Created by David Reed on 2/6/23.
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

struct FroopInvitesCardView: View {
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    // @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var friendViewController = FriendViewController.shared
    @ObservedObject var myData = MyData.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    
    @Binding var openFroop: Bool
    @State var froopStartTime: Date? = Date()
    @State private var dataLoaded = false
    @State var hostData: UserData = UserData()
    @State var invitedFriends: [UserData] = []
    @State var confirmedFriends: [UserData] = []
    @State var declinedFriends: [UserData] = []
    @State var pendingFriends: [UserData] = []
    @State private var showAlert = false

    
    let visibleFriendsLimit = 8
    @State private var formattedDateString: String = ""
    let froopHostAndFriends: FroopHistory

    
    init(openFroop: Binding<Bool>, froopHostAndFriends: FroopHistory, invitedFriends: [UserData]) {
        self._openFroop = openFroop
        self.timeZoneManager = TimeZoneManager()
        self.froopHostAndFriends = froopHostAndFriends
        self.invitedFriends = invitedFriends
    }
    
    var body: some View {
        
        ZStack (alignment: .top){
            RoundedRectangle(cornerRadius: 10)
                .frame(height: 210)
                .foregroundColor(.white)
                .padding(.leading, 10)
                .padding(.trailing, 10)
                .padding(.top, 10)
                .onTapGesture {
                    froopManager.selectedFroopUUID = froopHostAndFriends.froop.froopId
                    froopManager.selectedFroopHistory.froop = froopHostAndFriends.froop
//                    froopManager.selectedHost = hostData
                }
                
            VStack (alignment: .leading) {
                HStack (alignment: .center){
                    HostProfilePhotoView(imageUrl: froopHostAndFriends.froop.froopHostPic)
                        .scaledToFit()
                        .frame(width: 65, height: 35)
                        .padding(.leading, 5)
                      
                    VStack (alignment: .leading){
                        HStack {
                            Text(froopHostAndFriends.froop.froopName)
                                .font(.system(size: 16))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Text(froopHostAndFriends.textForStatus())
                                .font(.system(size: 14))
                                .fontWeight(.semibold)
                                .foregroundColor(froopHostAndFriends.colorForStatus())
                                .multilineTextAlignment(.leading)
                                .padding(.trailing, 15)
                        }
                        .offset(y: -10)
                        
                        HStack {
                            Text("Host:")
                                .font(.system(size: 14))
                                .fontWeight(.light)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .multilineTextAlignment(.leading)
                            
                            Text(froopHostAndFriends.host.firstName)
                                .font(.system(size: 14))
                                .fontWeight(.light)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .multilineTextAlignment(.leading)
                            
                            Text(froopHostAndFriends.host.lastName)
                                .font(.system(size: 14))
                                .fontWeight(.light)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .multilineTextAlignment(.leading)
                                .offset(x: -5)
                        }
                        .offset(y: -5)
                    }
                    .offset(y: 6)
                }
                .padding(.top, 10)
                .padding(.bottom, 5)
                .padding(.leading, 10)
                
                Divider()
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                    .padding(1)
                    .padding(1)
                
                
                HStack {
                    Spacer()
                    
                    let uid = FirebaseServices.shared.uid
                    
                    Button(action: {
                        LocationManager.shared.requestAlwaysAuthorization()
                        FroopDataController.shared.moveFroopInvitation(uid: uid, froopId: froopHostAndFriends.froop.froopId, froopHost: froopHostAndFriends.froop.froopHost, decision: "accept")
//                        appStateManager.setupListener() {_ in
//                            print("Accepted")
//                        }
                         
                        //selectedTab = 1
                        createCalendarEvent()
                    }) {
                        ZStack {
                            Rectangle()
                                .border(Color(red: 50/255, green: 46/255, blue: 62/255), width: 0.25)
                                .foregroundColor(.clear)
                                .frame(width: 150, height: 40)
                            Text("Accept")
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .font(.system(size: 18))
                                .fontWeight(.light)
                        }
                    }
                    .buttonStyle(FroopButtonStyle())
                    
                    Button(action: {
                        FroopDataController.shared.moveFroopInvitation(uid: uid, froopId: froopHostAndFriends.froop.froopId, froopHost: froopHostAndFriends.froop.froopHost, decision: "decline")
                    }) {
                        ZStack {
                            Rectangle()
                                .border(Color(red: 50/255, green: 46/255, blue: 62/255), width: 0.25)
                                .foregroundColor(.clear)
                                .frame(width: 150, height: 40)
                            Text("Decline")
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .font(.system(size: 18))
                                .fontWeight(.light)
                        }
                    }
                    .buttonStyle(FroopButtonStyle())
                    
                    Spacer()
                }
                
                
                Divider()
                    .padding(.leading, 15)
                    .padding(.trailing, 15)
                    .padding(1)
                    .padding(1)
                
                VStack (alignment: .leading) {
                    HStack {
                        Image(systemName: "clock")
                            .frame(width: 30, height: 30)
                            .scaledToFill()
                            .font(.system(size: 18))
                            .fontWeight(.light)
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                        Text(formattedDateString)
                            .font(.system(size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                        Spacer()
                    }
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .frame(width: 30, height: 30)
                            .scaledToFill()
                            .font(.system(size: 18))
                            .fontWeight(.light)
                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                        VStack (alignment: .leading){
                            
                            Text(froopHostAndFriends.froop.froopLocationtitle)
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            Text(froopHostAndFriends.froop.froopLocationsubtitle)
                                .font(.system(size: 14))
                                .fontWeight(.light)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .lineLimit(2)
                                .padding(.trailing, 25)
                        }
                        Spacer()
                    }
                }
                .padding(.leading, 5)

            }
            .onAppear {
                timeZoneManager.convertUTCToCurrent(date: froopHostAndFriends.froop.froopStartTime, currentTZ: TimeZone.current.identifier) { convertedDate in
                    formattedDateString = timeZoneManager.formatDate(passedDate: convertedDate)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Calendar Update"), message: Text("This Froop has been added to your calendar."), dismissButton: .default(Text("OK")))
            }
        }
    }
    

    
    func printFroop () {
        print(froopHostAndFriends.froop)
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

    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        let eventStore = EKEventStore()
        
        eventStore.requestFullAccessToEvents { (granted, error) in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func createCalendarEvent() {
        let eventStore = EKEventStore()

        requestCalendarAccess { granted in
            if granted {
                let event = EKEvent(eventStore: eventStore)
                event.title = froopManager.selectedFroopHistory.froop.froopName
                event.startDate = froopManager.selectedFroopHistory.froop.froopStartTime
                event.endDate = froopManager.selectedFroopHistory.froop.froopEndTime
                
                // Construct the URL string using your app's URL scheme
                let urlString = "froopproof://event?id=\(froopManager.selectedFroopHistory.froop.froopId)"
                
                // Adding a URL to the event notes
                event.notes = """
                \(froopManager.selectedFroopHistory.froop.froopLocationtitle) at \(froopManager.selectedFroopHistory.froop.froopLocationsubtitle)
                For more details, open in Froop: \(urlString)
                """
                
                event.calendar = eventStore.defaultCalendarForNewEvents

                do {
                    try eventStore.save(event, span: .thisEvent)
                    print("Event saved successfully")
                    showAlert = true
                } catch {
                    PrintControl.shared.printErrorMessages("Error saving event: \(error.localizedDescription)")
                }
            } else {
                PrintControl.shared.printErrorMessages("Calendar access not granted")
            }
        }
    }

}




