//
//  RideRequestView.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import MapKit

struct FroopLocationConfirmationView: View {
    
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationManager = LocationManager.shared
    // @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var appStateManager = AppStateManager.shared

    @ObservedObject var froopData = FroopData.shared
    @ObservedObject var myData = MyData.shared
    @EnvironmentObject var viewModel: LocationSearchViewModel
    @State var selectedRideType: RideType = .setFroopLocation
    @ObservedObject var changeView: ChangeView

    
    var body: some View {
        ZStack {
            
            VStack(alignment: .leading, spacing: 24) {
                TripLocationsView(froopData: froopData)
                    .padding(.horizontal)
                    .padding(.bottom, 85)
            }
            VStack {
                Spacer()
                VStack {
                    Capsule()
                        .foregroundColor(.white)
                        .frame(width: 48, height: 6)
                        .padding(8)
                    
                    Spacer()
                    VStack {
                        Button(action: {
                            PrintControl.shared.printLocationServices("froopData.id: \(froopData.id)")
                            PrintControl.shared.printLocationServices("self.froopData.id: \(self.froopData.id)")
                            PrintControl.shared.printLocationServices(froopData.froopLocationtitle)
                            PrintControl.shared.printLocationServices(froopData.froopLocationsubtitle)
                            PrintControl.shared.printLocationServices("Froop Location Coordinate - Latitude: \(froopData.froopLocationCoordinate.latitude), Longitude: \(froopData.froopLocationCoordinate.longitude)")
                            
                            PrintControl.shared.printLocationServices(froopData.froopName)
                            PrintControl.shared.printLocationServices(froopData.froopType.description)
                            if appStateManager.froopIsEditing {
                                changeView.pageNumber = changeView.showSummary
                            } else {
                                changeView.pageNumber += 1
                            }
                            
                        }) {
                            Text("Confirm!")
                                .font(.system(size: 28, weight: .thin))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(width: 225, height: 45)
                        .border(Color.primary, width: 1)
                        .padding(.bottom, UIScreen.screenHeight * 0.08)
                        .onAppear {
                            LocationManager.shared.stopUpdating()
                        }
                    }
                    
                }
                .frame(height: UIScreen.screenHeight * 0.45)
            }
            .opacity(1)
            .frame(height: UIScreen.screenHeight * 0.45)
        }
    }
}




