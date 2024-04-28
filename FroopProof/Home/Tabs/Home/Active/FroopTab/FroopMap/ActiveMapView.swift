//
//  ActiveMapView.swift
//  FroopProof
//
//  Created by David Reed on 10/30/23.
//

import SwiftUI
import MapKit
import Kingfisher
import CoreLocation


struct ActiveMapView: View {
    /// GLOBAL PROPERTIES
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var froopManager = FroopManager.shared
    @ObservedObject var mapManager = MapManager.shared
    @ObservedObject var froopHistory: FroopHistory
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var annotationManager = AnnotationManager.shared
    @ObservedObject var timerServices = TimerServices.shared
    
    /// TRACKING PROPERTIESS
    @State private var mapRegion: MKCoordinateRegion = MKCoordinateRegion.myRegion
    @State var tapLatitude: Double = 0.0
    @State var tapLongitude: Double = 0.0
    @State var mapPositionX: Double = 0.0
    @State var mapPositionY: Double = 0.0
    @State private var selectedMarkerId: String?
    @State var distance: Double = 0.0
    @State private var userLocation: CLLocationCoordinate2D?
    @State var offset: CGFloat = 0
    @State var lastStoredOffset: CGFloat = 0
    @GestureState var gesturOffSet: CGFloat = 0
    @State private var equatableCenter: EquatableCoordinate = EquatableCoordinate(coordinate: MKCoordinateRegion.myRegion.center)
    
    /// STATE PROPERTIES
    @State var friendDetailOpen: Bool = false
    @State private var isMapDraggable = true
    @State private var mapSelection: String?
    private var shouldShowAnnotations: Bool {
        mapManager.tapLatitudeDelta < 0.008
    }
    
    
    /// Route Properties
    @State private var routeDisplaying: Bool = false
    @State private var route: MKRoute?
    @State private var routeDestination: MKMapItem?
    @State var makeNewPin: Bool = false
    
    /// LEGACY
    @State private var cameraPosition: MapCameraPosition = .region(.myRegion)
    @State var tapLatitudeDelta: Double = 0.0
    @State var tapLongitudeDelta: Double = 0.0
    @State private var centerLatitude: Double = 0.0
    @State private var centerLongitude: Double = 0.0
    @State var showMenu: Bool = false
    @State var newPin: FroopDropPin = FroopDropPin()
    
    /// OTHER PROPERTIES
    @Namespace private var locationSpace
    @Binding var globalChat: Bool
//    @Binding var selectedUser: UserData?
    @State private var rerun = UUID()
    
    init(froopHistory: FroopHistory, globalChat: Binding <Bool>) {
        UITabBar.appearance().isHidden = true
        self.froopHistory = FroopHistory(
            froop: Froop(dictionary: [:]),
            host: UserData(),
            invitedFriends: [],
            confirmedFriends: [],
            declinedFriends: [],
            pendingFriends: [],
            images: [],
            videos: [],
            froopGroupConversationAndMessages: ConversationAndMessages(conversation: Conversation(), messages: [], participants: []), froopMediaData: FroopMediaData(
                froopImages: [],
                froopDisplayImages: [],
                froopThumbnailImages: [],
                froopIntroVideo: "",
                froopIntroVideoThumbnail: "",
                froopVideos: [],
                froopVideoThumbnails: []
            )
        )
        _globalChat = globalChat
    }
    
    var body: some View {
        
        if appStateManager.aFHI >= 0 && appStateManager.aFHI < appStateManager.currentFilteredFroopHistory.count {
            
            MapReader { reader in
                Map(position: $mapManager.cameraPosition, interactionModes: isMapDraggable ? .all : [], selection: $mapSelection) {
                    
                    if let route {
                        MapPolyline(route.polyline)
                            .stroke(Color(red: 255/255, green: 49/255, blue: 97/255), lineWidth: 5)
                    }
                    
                    if MapManager.shared.newPinCreation {
                        Annotation("by: \(MyData.shared.firstName) \(MyData.shared.lastName)", coordinate: MapManager.shared.froopDropPin.coordinate) {
                            NewFroopPin(froopDropPin: MapManager.shared.froopDropPin)
                        }
                    }
                    if shouldShowAnnotations {
                        ForEach(MapManager.shared.froopPins, id: \.id) { pin in
                            Annotation("", coordinate: pin.coordinate) {
                                CreatedFroopPin(froopDropPin: pin)
                            }
                            .tag(pin.id)
                        }
                    }
                    
                    ForEach(annotationManager.guestAnnotations, id: \.froopUserID) { participant in
                        Annotation(participant.firstName, coordinate: participant.coordinate) {
                            ActiveGuestAnnotation(guest: participant, globalChat: $globalChat)
                                .id(participant.froopUserID)
                        }
                    }
                    
                    
                    // MARK: Froop Annotation
                    Marker(appStateManager.currentFilteredFroopHistory[appStateManager.aFHI].froop.froopLocationtitle, coordinate: appStateManager.currentFilteredFroopHistory[appStateManager.aFHI].froop.froopLocationCoordinate ?? CLLocationCoordinate2D())
                        .tint(Color(red: 249/255, green: 0/255, blue: 98/255))
                        .tag(appStateManager.currentFilteredFroopHistory[appStateManager.aFHI].froop.froopId)
                }
                .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight)
                .opacity(appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopId == nil ? 0.5 : 1)
                .onChange(of: mapSelection) { oldValue, newValue in
                    if let selectedId = newValue, selectedId != selectedMarkerId {
                        selectedMarkerId = selectedId
                        if let selectedPin = MapManager.shared.froopPins.first(where: { $0.id.uuidString == selectedId }) {
                            annotationManager.zoomToLocation(selectedPin.coordinate)
                        }
                    }
                }
                .mapStyle(.standard(elevation: .automatic))
                .onMapCameraChange { mapCameraUpdateContext in
                    mapManager.tapLatitude = mapCameraUpdateContext.camera.centerCoordinate.latitude
                    mapManager.tapLongitude = mapCameraUpdateContext.camera.centerCoordinate.longitude
                    mapManager.tapLatitudeDelta = mapCameraUpdateContext.region.span.latitudeDelta
                    mapManager.tapLongitudeDelta = mapCameraUpdateContext.region.span.longitudeDelta
                    print("\(mapCameraUpdateContext.camera.centerCoordinate)")
                    print("\(mapCameraUpdateContext.region)")
                }
                .onTapGesture(perform: { screenCoord in
                    annotationManager.trackingUser = false
                    if MapManager.shared.newPinCreation {
                        let pinLocation = reader.convert(screenCoord, from: .local)
                        tapLatitude = pinLocation?.latitude ?? 0.0
                        tapLongitude = pinLocation?.longitude ?? 0.0
                        MapManager.shared.froopDropPin.coordinate = pinLocation ?? CLLocationCoordinate2D()
                        print(pinLocation as Any)
                    }
                })
                .onChange(of: equatableCenter) {
                    MapManager.shared.centerLatitude = equatableCenter.coordinate.latitude
                    MapManager.shared.centerLongitude = equatableCenter.coordinate.longitude
                }
                .task {
                    await MapManager.shared.loadRouteDestination()
                }
                .onAppear {
                    timerServices.shouldUpdateAnnotations = true
                    if let center = MapManager.shared.cameraPosition.region?.center {
                        MapManager.shared.centerLatitude = center.latitude
                        MapManager.shared.centerLongitude = center.longitude
                    }
                    MapManager.shared.startListeningForFroopPins()
                    
                    let froopLocation = appStateManager.currentFilteredFroopHistory[appStateManager.aFHI].froop.froopLocationCoordinate ?? CLLocationCoordinate2D()
                    let myLocation = MyData.shared.coordinate // Directly accessing the property
                    
                    let midpoint = MapManager.shared.midpointBetween(coordinate1: froopLocation, coordinate2: myLocation)
                    let span = MapManager.shared.spanToInclude(coordinate1: froopLocation, coordinate2: myLocation)
                    let region = MKCoordinateRegion(center: midpoint, span: span)
                    withAnimation(.easeInOut(duration: 1.0)) {
                        MapManager.shared.cameraPosition = .region(region)
                    }
                    
                    Task {
                        await locationManager.startLiveLocationUpdates()
                    }
                    timerServices.startAnnotationTimer()
                    mapSelection = appStateManager.currentFilteredFroopHistory[appStateManager.aFHI].froop.froopId
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        // Ensure user location is available before fetching the route
                        if locationManager.userLocation != nil {
                            fetchRoute()
                        } else {
                            PrintControl.shared.printMap("💥User location is nil, cannot fetch route")
                        }
                    }
                    PrintControl.shared.printMap("🔥 Map On Appear Firing")
                }
                .overlay {
                    HStack {
                        VStack {
                            ZStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(.white)
                                    .background(.ultraThinMaterial)
                                    .clipShape(.rect(cornerRadius: 5))
                                
                                Image(systemName: "location.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                
                            }
                            .padding(.bottom, 5)
                            .onTapGesture {
                                // Safely unwrap the current center of the camera position
                                if let currentCenter = mapManager.cameraPosition.region?.center {
                                    mapManager.centerLatitude = currentCenter.latitude
                                    mapManager.centerLongitude = currentCenter.longitude
                                }
                                
                                // Safely unwrap the froop location and use a default coordinate if nil
                                let froopLocation = appStateManager.currentFilteredFroopHistory[appStateManager.aFHI].froop.froopLocationCoordinate ?? CLLocationCoordinate2D()
                                let myLocation = MyData.shared.coordinate // Assuming this is always valid
                                
                                // Calculate midpoint and span
                                let midpoint = mapManager.midpointBetween(coordinate1: froopLocation, coordinate2: myLocation)
                                let span = mapManager.spanToInclude(coordinate1: froopLocation, coordinate2: myLocation)
                                
                                // Create a new region and update the camera position
                                let region = MKCoordinateRegion(center: midpoint, span: span)
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    mapManager.cameraPosition = .region(region)
                                }
                            }
                            
                            ZStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(.white)
                                    .background(.ultraThinMaterial)
                                    .clipShape(.rect(cornerRadius: 5))
                                
                                Image(systemName: "f.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                
                            }
                            .padding(.bottom, 5)
                            .onTapGesture {
                                annotationManager.trackingUser = false
                                // Safely unwrap the current center of the camera position
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    // Calculate the offset to move the center upwards
                                    let froopLoc = appStateManager.currentFilteredFroopHistory[appStateManager.aFHI].froop.froopLocationCoordinate ?? CLLocationCoordinate2D()
                                    // Adjust the center point upwards
                                    let adjustedCenter = CLLocationCoordinate2D(
                                        latitude: froopLoc.latitude,
                                        longitude: froopLoc.longitude
                                    )
                                    
                                    // Create a new region with the adjusted center
                                    
                                    let adjustedRegion = MKCoordinateRegion(
                                        center: adjustedCenter,
                                        latitudinalMeters: 250,
                                        longitudinalMeters: 250
                                    )
                                    
                                    MapManager.shared.cameraPosition = .region(adjustedRegion)
                                }
                            }
                            
                            ZStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                    .background(Material.ultraThinMaterial)
                                    .clipShape(.rect(cornerRadius: 5))
                                
                                Image(systemName: "person.and.arrow.left.and.arrow.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                
                            }
                            .padding(.bottom, 5)
                            .onTapGesture {
                                withAnimation {
                                    cycleThroughGuestsAndHost()
                                    annotationManager.trackingUser = true
                                }
                            }
                            if mapManager.froopPins.count > 0 {
                                ZStack {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 34))
                                        .foregroundColor(.white)
                                        .background(.ultraThinMaterial)
                                        .clipShape(.rect(cornerRadius: 5))
                                    
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 34))
                                        .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                    
                                    Image(systemName: "arrow.left.and.line.vertical.and.arrow.right")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                                .onTapGesture {
                                    annotationManager.trackingUser = false
                                    cycleThroughPins()
                                }
                            }
                            //                                Text(String(describing: mapManager.tapLatitudeDelta))
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(.top, 115)
                    .padding(.leading, 10)
                }
                .navigationTitle("\(appStateManager.currentFilteredFroopHistory[appStateManager.aFHI].froop.froopName)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .navigationBarItems(
                    leading: Button(action: onAddPinButtonTapped) {
                        HStack(spacing: 15) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 18))
                                .fontWeight(.regular)
                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                .offset(x: 7)
                            Text("ADD PIN")
                                .fontWeight(.semibold)
                                .font(.system(size: 14))
                                .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                        }
                    },
                    trailing: Button(action: onWazeButtonTapped) {
                        Image("wazeLogoRound")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 35, height: 35)
                            .clipShape(Circle())
                    }
                )
                .onDisappear {
                    timerServices.shouldUpdateAnnotations = false
                }
            }
            .onAppear {
                annotationManager.updateAnnotations(with: appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.confirmedFriends ?? [])
            }
        }
    }
    
    func onAddPinButtonTapped() {
        annotationManager.trackingUser = false
        if let newCenter = appStateManager.currentFilteredFroopHistory[appStateManager.aFHI].froop.froopLocationCoordinate {
            let offset = mapRegion.span.latitudeDelta / 20
            let adjustedCenter = CLLocationCoordinate2D(latitude: newCenter.latitude - offset, longitude: newCenter.longitude)
            let adjustedRegion = MKCoordinateRegion(center: adjustedCenter, latitudinalMeters: 250, longitudinalMeters: 250)
            withAnimation(.easeInOut(duration: 1.0)) {
                MapManager.shared.cameraPosition = .region(adjustedRegion)
            }
            createNewDropPin()
            mapManager.showPinDetailsView = false
            MapManager.shared.newPinCreation = true
            MapManager.shared.showSavePinView = true
            MapManager.shared.tabUp = false
            appStateManager.appStateToggle = true
        }
    }
    
    func onWazeButtonTapped() {
        MapManager.shared.openWaze()
    }
    
    func focusOnPin(_ pin: FroopDropPin) {
        let newRegion = MKCoordinateRegion(center: pin.coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        withAnimation {
            mapManager.cameraPosition = .region(newRegion)
        }
    }
    
    func cycleThroughPins() {
        annotationManager.cycleToNextPin()
        guard !MapManager.shared.froopPins.isEmpty else { return }
        
        // Assuming cycleToNextPin() updates currentPinIndex appropriately
        let pin = MapManager.shared.froopPins[annotationManager.currentPinIndex]
        focusOnPin(pin)
    }
    
    func cycleThroughGuestsAndHost() {
        annotationManager.cycleToNextGuest()
        guard !annotationManager.guestAnnotations.isEmpty else { return }
        
        // Assuming cycleToNextGuest() updates currentGuestIndex appropriately
        let nextGuest = annotationManager.guestAnnotations[annotationManager.currentGuestIndex]
        annotationManager.zoomToLocation(nextGuest.coordinate)
    }
    
    func createNewDropPin() {
        if let currentLocation = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopLocationCoordinate {
            // Calculate the new latitude 100 meters to the north
            let metersNorth = 100.0
            let degreeDistance = metersNorth / 111000 // degrees per meter
            
            let newLatitude = currentLocation.latitude + degreeDistance
            let newCoordinate = CLLocationCoordinate2D(latitude: newLatitude, longitude: currentLocation.longitude)
            
            MapManager.shared.froopDropPin = FroopDropPin(coordinate: newCoordinate, title: "", subtitle: "", pinImage: "mappin.circle.fill")
        }
        makeNewPin = true
    }
    
    func updatePinLocation(to newCoordinate: CLLocationCoordinate2D) {
        MapManager.shared.froopDropPin.coordinate = newCoordinate
    }
    
    func fetchRoute() {
        PrintControl.shared.printMap("🔥🚀💥fetchRoute Firling")
        // Assuming you have a source location, if not, you'll need to fetch it
        if let sourceCoordinate = locationManager.userLocation?.coordinate {
            let sourceMapItem = MKMapItem(placemark: MKPlacemark(coordinate: sourceCoordinate))
            PrintControl.shared.printMap("🔥Source location: \(sourceCoordinate.latitude), \(sourceCoordinate.longitude)")
            
            if let destinationCoordinate = MapManager.shared.routeDestination?.placemark.coordinate {
                PrintControl.shared.printMap("🔥Destination location: \(destinationCoordinate.latitude), \(destinationCoordinate.longitude)")
                
                let request = MKDirections.Request()
                request.source = sourceMapItem
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
                
                Task {
                    do {
                        let response = try await MKDirections(request: request).calculate()
                        route = response.routes.first
                        routeDestination = MapManager.shared.routeDestination
                        
                        withAnimation(.snappy) {
                            routeDisplaying = true
                        }
                    } catch {
                        PrintControl.shared.printMap("💥Failed to calculate route: \(error)")
                    }
                }
            } else {
                PrintControl.shared.printMap("💥Destination location not set")
            }
        } else {
            PrintControl.shared.printMap("💥Source location not available")
        }
    }
    
    func midpointBetween(coordinate1: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        let latitude = (coordinate1.latitude + coordinate2.latitude) / 2
        let longitude = (coordinate1.longitude + coordinate2.longitude) / 2
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func spanToInclude(coordinate1: CLLocationCoordinate2D, coordinate2: CLLocationCoordinate2D) -> MKCoordinateSpan {
        let maxLatitude = max(abs(coordinate1.latitude - coordinate2.latitude), abs(coordinate1.longitude - coordinate2.longitude))
        let span = maxLatitude * 1.5 // Adjust the multiplication factor to add padding
        return MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
    }
    
    func latitudeDeltaFromDrag(point: CGPoint, mapCenter: CLLocationCoordinate2D, mapSpan: MKCoordinateSpan, screenSize: CGSize) -> Double {
        let tapLatitudeDelta = mapSpan.latitudeDelta / screenSize.height
        let centerScreenPoint = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        let screenOffsetY = point.y - centerScreenPoint.y
        let latitudeOffset = screenOffsetY * tapLatitudeDelta
        return latitudeOffset
    }
    
}

extension View {
    func getRect()-> CGRect {
        return UIScreen.main.bounds
    }
    func safeArea()->UIEdgeInsets {
        let null = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return null
        }
        guard let safeArea = screen.windows.first?.safeAreaInsets else {
            return null
        }
        return safeArea
    }
}



///OLDER CLASSES

class MovableAnnotationView: MKAnnotationView {
    var newCenter: CGPoint?
}

protocol MovableAnnotation: AnyObject {
    var coordinate: CLLocationCoordinate2D { get set }
    var title: String? { get set }
    var guest: UserData { get set }
}

class GuestAnnotation: NSObject, MKAnnotation, MovableAnnotation {
    var guest: UserData
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    
    init(guest: UserData) {
        self.guest = guest
        self.coordinate = guest.coordinate
        self.title = "\(guest.firstName) \(guest.lastName)"
        super.init()
    }
}

class PhoneNumberButton: UIButton {
    var phoneNumber: String?
}

class AnnotationModel: ObservableObject {
    @Published var annotation: FroopDropPin?
}

struct EquatableCoordinate: Equatable {
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: EquatableCoordinate, rhs: EquatableCoordinate) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}



