//
//  NewFroopSummary.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import SwiftUIBlurView
import Kingfisher
import Firebase
import FirebaseAuth
import FirebaseFirestore


struct FroopSummaryView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var friendViewController = FriendViewController.shared
    @ObservedObject var manager = PayWallManager.shared
    @ObservedObject var locationManager = LocationManager.shared

    // @ObservedObject var froopDataListener = FroopDataListener.shared
    var db = FirebaseServices.shared.db
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var timeZoneManager: TimeZoneManager = TimeZoneManager()
    @ObservedObject var myData = MyData.shared
    @ObservedObject var froopData: FroopData
    @ObservedObject var changeView = ChangeView.shared
    @State var froopHolder: Froop = Froop(dictionary: [:])
    @State var selectedFroopType: FroopType?
    @State var confirmedFriends: [UserData] = []
    @ObservedObject var froopTypeStore = FroopTypeStore()
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 5
    var PCtotalPages = 6
    @State var myTimeZone: TimeZone = TimeZone.current
    @State private var formattedDateString: String = ""
    @State private var showMap = false
    @State private var hide: Bool = false
    @State private var animate = false
    @State private var addressAtMyLocation: Bool = true
    
    var body: some View {
        
        ZStack {
            //MARK:  Background Layout Objects
            //
            Rectangle()
                .foregroundColor(Color(red: 240/255, green: 240/255, blue: 240/255))
            
                .background(.ultraThinMaterial)
                .padding(.top)
                .ignoresSafeArea()
                .onAppear {
                    if froopData.template {
                        froopData.froopHost = FirebaseServices.shared.uid
                        froopData.froopId = String(describing: UUID())
                    }
                    appStateManager.froopIsEditing = true
                    froopHolder = froopData.toFroop()
                    fetchFriendsData(from: froopData.froopInvitedFriends) { fetchedFriends in
                        self.confirmedFriends = fetchedFriends
                        // Additional actions if needed
                    }
                    
                }
            
            GeometryReader { geometry in
                // MARK: BANNER
                if myData.premiumAccount {
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(.white)
                                .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.2), radius: 7, x: 7, y: 7)
                                .shadow(color: Color.white.opacity(0.7), radius: 7, x: -4, y: -4)
                                .frame(width: geometry.size.width * 0.9, height: 75)
                                .padding(.top, 15)
                                .padding(.horizontal, geometry.size.width * 0.05) // Use relative padding
                            
                            VStack (spacing: 10) {
                                HStack {
                                    Text("PREMIUM")
                                        .font(.system(.title2, design: .default)) // Use dynamic type
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .foregroundStyle(Color(red: 249/255, green: 0/255, blue: 96/255))
                                        .padding(.horizontal, geometry.size.width * 0.1)
                                        .offset(y: 5)
                                    
                                    Spacer()
                                    Text("Status")
                                        .font(.system(size: 14))
                                        .fontWeight(.regular)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .foregroundStyle(Color(red: 249/255, green: 0/255, blue: 96/255))
                                        .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                        .offset(y: 5)
                                    
                                    
                                }
                                
                                HStack {
                                    Text("ACCOUNT")
                                        .font(.system(.title2, design: .default)) // Use dynamic type
                                        .fontWeight(.bold)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.5)
                                        .foregroundStyle(.white)
                                        .padding(.trailing, UIScreen.screenWidth * 0.1)
                                        .padding(.leading, UIScreen.screenWidth * 0.1)
                                    Spacer()
                                    Text("ACTIVE")
                                        .font(.system(size: 20))
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .foregroundStyle(Color(red: 249/255, green: 0/255, blue: 96/255))
                                        .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                }
                            }
                            .padding(.top, 10)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundStyle(Color(red: 249/255, green: 0/255, blue: 96/255))
                                    .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.2), radius: 7, x: 7, y: 7)
                                    .shadow(color: Color.white.opacity(0.7), radius: 7, x: -4, y: -4)
                                    .frame(width: geometry.size.width * 0.9, height: 75)
                                    .padding(.top, 15)
                                    .padding(.horizontal, geometry.size.width * 0.05) // Use relative padding
                                
                                VStack (spacing: 10) {
                                    HStack {
                                        Text("PREMIUM")
                                            .font(.system(.title2, design: .default)) // Use dynamic type
                                            .fontWeight(.bold)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                            .offset(y: 5)
                                        Spacer()
                                        Text("Status")
                                            .font(.system(size: 14))
                                            .fontWeight(.regular)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                            .offset(y: 5)
                                        
                                    }
                                    
                                    HStack {
                                        Text("ACCOUNT")
                                            .font(.system(.title2, design: .default)) // Use dynamic type
                                            .fontWeight(.bold)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.5)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                        
                                        Spacer()
                                        Text("ACTIVE")
                                            .font(.system(size: 20))
                                            .fontWeight(.bold)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                    }
                                }
                                .padding(.top, 10)
                            }
                            .mask(
                                ZStack {
                                    SlantedSwipeInObject(width: geometry.size.width, height: 90)
                                        .offset(x: animate ? -geometry.size.width * 1.4 : 0, y: 0)
                                }
                            )
                        }
                        .onAppear {
                            withAnimation(.interpolatingSpring(stiffness: 100, damping: 15).delay(0.5)) {
                                animate = true
                            }
                        }
                        
                        Spacer()
                        Rectangle()
                            .foregroundStyle(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .opacity(0.7)
                            .frame(height: 125)
                            .ignoresSafeArea()
                    }
                    
                    
                    .padding(.top, UIScreen.screenHeight * 0.025 + 75)
                    .ignoresSafeArea()
                } else {
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundStyle(.white)
                                .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.2), radius: 7, x: 7, y: 7)
                                .shadow(color: Color.white.opacity(0.7), radius: 7, x: -4, y: -4)
                                .frame(width: geometry.size.width * 0.9, height: 75)
                                .padding(.top, 15)
                                .padding(.horizontal, geometry.size.width * 0.05) // Use relative padding
                            
                            VStack (spacing: 10) {
                                HStack {
                                    Text("GET PREMIUM")
                                        .font(.system(.title2, design: .default)) // Use dynamic type
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .foregroundStyle(Color(red: 249/255, green: 0/255, blue: 96/255))
                                        .padding(.horizontal, geometry.size.width * 0.1)
                                        .offset(y: 5)
                                    
                                    Spacer()
                                    Text("FOR ONLY")
                                        .font(.system(size: 14))
                                        .fontWeight(.regular)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .foregroundStyle(Color(red: 249/255, green: 0/255, blue: 96/255))
                                        .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                        .offset(y: 5)
                                    
                                    
                                }
                                
                                HStack {
                                    Text("Add Video To All Your Froops!")
                                        .font(.system(size: 14))
                                        .fontWeight(.regular)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.5)
                                        .foregroundStyle(.white)
                                        .padding(.trailing, UIScreen.screenWidth * 0.1)
                                        .padding(.leading, UIScreen.screenWidth * 0.1)
                                    Spacer()
                                    Text("$49.99 / YEAR")
                                        .font(.system(size: 20))
                                        .fontWeight(.bold)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .foregroundStyle(Color(red: 249/255, green: 0/255, blue: 96/255))
                                        .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                }
                            }
                            .padding(.top, 10)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundStyle(Color(red: 249/255, green: 0/255, blue: 96/255))
                                    .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.2), radius: 7, x: 7, y: 7)
                                    .shadow(color: Color.white.opacity(0.7), radius: 7, x: -4, y: -4)
                                    .frame(width: geometry.size.width * 0.9, height: 75)
                                    .padding(.top, 15)
                                    .padding(.horizontal, geometry.size.width * 0.05) // Use relative padding
                                
                                VStack (spacing: 10) {
                                    HStack {
                                        Text("GET PREMIUM")
                                            .font(.system(.title2, design: .default)) // Use dynamic type
                                            .fontWeight(.bold)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                            .offset(y: 5)
                                        Spacer()
                                        Text("FOR ONLY")
                                            .font(.system(size: 14))
                                            .fontWeight(.regular)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                            .offset(y: 5)
                                        
                                        
                                    }
                                    
                                    HStack {
                                        Text("Add Video To All Your Froops!")
                                            .font(.system(size: 14))
                                            .fontWeight(.regular)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.5)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                        
                                        Spacer()
                                        Text("$49.99 / YEAR")
                                            .font(.system(size: 20))
                                            .fontWeight(.bold)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, geometry.size.width * 0.1) // Use relative padding
                                        
                                        
                                        
                                    }
                                }
                                .padding(.top, 10)
                            }
                            .mask(
                                ZStack {
                                    SlantedSwipeInObject(width: geometry.size.width, height: 90)
                                        .offset(x: animate ? -geometry.size.width * 1.4 : 0, y: 0)
                                }
                            )
                        }
                        .onAppear {
                            withAnimation(.interpolatingSpring(stiffness: 100, damping: 15).delay(0.5)) {
                                animate = true
                            }
                        }
                        
                        Spacer()
                        Rectangle()
                            .foregroundStyle(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .opacity(0.7)
                            .frame(height: 125)
                            .ignoresSafeArea()
                    }
                    .padding(.top, UIScreen.screenHeight * 0.025 + 75)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            manager.showIAPView.toggle()
                        }
                    }
                }
            }
            
            
            //MARK: Content
            
            VStack (alignment: .center, spacing: 5) {
                //MARK: Froop Content
                HStack {
                    Spacer()
                    VStack (alignment: .center){
                        
                        VStack {
                            Text("Does everything look right?")
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.9))
                            
                            Text("Tap below to make changes.")
                                .font(.system(size: 16))
                                .fontWeight(.regular)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.5))
                            
                            Spacer()
                        }
                        .frame(height: 35)
                    }
                    Spacer()
                }
                
                //MARK: Title
                VStack (alignment: .leading) {
                    
                    Text("FROOP TITLE")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.9))
                        .padding(.leading, 15)
                        .offset(y: 5)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.25), lineWidth: 0.25)
                            )
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                        
                        HStack (spacing: 0 ){
                            Image(systemName: "t.circle")
                                .frame(width: 60, height: 50)
                                .scaledToFill()
                                .font(.system(size: 24))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                .padding(.leading, 25)
                                .frame(alignment: .center)
                            Text("\"\(froopData.froopName)\"")
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .lineLimit(2)
                                .padding(.trailing, 25)
                            Spacer()
                        }
                    }
                }
                .frame(width: UIScreen.screenWidth - 40, height: 75)
                .padding(.top, 15)
                .onTapGesture {
                    changeView.pageNumber = 4
                }
                
                //MARK: Froop Date
                VStack (alignment: .leading) {
                    
                    Text("DATE")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.9))
                        .padding(.leading, 15)
                        .offset(y: 5)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.25), lineWidth: 0.25)
                            )
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                        
                        
                        HStack (spacing: 0 ){
                            Image(systemName: "clock")
                                .frame(width: 60, height: 50)
                                .scaledToFill()
                                .font(.system(size: 24))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                .padding(.leading, 25)
                                .frame(alignment: .center)
                            Text(formatDate(for: froopData.froopStartTime, in: "America/Los_Angeles"))
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .lineLimit(2)
                                .padding(.trailing, 25)
                            Spacer()
                        }
                    }
                }
                .frame(width: UIScreen.screenWidth - 40, height: 75)
                .onTapGesture {
                    changeView.pageNumber = 3
                }
                
                //MARK: Froop Location
                VStack (alignment: .leading) {
                    
                    Text("ADDRESS \(String(describing:addressAtMyLocation))")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.9))
                        .padding(.leading, 15)
                        .offset(y: 5)
                        .onTapGesture {
                            locationManager.startUpdating()
                            addressAtMyLocation.toggle()
                            print("My Current Address - \(String(describing: locationManager.currentAddress))")
                            print("My Current Location - \(String(describing: locationManager.currentLocation))")
                            print("User2DLocation - \(String(describing: locationManager.user2DLocation))")
                            print("myData.coordinate - \(String(describing: myData.coordinate))")
                        }
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .frame(height: 75)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.25), lineWidth: 0.25)
                            )
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                        
                        HStack (spacing: 0 ){
                            Image(systemName: "mappin.and.ellipse")
                                .frame(width: 60, height: 60)
                                .scaledToFill()
                                .font(.system(size: 24))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                .padding(.leading, 25)
                                .frame(alignment: .center)
                            if addressAtMyLocation, let address = locationManager.currentAddress {
                                VStack(alignment: .leading) {
                                    Text("Current Location")
                                        .font(.system(size: 16))
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                        .padding(.trailing, 25)
                                    Text(address)
                                        .font(.system(size: 14))
                                        .fontWeight(.light)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.5)
                                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                        .lineLimit(2)
                                        .padding(.trailing, 25)
                                }
                            } else {
                                VStack (alignment: .leading) {
                                    Text(froopData.froopLocationtitle)
                                        .font(.system(size: 16))
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.5)
                                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                        .padding(.trailing, 25)
                                    Text(froopData.froopLocationsubtitle)
                                        .font(.system(size: 14))
                                        .fontWeight(.light)
                                        .lineLimit(2)
                                        .minimumScaleFactor(0.5)
                                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                        .lineLimit(2)
                                        .padding(.trailing, 25)
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .frame(width: UIScreen.screenWidth - 40, height: 100)
                .onTapGesture {
                    changeView.pageNumber = 2
                }
                
                //MARK: Froop Duration
                VStack (alignment: .leading) {
                    
                    Text("DURATION")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.9))
                        .padding(.leading, 15)
                        .offset(y: 5)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.25), lineWidth: 0.25)
                            )
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                        
                        HStack (spacing: 0 ){
                            Image(systemName: "hourglass.tophalf.filled")
                                .frame(width: 60, height: 50)
                                .scaledToFill()
                                .font(.system(size: 24))
                                .fontWeight(.medium)
                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                .padding(.leading, 25)
                                .frame(alignment: .center)
                            Text("Duration: \(formatDuration(durationInSeconds: froopData.froopDuration))")
                                .font(.system(size: 16))
                                .fontWeight(.medium)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .lineLimit(2)
                                .padding(.trailing, 25)
                            Spacer()
                        }
                    }
                }
                .frame(width: UIScreen.screenWidth - 40, height: 75)
                .onTapGesture {
                    changeView.pageNumber = 3
                }
                
                //MARK: Froop Type
                VStack (alignment: .leading) {
                    
                    Text("TYPE OF FROOP")
                        .font(.system(size: 14))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.9))
                        .padding(.leading, 15)
                        .offset(y: 5)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .foregroundColor(.white)
                            .opacity(0.8)
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.25), lineWidth: 0.25)
                            )
                            .padding(.leading, 15)
                            .padding(.trailing, 15)
                        
                        HStack (spacing: 0 ){
                            if let froopType = FroopTypeStore.shared.froopTypes.first(where: { $0.id == froopData.froopType }) {
                                Image(systemName: froopType.imageName)
                                    .frame(width: 60, height: 50)
                                    .scaledToFill()
                                    .font(.system(size: 24))
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255 ))
                                    .padding(.leading, 25)
                                    .frame(alignment: .center)
                                Text("It's a \(froopType.name)")
                                    .font(.system(size: 16))
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                    .lineLimit(2)
                                    .padding(.trailing, 25)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(width: UIScreen.screenWidth - 40, height: 75)
                .onTapGesture {
                    changeView.pageNumber = 1
                }
                
                Spacer()
                
            }
            .padding(.top, 130)
            
            VStack {
                Spacer()
                //MARK: Save Froop Button
                ZStack {
                    
                    Rectangle()
                        .foregroundColor(.clear)
                        .frame(height: 75)
                        .padding(.leading, 15)
                        .padding(.trailing, 15)
                    Button {
                        Task {
                            do {
                                FroopManager.shared.froopHolder.froopHost = FirebaseServices.shared.uid
                                appStateManager.froopIsEditing = false
                                if LocationManager.shared.locationUpdateTimerOn == true {
                                    TimerServices.shared.shouldCallupdateUserLocationInFirestore = true
                                }
                                if AppStateManager.shared.stateTransitionTimerOn == true {
                                    TimerServices.shared.shouldCallAppStateTransition = true
                                }
                                PrintControl.shared.printFroopCreation("Attempting to Save Froop")
                                froopData.froopHostPic = MyData.shared.profileImageUrl
                                froopData.froopHost = MyData.shared.froopUserID
                                
                                let froopId = try await froopData.saveData()
                                try await withCheckedThrowingContinuation { continuation in
                                    froopData.createInvite(froopId: froopId) { result in
                                        switch result {
                                            case .success(let inviteUrl):
                                                print("Invite URL: \(inviteUrl)")
                                                continuation.resume(returning: ())
                                            case .failure(let error):
                                                continuation.resume(throwing: error)
                                        }
                                    }
                                }
                                changeView.froopAdded = true
                                
                                if ProfileCompletionCurrentPage <= PCtotalPages {
                                    ProfileCompletionCurrentPage = 2
                                    //                                        print(ProfileCompletionCurrentPage)
                                }
                                changeView.showNFWalkthroughScreen = false
                                
                                for friendId in confirmedFriends {
                                    do {
                                        _ = try await FroopDataController.shared.addInvitedFriendstoFroop(invitedFriends: [friendId], instanceFroop: froopHolder)
                                        print("Invitation successfully sent to \(friendId.froopUserID)")
                                    } catch {
                                        print("🚫Error sending invitation to \(friendId.froopUserID): \(error.localizedDescription)")
                                    }
                                }
                                
                                
                                // Schedule the location tracking notification
                                let userNotificationsController = UserNotificationsController()
                                userNotificationsController.scheduleLocationTrackingNotification(froopId: froopData.froopId, froopName: froopData.froopName, froopStartTime: froopData.froopStartTime)
                                
                                // Schedule the Froop reminder notification
                                userNotificationsController.scheduleFroopReminderNotification(froopId: froopData.froopId, froopName: froopData.froopName, froopStartTime: froopData.froopStartTime)
                                //                                    self.appStateManager.setupListener() { _ in }
                                froopData.froopDate = Date()
                                froopData.froopStartTime = Date()
                                froopData.froopCreationTime = Date()
                                froopData.froopDuration = 0
                                froopData.froopInvitedFriends = []
                                froopData.froopEndTime = Date()
                                froopData.froopImages = []
                                froopData.froopDisplayImages = []
                                froopData.froopThumbnailImages = []
                                froopData.froopVideos = []
                                froopData.froopVideoThumbnails = []
                                froopData.froopIntroVideo = ""
                                froopData.froopIntroVideoThumbnail = ""
                                froopData.froopHost = ""
                                froopData.froopHostPic = ""
                                froopData.froopTimeZone = ""
                                froopData.froopMessage = ""
                                froopData.froopList = []
                                froopData.template = false
                                froopData.hidden = []
                                froopData.inviteUrl = ""
                                froopData.videoSubscribed = false
                                
                                appStateManager.selectedTabTwo = 1
                            }
                        }
                    } label: {
                        Text("Save Froop")
                            .font(.system(size: 28, weight: .thin))
                            .foregroundColor(.white).opacity(1)
                            .multilineTextAlignment(.center)
                            .frame(width: 225, height: 45)
                            .border(Color(.white).opacity(1), width: 0.25)
                            .padding(.top)
                    }
                }
            }
            .ignoresSafeArea()
            .padding(.bottom, UIScreen.screenHeight * 0.01)
            .onAppear {
                timeZoneManager.convertUTCToCurrent(date: froopData.froopStartTime, currentTZ: TimeZone.current.identifier) { convertedDate in
                    formattedDateString = timeZoneManager.formatDate(passedDate: convertedDate)
                }
                froopData.froopEndTime = froopData.froopStartTime.addingTimeInterval(TimeInterval(froopData.froopDuration))
                PrintControl.shared.printFroopCreation("Froop End Time:  \(froopData.froopEndTime)")
            }
            
            CustomPayWallView(
                model: $manager.model
            )
            .offset(y: manager.showIAPView ? 0 : UIScreen.main.bounds.height)
            .opacity(manager.showIAPView ? 1 : 0)
            .edgesIgnoringSafeArea(.all)
            .onChange(of: manager.showIAPView) { oldValue, newValue in
                if newValue {
                    Task {
                        do {
                            try await manager.fetchPaywallData()
                        } catch {
                            print(error.localizedDescription)
                            manager.showDefaultView = true
                        }
                    }
                }
            }
        }
    }
    
    
    
    func formatDuration(durationInSeconds: Int) -> String {
        PrintControl.shared.printFroopCreation("-FroopSummaryView: Function: formatDuration is firing!")
        let hours = durationInSeconds / 3600
        let minutes = (durationInSeconds % 3600) / 60
        
        let hourString = hours == 1 ? "h : " : "h : "
        let minuteString = minutes == 1 ? "m" : "m"
        
        return String(format: "%02d\(hourString) %02d\(minuteString)", hours, minutes)
    }
    
    func uploadData(froopData: FroopData) {
        PrintControl.shared.printFroopCreation("-FroopSummaryView: Function: uploadData is firing!")
        
        let uid = FirebaseServices.shared.uid
        db.collection("users").document(uid).collection("myFroops").addDocument(data: froopData.dictionary) { (error) in
            if let error = error {
                PrintControl.shared.printFroopCreation("Error uploading data: \(error)")
            } else {
                PrintControl.shared.printFroopCreation("Data successfully uploaded")
            }
        }
    }
    
    func formatDate(for date: Date, in timeZoneIdentifier: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy h:mm a"
        if let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            formatter.timeZone = timeZone
        }
        return formatter.string(from: date)
    }
    
    func formatTime(creationTime: Date) -> String {
        PrintControl.shared.printFroopCreation("-FroopSummaryView: Function: formatTime is firing!")
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .hour, .day]
        formatter.unitsStyle = .abbreviated
        
        let currentTime = Date()
        let timeSinceCreation = currentTime.timeIntervalSince(creationTime)
        
        let formattedTime = formatter.string(from: timeSinceCreation) ?? ""
        
        return formattedTime
    }
    
    func fetchFriendsData(from friendUIDs: [String], completion: @escaping ([UserData]) -> Void) {
        let usersRef = db.collection("users")
        var friends: [UserData] = []
        
        let group = DispatchGroup()
        
        for friendUID in friendUIDs {
            group.enter()
            
            usersRef.document(friendUID).getDocument { document, error in
                if let document = document, document.exists, let userData = document.data() {
                    let friend = UserData(dictionary: userData)
                    friends.append(friend ?? UserData())
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.confirmedFriends = friends // Assign here, inside the notify closure
            completion(friends)
        }
    }
    
}



struct SlantedSwipeInObject: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: width * 2, y: 0))
            path.addLine(to: CGPoint(x: width * 1.9, y: height)) // Adjust the slant by modifying this multiplier
            path.addLine(to: CGPoint(x: 0, y: height))
            path.closeSubpath()
        }
        .fill(Color.white.opacity(1))
        .frame(width: width, height: height)
    }
}
