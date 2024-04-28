//
//  MapManager.swift
//  FroopProof
//
//  Created by David Reed on 11/6/23.
//

import SwiftUI
import MapKit
import FirebaseFirestore
import Combine
import Contacts


class MapManager: ObservableObject {
    
    /// Global Properties
    static let shared = MapManager()
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var froopManager = FroopManager.shared
    @Published var mapSelection: String?

    /// Interface Properties
    @Published var tabUp: Bool = true
    @Published var showMenu: Bool = false

    
    /// Map Specific Properties
    @Published var route: MKRoute?
    @Published var routeDestination: MKMapItem?
    @Published var cameraPosition: MapCameraPosition = .region(.myRegion)
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion.myRegion
    @Published var centerLatitude: Double = 0.0
    @Published var centerLongitude: Double = 0.0
    @Published var refreshMap = false
    @Published var routeDisplaying: Bool = false
    @Published var equatableCenter: EquatableCoordinate = EquatableCoordinate(coordinate: MKCoordinateRegion.myRegion.center) 

    /// Pin and Annotation Properties
    @Published var makeNewPin: Bool = false
    @Published var newPinCreation: Bool = false
    @Published var newPassivePinCreation: Bool = false
    @Published var froopPins: [FroopDropPin] = []
    @Published var newPin: FroopDropPin = FroopDropPin()
    @Published var froopDropPin: FroopDropPin = FroopDropPin()
    @Published var onSelected: Bool = false
    @Published var showSavePinView: Bool = false
    @Published var showSavePassivePinView: Bool = false

    @Published var showPinDetailsView: Bool = false
    @Published var showPassivePinDetailsView: Bool = false
    @Published var pinEnlarge: Bool = false
    @Published var createdPinDetail: FroopDropPin = FroopDropPin()
    
    /// Diagnostic Properties
    @Published var tapLatitude: Double = 0.0
    @Published var tapLongitude: Double = 0.0
    @Published var tapLatitudeDelta: Double = 0.0
    @Published var tapLongitudeDelta: Double = 0.0
    @Published var mapPositionX: Double = 0.0
    @Published var mapPositionY: Double = 0.0
    
    /// Other Properties
    let colorLookup: [Color: UIColor] = [
        .pink: UIColor.systemPink,
        .black: UIColor(red: 50/255, green: 46/255, blue: 62/255, alpha: 1.0),
        .blue: UIColor.blue,
        .green: UIColor.green,
        .yellow: UIColor.yellow,
        .red: UIColor.red,
        .orange: UIColor.orange,
        .purple: UIColor.purple
    ]
    
    let wazeDeepLink = "https://waze.com/ul" // Update this with the specific location if needed
    
    func createNewPassiveDropPin() {
        if let currentLocation = froopManager.selectedFroopHistory.froop.froopLocationCoordinate {
            // Calculate the new latitude 100 meters to the north
            let metersNorth = 100.0
            let degreeDistance = metersNorth / 111000 // degrees per meter
            
            let newLatitude = currentLocation.latitude + degreeDistance
            let newCoordinate = CLLocationCoordinate2D(latitude: newLatitude, longitude: currentLocation.longitude)
            
            MapManager.shared.froopDropPin = FroopDropPin(coordinate: newCoordinate, title: "Tap On Map", subtitle: "To Place", pinImage: "mappin.circle.fill")
        }
        makeNewPin = true
    }
    
    func createNewDropPin() {
        if let currentLocation = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopLocationCoordinate {
            // Calculate the new latitude 100 meters to the north
            let metersNorth = 100.0
            let degreeDistance = metersNorth / 111000 // degrees per meter
            
            let newLatitude = currentLocation.latitude + degreeDistance
            let newCoordinate = CLLocationCoordinate2D(latitude: newLatitude, longitude: currentLocation.longitude)
            
            MapManager.shared.froopDropPin = FroopDropPin(coordinate: newCoordinate, title: "Tap On Map", subtitle: "To Place", pinImage: "mappin.circle.fill")
        }
        makeNewPin = true
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
    
    func openPassiveWaze() {
        // Retrieve the name and address
        
        let latitude: Double = froopManager.selectedFroopHistory.froop.froopLocationCoordinate?.latitude ?? 0.0
        let longitude: Double = froopManager.selectedFroopHistory.froop.froopLocationCoordinate?.longitude ?? 0.0
        
        // Check if Waze is installed
        if UIApplication.shared.canOpenURL(URL(string: "waze://")!) {
            // Waze is installed. Launch Waze and start navigation
            let urlStr = String(format: "waze://?ll=%f,%f&navigate=yes", latitude, longitude)
            UIApplication.shared.open(URL(string: urlStr)!)
        } else {
            // Waze is not installed. Launch AppStore to install Waze app
            UIApplication.shared.open(URL(string: "http://itunes.apple.com/us/app/id323229106")!)
        }
    }
    
    func openWaze() {
        // Retrieve the name and address
        
        let latitude: Double = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopLocationCoordinate?.latitude ?? 0.0
        let longitude: Double = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopLocationCoordinate?.longitude ?? 0.0
        
        // Check if Waze is installed
        if UIApplication.shared.canOpenURL(URL(string: "waze://")!) {
            // Waze is installed. Launch Waze and start navigation
            let urlStr = String(format: "waze://?ll=%f,%f&navigate=yes", latitude, longitude)
            UIApplication.shared.open(URL(string: urlStr)!)
        } else {
            // Waze is not installed. Launch AppStore to install Waze app
            UIApplication.shared.open(URL(string: "http://itunes.apple.com/us/app/id323229106")!)
        }
    }
    
    func mapItem(for address: String) async throws -> MKMapItem {
        let geocoder = CLGeocoder()
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(address) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let placemark = placemarks?.first, let location = placemark.location else {
                    continuation.resume(throwing: NSError(domain: "", code: -1, userInfo: nil)) // Consider creating a specific error
                    return
                }
                
                var addressDictionary: [String: Any] = [:]
                if let name = placemark.name { addressDictionary[CNPostalAddressStreetKey] = name }
                if let city = placemark.locality { addressDictionary[CNPostalAddressCityKey] = city }
                if let state = placemark.administrativeArea { addressDictionary[CNPostalAddressStateKey] = state }
                if let zip = placemark.postalCode { addressDictionary[CNPostalAddressPostalCodeKey] = zip }
                if let country = placemark.country { addressDictionary[CNPostalAddressCountryKey] = country }
                if let isoCountryCode = placemark.isoCountryCode { addressDictionary[CNPostalAddressISOCountryCodeKey] = isoCountryCode }
                
                let mkPlacemark = MKPlacemark(coordinate: location.coordinate, addressDictionary: addressDictionary)
                let mapItem = MKMapItem(placemark: mkPlacemark)
                mapItem.name = placemark.name // Optionally set the name based on the placemark details
                
                continuation.resume(returning: mapItem)
            }
        }
    }
    func loadPassiveRouteDestination() async {
        //let address = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopLocationsubtitle
        let coordinate = froopManager.selectedFroopHistory.froop.froopLocationCoordinate ?? CLLocationCoordinate2D()
        do {
            let placemark = MKPlacemark(coordinate: coordinate)
            DispatchQueue.main.async {
                self.routeDestination = MKMapItem(placemark: placemark)
            }
        }
    }
    
    func loadRouteDestination() async {
        //let address = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopLocationsubtitle
        let coordinate = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopLocationCoordinate ?? CLLocationCoordinate2D()
        do {
            let placemark = MKPlacemark(coordinate: coordinate)
            DispatchQueue.main.async {
                self.routeDestination = MKMapItem(placemark: placemark)
            }
        }
    }
    
    func updatePassiveFroopDropPin() {
        // Ensure the user ID and Froop ID are available
        let userId = froopManager.selectedFroopHistory.host.froopUserID
        let froopId = froopManager.selectedFroopHistory.froop.froopId

        // Reference to the specific froopPin document in Firestore
        let froopPinRef = db.collection("users").document(userId)
            .collection("myFroops").document(froopId)
            .collection("froopPins").document(froopDropPin.id.uuidString)
        
        // Update only the messageBody field
        froopPinRef.updateData(["messageBody": froopDropPin.messageBody]) { error in
            if let error = error {
                // Handle any errors here
                print("🚫Error updating FroopDropPin messageBody: \(error.localizedDescription)")
            } else {
                // Update successful
                print("FroopDropPin messageBody updated successfully")
            }
        }
    }
    
    func updateFroopDropPin() {
        // Ensure the user ID and Froop ID are available
        let userId = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.froopUserID ?? ""
        let froopId = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopId ?? ""

        // Reference to the specific froopPin document in Firestore
        let froopPinRef = db.collection("users").document(userId)
            .collection("myFroops").document(froopId)
            .collection("froopPins").document(froopDropPin.id.uuidString)
        
        // Update only the messageBody field
        froopPinRef.updateData(["messageBody": froopDropPin.messageBody]) { error in
            if let error = error {
                // Handle any errors here
                print("🚫Error updating FroopDropPin messageBody: \(error.localizedDescription)")
            } else {
                // Update successful
                print("FroopDropPin messageBody updated successfully")
            }
        }
    }
    
    func savePassiveFroopDropPin() {
        newPinCreation = false
        // Ensure the user ID and Froop ID are available
        let userId = froopManager.selectedFroopHistory.host.froopUserID
        let froopId = froopManager.selectedFroopHistory.froop.froopId
        froopDropPin.coordinate = froopDropPin.coordinate
        // Reference to the froopPins collection in Firestore
        let froopPinsRef = db.collection("users").document(userId)
            .collection("myFroops").document(froopId)
            .collection("froopPins")
        
        // Convert FroopDropPin to a dictionary
        let pinData = froopDropPin.dictionary
        
        // Save the pin data to Firestore
        froopPinsRef.document(froopDropPin.id.uuidString).setData(pinData) { error in
            if let error = error {
                // Handle any errors here
                print("🚫Error saving FroopDropPin: \(error.localizedDescription)")
            } else {
                // Data saved successfully
                print("FroopDropPin saved successfully")
            }
        }
    }
    
    func saveFroopDropPin() {
        newPinCreation = false
        // Ensure the user ID and Froop ID are available
        let userId = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.froopUserID ?? ""
        let froopId = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopId ?? ""
        froopDropPin.coordinate = froopDropPin.coordinate
        // Reference to the froopPins collection in Firestore
        let froopPinsRef = db.collection("users").document(userId)
            .collection("myFroops").document(froopId)
            .collection("froopPins")
        
        // Convert FroopDropPin to a dictionary
        let pinData = froopDropPin.dictionary
        
        // Save the pin data to Firestore
        froopPinsRef.document(froopDropPin.id.uuidString).setData(pinData) { error in
            if let error = error {
                // Handle any errors here
                print("🚫Error saving FroopDropPin: \(error.localizedDescription)")
            } else {
                // Data saved successfully
                print("FroopDropPin saved successfully")
            }
        }
    }
    
    func deletePassiveFroopDropPin(pinId: String) {
        let userId = froopManager.selectedFroopHistory.host.froopUserID
        let froopId = froopManager.selectedFroopHistory.froop.froopId
        showPinDetailsView = false
        let froopPinsRef = db.collection("users").document(userId)
            .collection("myFroops").document(froopId)
            .collection("froopPins")

        froopPinsRef.document(pinId).delete() { error in
            if let error = error {
                print("🚫Error removing document: \(error)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    func deleteFroopDropPin(pinId: String) {
        let userId = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.froopUserID ?? ""
        let froopId = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopId ?? ""
        showPinDetailsView = false
        let froopPinsRef = db.collection("users").document(userId)
            .collection("myFroops").document(froopId)
            .collection("froopPins")

        froopPinsRef.document(pinId).delete() { error in
            if let error = error {
                print("🚫Error removing document: \(error)")
            } else {
                print("Document successfully removed!")
            }
        }
    }
    
    func startListeningForPassiveFroopPins() {
        // Check if the index is within bounds and the array is not empty

        let userId = froopManager.selectedFroopHistory.host.froopUserID
        let froopId = froopManager.selectedFroopHistory.froop.froopId

        let froopPinsRef = db.collection("users").document(userId)
                             .collection("myFroops").document(froopId)
                             .collection("froopPins")

        froopPinsRef.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
//                print("No documents in 'froopPins' or error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            self.froopPins = documents.map { queryDocumentSnapshot -> FroopDropPin in
                let data = queryDocumentSnapshot.data()
//                print("Document data: \(data)") // Print the data for each document

                let title = data["title"] as? String ?? ""
                let subtitle = data["subtitle"] as? String ?? ""
                let colorHex = data["color"] as? String ?? "#000000FF"
                let color = UIColor(hex: colorHex) ?? UIColor(red: 50/255, green: 46/255, blue: 62/255, alpha: 1.0)
                let pinImage = data["pinImage"] as? String ?? "mappin"
                let creatorUID = data["creatorUID"] as? String ?? ""
                let latitude = data["latitude"] as? Double ?? 0
                let longitude = data["longitude"] as? Double ?? 0
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                let documentID = UUID(uuidString: queryDocumentSnapshot.documentID) ?? UUID()
                return FroopDropPin(
                    id: documentID,
                    coordinate: coordinate,
                    title: title,
                    subtitle: subtitle,
                    color: color,
                    creatorUID: creatorUID,
                    pinImage: pinImage
                )
            }
        }
    }

    func startListeningForFroopPins() {
        // Check if the index is within bounds and the array is not empty
        guard appStateManager.aFHI >= 0,
              appStateManager.aFHI < appStateManager.currentFilteredFroopHistory.count else {
//            print("Current Froop History is empty or index is out of bounds")
            return
        }

        let userId = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.host.froopUserID ?? ""
        let froopId = appStateManager.currentFilteredFroopHistory[safe: appStateManager.aFHI]?.froop.froopId ?? ""

        let froopPinsRef = db.collection("users").document(userId)
                             .collection("myFroops").document(froopId)
                             .collection("froopPins")

        froopPinsRef.addSnapshotListener { snapshot, error in
            guard let documents = snapshot?.documents else {
//                print("No documents in 'froopPins' or error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            self.froopPins = documents.map { queryDocumentSnapshot -> FroopDropPin in
                let data = queryDocumentSnapshot.data()
//                print("Document data: \(data)") // Print the data for each document

                let title = data["title"] as? String ?? ""
                let subtitle = data["subtitle"] as? String ?? ""
                let colorHex = data["color"] as? String ?? "#000000FF"
                let color = UIColor(hex: colorHex) ?? UIColor(red: 50/255, green: 46/255, blue: 62/255, alpha: 1.0)
                let pinImage = data["pinImage"] as? String ?? "mappin"
                let creatorUID = data["creatorUID"] as? String ?? ""
                let latitude = data["latitude"] as? Double ?? 0
                let longitude = data["longitude"] as? Double ?? 0
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

                let documentID = UUID(uuidString: queryDocumentSnapshot.documentID) ?? UUID()
                return FroopDropPin(
                    id: documentID,
                    coordinate: coordinate,
                    title: title,
                    subtitle: subtitle,
                    color: color,
                    creatorUID: creatorUID, 
                    pinImage: pinImage
                )
            }
        }
    }
    
    
    /// Utility Methods
    
    func convertToUIColor(_ color: Color) -> UIColor {
        return UIColor(color)
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
    
    func convertPointToCoordinate(point: CGPoint, mapCenter: CLLocationCoordinate2D, mapSpan: MKCoordinateSpan, screenSize: CGSize) -> CLLocationCoordinate2D {
        // Determine scale
        let tapLatitudeDelta = mapSpan.latitudeDelta / screenSize.height
        let tapLongitudeDelta = mapSpan.longitudeDelta / screenSize.width
        
        // Calculate offset from center in screen points
        let centerScreenPoint = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        let screenOffsetX = point.x - centerScreenPoint.x
        let screenOffsetY = point.y - centerScreenPoint.y
        
        // Convert screen offset to geographical offset
        let latitudeOffset = screenOffsetY * tapLatitudeDelta
        let longitudeOffset = screenOffsetX * tapLongitudeDelta
        
        // Apply offset to map center
        let newLatitude = mapCenter.latitude - latitudeOffset // Subtract because screen Y increases downwards
        let newLongitude = mapCenter.longitude + longitudeOffset
        
        return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
    }
    
    func updatePinLocation(to newCoordinate: CLLocationCoordinate2D) {
        froopDropPin.coordinate = newCoordinate
    }
}


extension UIColor {
    convenience init(_ color: Color) {
        let components = color.cgColor?.components ?? [0, 0, 0, 0]
        self.init(red: components[0], green: components[1], blue: components[2], alpha: components[3])
    }
}

extension UIColor {
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat
        let scanner = Scanner(string: hex)
        var hexNumber: UInt64 = 0

        if scanner.scanHexInt64(&hexNumber) {
            r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
            g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
            b = CGFloat(hexNumber & 0x0000ff) / 255
            a = 1.0 // Assuming your hex color is not transparent and does not include alpha value

            self.init(red: r, green: g, blue: b, alpha: a)
        } else {
            return nil
        }
    }
}

struct EquatableRegion: Equatable {
    let region: MKCoordinateRegion
    
    static func == (lhs: EquatableRegion, rhs: EquatableRegion) -> Bool {
        return lhs.region.center.latitude == rhs.region.center.latitude &&
        lhs.region.center.longitude == rhs.region.center.longitude &&
        lhs.region.span.latitudeDelta == rhs.region.span.latitudeDelta &&
        lhs.region.span.longitudeDelta == rhs.region.span.longitudeDelta
    }
}


extension MapManager {
    func zoomToLocation(_ coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        self.cameraPosition = .region(region)
    }
}
