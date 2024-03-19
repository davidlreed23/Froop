////
////  MapContainerView.swift
////  FroopProof
////
////  Created by David Reed on 12/12/23.
////
//
//import SwiftUI
//import MapKit
//import Kingfisher
//import CoreLocation
//
//
//struct MapContainerView: View {
//    @ObservedObject var mapManager = MapManager.shared
//    @ObservedObject var appStateManager = AppStateManager.shared
//    @ObservedObject var locationManager = LocationManager.shared
//    @State var tapLatitude: Double = 0.0
//    @State var tapLongitude: Double = 0.0
//    @Binding var globalChat: Bool
//
//    var body: some View {
//        MapReader { reader in
//
//            Map(position: $mapManager.cameraPosition, interactionModes: .all, selection: .constant(nil)) {
//                /// FROOP DESTINATION MARKER
//                Marker(appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopLocationtitle , coordinate: appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopLocationCoordinate ?? CLLocationCoordinate2D())
//                    .tint(Color(red: 249/255, green: 0/255, blue: 98/255))
//                    .tag(appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopId )
//                
//                if mapManager.route != nil {
//                    MapPolyline(mapManager.route?.polyline ?? MKPolyline())
//                        .stroke(Color(red: 255/255, green: 49/255, blue: 97/255), lineWidth: 5)
//                }
//
//                
//                /// NEW PIN ANNOTATION CUSTOMIZE BEFORE SAVING
//                if MapManager.shared.newPinCreation {
//                    Annotation("by: \(MyData.shared.firstName) \(MyData.shared.lastName)", coordinate: MapManager.shared.froopDropPin.coordinate) {
//                        NewFroopPin(froopDropPin: MapManager.shared.froopDropPin)
//                    }
//                }
//                
//                /// USER CREATED PINS
//                ForEach(MapManager.shared.froopPins, id: \.id) { pin in
//                    Annotation(pin.title, coordinate: pin.coordinate) {
//                        CreatedFroopPin(froopDropPin: pin)
//                    }
//                    .tag(pin.id)
//                }
//                
//                /// CONFIRMED FRIEND ANNOTATIONS - SHOWS ATTENDING FRIENDS ON MAP
//                ForEach(appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.confirmedFriends.filter { $0.froopUserID != appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.froopUserID } , id: \.self) { guest in
//                    Annotation(guest.firstName, coordinate: guest.coordinate) {
//                        ActiveGuestAnnotation(globalChat: $globalChat, guest: guest)
//                    }
//                    .tag(guest.froopUserID)
//                }
//                
//                /// HOST ANNOTATION - SIMILAR TO FRIEND ANNOTATIONS
//                if appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.froopUserID == FirebaseServices.shared.uid {
//                    Annotation(appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.firstName , coordinate: appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.coordinate ) {
//                        ActiveGuestAnnotation(globalChat: $globalChat, guest: appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host )
//                    }
//                    UserAnnotation()
//                } else {
//                    Annotation("\(String(describing: appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.firstName)) \(String(describing: appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.lastName))", coordinate: appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.coordinate ) {
//                        ZStack {
//                            Circle()
//                                .frame(width: 52, height: 52)
//                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
//                                .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255), radius: 5)
//                            KFImage(URL(string: appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.profileImageUrl ))
//                                .resizable()
//                                .frame(width: 50, height: 50)
//                                .clipShape(Circle())
//                        }
//                    }
//                    .tag(appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.froopUserID )
//                }
//            }
//            .onAppear {
//                if let center = MapManager.shared.cameraPosition.region?.center {
//                    MapManager.shared.centerLatitude = center.latitude
//                    MapManager.shared.centerLongitude = center.longitude
//                }
//                MapManager.shared.startListeningForFroopPins()
//                
//                let froopLocation = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopLocationCoordinate ?? CLLocationCoordinate2D()
//                let myLocation = MyData.shared.coordinate // Directly accessing the property
//                
//                let midpoint = MapManager.shared.midpointBetween(coordinate1: froopLocation, coordinate2: myLocation)
//                let span = MapManager.shared.spanToInclude(coordinate1: froopLocation, coordinate2: myLocation)
//                let region = MKCoordinateRegion(center: midpoint, span: span)
//                withAnimation(.easeInOut(duration: 1.0)) {
//                    MapManager.shared.cameraPosition = .region(region)
//                }
//                
//                locationManager.startUpdating()
//                
//                mapManager.mapSelection = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopId
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                    // Ensure user location is available before fetching the route
//                    if locationManager.userLocation != nil {
//                        mapManager.fetchRoute()
//                    } else {
//                        PrintControl.shared.printMap("💥User location is nil, cannot fetch route")
//                    }
//                }
//                PrintControl.shared.printMap("🔥 Map On Appear Firing")
//            }
//            .onTapGesture(perform: { screenCoord in
//                let pinLocation = reader.convert(screenCoord, from: .local)
//                tapLatitude = pinLocation?.latitude ?? 0.0
//                tapLongitude = pinLocation?.longitude ?? 0.0
//                mapManager.froopDropPin.coordinate = pinLocation ?? CLLocationCoordinate2D()
//            })
//        }
//    }
//}
