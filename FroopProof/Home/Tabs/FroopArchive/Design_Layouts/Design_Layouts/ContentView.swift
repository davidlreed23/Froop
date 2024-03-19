//
//  ContentView.swift
//  Design_Layouts
//
//  Created by David Reed on 6/11/23.
//

import SwiftUI
import UIKit
import Combine
import Foundation
import MapKit


struct ContentView: View {
    @ObservedObject var mapManager = MapManager.shared
    @State private var isMapDraggable = true
    @State private var mapSelection: String?
    @State var testLocation: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @State var lat: Double = 0.0
    @State var lon: Double = 0.0
    @State var annotationId: Int = 12345

    var body: some View {
        ZStack {
            
            MapReader { reader in
                Map(position: $mapManager.cameraPosition, interactionModes: isMapDraggable ? .all : [], selection: $mapSelection) {
                    ForEach(mapManager.annotations, id: \.id) { participant in
                        Annotation("Example", coordinate: testLocation) {
                            ActiveGuestAnnotation()
                                .id(annotationId)
                        }
                    }
                }
                .onAppear {
                    lat = 37.7749
                    lon = -122.4194
                    testLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
                }
            }
            Button("Move Annotation") {
                mapManager.moveAnnotation()
            }
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
            .padding(.top, 50)
            .padding(.top, 100)
            .padding(.bottom, 100)
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




struct CustomAnnotation: Identifiable {
    let id = UUID() // Conformance to Identifiable
    var coordinate: CLLocationCoordinate2D
}

class MapManager: ObservableObject {
    static let shared = MapManager()
    @Published var annotations: [ActiveGuestAnnotation] = []

    @Published var mapSelection: String?
    @Published var route: MKRoute?
    @Published var routeDestination: MKMapItem?
    @Published var cameraPosition: MapCameraPosition = .region(.myRegion)
    @Published var mapRegion: MKCoordinateRegion = MKCoordinateRegion.myRegion
    @Published var centerLatitude: Double = 0.0
    @Published var centerLongitude: Double = 0.0
    @Published var refreshMap = false
    @Published var routeDisplaying: Bool = false
    @Published var equatableCenter: EquatableCoordinate = EquatableCoordinate(coordinate: MKCoordinateRegion.myRegion.center)
    
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    func moveAnnotation() {
        // Example movement: Adjust the latitude and longitude
        let newCoordinate = CLLocationCoordinate2D(
            latitude: region.center.latitude + 0.01,
            longitude: region.center.longitude + 0.01
        )
        region.center = newCoordinate
    }
}

struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}

extension MKCoordinateRegion {
    static var myRegion: MKCoordinateRegion {
        return .init(center: .myLocation, latitudinalMeters: 1000, longitudinalMeters: 1000)
    }
}

extension CLLocationCoordinate2D {
    static var myLocation: CLLocationCoordinate2D {
        return .init(latitude: 37.7749 , longitude: -122.4194
        )
    }
}

struct EquatableCoordinate: Equatable {
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: EquatableCoordinate, rhs: EquatableCoordinate) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}



struct ActiveGuestAnnotation: Identifiable, View {
    @ObservedObject var mapManager = MapManager.shared
    let id = UUID()
    @State var distance: Double = 0.0
    @State var friendDetailOpen: Bool = false
    private var cancellables = Set<AnyCancellable>()
    
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .frame(width: 52, height: 52)
                    .foregroundColor(.pink)
                    .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255), radius: 5)
                Image(systemName: "target")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
        }
        ZStack {
            Rectangle()
                .frame(width: 100, height: 25)
                .foregroundColor(.white)
                .border(.green, width: 0.5)
                .opacity(0.75)
            Text("ETA \(String(format: "%.0f", 32)) min")
                .font(.system(size: 14))
                .fontWeight(.semibold)
                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                .multilineTextAlignment(.leading)
        }
    }
}



struct Entry {
    let id = UUID()
    
    func getName() -> String {
        return "Entry with id \(id.uuidString)"
    }
}

extension Color {
    
    static let offWhite = Color(red: 225 / 255, green: 225 / 255, blue: 235 / 255 )
    
    func luminosity(_ value: Double) -> Color {
        let uiColor = UIColor(self)
        
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        return Color(UIColor(hue: hue, saturation: saturation, brightness: CGFloat(value), alpha: alpha))
    }
}
