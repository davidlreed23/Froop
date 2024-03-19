////
////  ActiveMapView_ref.swift
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
//struct ActiveMapView: View {
//    @ObservedObject var locationManager = LocationManager.shared
//    @ObservedObject var appStateManager = AppStateManager.shared
//    @ObservedObject var mapManager = MapManager.shared
//    @ObservedObject var froopHistory: FroopHistory
//    @Binding var globalChat: Bool
//    @State private var equatableRegion: EquatableRegion?
//    
//    var body: some View {
//        NavigationStack {
//            let sideBarWidth = getRect().width - 90
//
//            if appStateManager.aFHI >= 0 && appStateManager.aFHI < appStateManager.currentFilteredFroopHistory.count {
//                MapContainerView(globalChat: $globalChat)
//                    .onAppear(perform: setupMapView)
//                    .onChange(of: equatableRegion) { oldValue, newValue in
//                        updateRegion(newRegion: newValue ?? EquatableRegion(region: MKCoordinateRegion()))
//                    }
//                    .onChange(of: MapManager.shared.refreshMap) {
//                    }
//                    .onChange(of: mapManager.equatableCenter) {
//                        MapManager.shared.centerLatitude = mapManager.equatableCenter.coordinate.latitude
//                        MapManager.shared.centerLongitude = mapManager.equatableCenter.coordinate.longitude
//                    }
//                    .task {
//                        await MapManager.shared.loadRouteDestination()
//                    }
//                    .overlay(alignment: .topLeading) {
//                        VStack {
//                            Text(String(describing: MapManager.shared.froopPins.count))
//                                .font(.system(size: 24))
//                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
//                                .fontWeight(.bold)
//                            Text(String(describing: mapManager.cameraPosition.region?.span.latitudeDelta))
//                        }
//                        .padding(.leading, 20)
//                        .padding(.top, 20)
//                    }
//                    .onChange(of: equatableRegion) { oldValue, newValue in
//                        if let newRegion = newValue?.region {
//                            mapManager.cameraPosition = .region(newRegion)
//                        }
//                    }
//
//                    .navigationTitle("\(appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopName )")
//                    .navigationBarTitleDisplayMode(.inline)
//                    .toolbarBackground(.visible, for: .navigationBar)
//                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
//                    .navigationBarItems(leading:
//                                            Button(action: {
//                        if let newCenter = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopLocationCoordinate {
//                            // Calculate the offset to move the center upwards
//                            let offset = mapManager.mapRegion.span.latitudeDelta / 20
//                            
//                            // Adjust the center point upwards
//                            let adjustedCenter = CLLocationCoordinate2D(
//                                latitude: newCenter.latitude - offset,
//                                longitude: newCenter.longitude
//                            )
//                            
//                            // Create a new region with the adjusted center
//                            let adjustedRegion = MKCoordinateRegion(
//                                center: adjustedCenter,
//                                latitudinalMeters: 250,
//                                longitudinalMeters: 250
//                            )
//                            
//                            // Update cameraPosition to frame this new region
//                            withAnimation(.easeInOut(duration: 1.0)) {
//                                MapManager.shared.cameraPosition = .region(adjustedRegion)
//                            }
//                            
//                            mapManager.createNewDropPin()
//                            MapManager.shared.newPinCreation = true
//                            MapManager.shared.showSavePinView = true
//                            MapManager.shared.tabUp = false
//                            appStateManager.appStateToggle = true
//                        }
//                    }) {
//                        HStack (spacing: 15) {
//                            Image(systemName: "mappin.and.ellipse")
//                                .font(.system(size: 18))
//                                .fontWeight(.regular)
//                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
//                                .offset(x: 7)
//                            Text("ADD PIN")
//                                .fontWeight(.semibold)
//                                .font(.system(size: 14))
//                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
//                        }
//                    }
//                                        , trailing:
//                                            
//                                            Button(action: {
//                        MapManager.shared.openWaze()
//                    }) {
//                        Image("wazeLogoRound") // This will load the Waze logo from your assets
//                            .resizable()
//                            .scaledToFill()
//                            .frame(width: 35, height: 35) // Adjust size as needed
//                            .clipShape(Circle())
//                    }
//                    )
//            }
//        }
//    }
//    
//    func setupMapView() {
//        // Setup map view and initialize equatableRegion
//        equatableRegion = EquatableRegion(region: mapManager.cameraPosition.region ?? MKCoordinateRegion())
//    }
//    
//    func updateRegion(newRegion: EquatableRegion) {
//        // Handle the region update
//        mapManager.cameraPosition = .region(newRegion.region)
//    }
//    
//    private var addPinButton: some View {
//        Button("ADD PIN", action: createNewDropPin)
//            .buttonStyle(MapActionButtonStyle())
//    }
//    
//    private var openWazeButton: some View {
//        Button(action: mapManager.openWaze) {
//            Image("wazeLogoRound")
//                .resizable()
//                .scaledToFill()
//                .frame(width: 35, height: 35)
//                .clipShape(Circle())
//        }
//    }
//    
//    private func updateRegion(_ newRegion: MKCoordinateRegion) {
//        mapManager.cameraPosition = .region(newRegion)
//    }
//    
//    private func createNewDropPin() {
//        // Your pin creation code here
//    }
//}
//

//
