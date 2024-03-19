//
//  FroopLocationView.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import SwiftUIBlurView
import Combine

struct FroopLocationView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var printControl = PrintControl.shared
    // @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var locationManager = LocationManager.shared
    @ObservedObject var locationServices = LocationServices.shared
    @ObservedObject var changeView: ChangeView
    @ObservedObject var froopData: FroopData
    
    @State private var showLocationSearchView = false
    @State private var mapState = MapViewState.searchingForLocation
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @Binding var homeViewModel: HomeViewModel
    @ObservedObject var myData = MyData.shared
    @State var showRec = false
    @State private var delayCompleted = false

    
    var body: some View {
        
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                FroopMapViewRepresentable(froopData: froopData, mapState: $mapState)
                    .blur(radius: mapState == .searchingForLocation ? 10 : 0)
                    .onAppear {
                        LocationManager.shared.startUpdating()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                           // LocationManager.shared.stopUpdating()
                        }
                    }
                Rectangle()
                    .fill(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .opacity(showRec ? 0 : 0.6)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .onTapGesture {
                        UIApplication.shared.endEditing()
                    }
                if mapState == .searchingForLocation {
                    
                    LocationSearchView(mapState: $mapState, showLocationSearchView: $showLocationSearchView, delayCompleted: $delayCompleted, showRec: $showRec, froopData: froopData)
            
                } else if mapState == .noInput {
                   Text("")
                        .padding(.top, 120)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                mapState = .searchingForLocation
                                
                            }
                        }
                }
                
            }
            .ignoresSafeArea(.keyboard)
            
            
            MapViewActionButton(mapState: $mapState)
                .offset(y: -800)
                .padding(.leading)
                .padding(.top, 4)
            
            if (delayCompleted == true && mapState == .locationSelected || mapState == .polylineAdded) {
                
                BlurView(style: .light)
                    .frame(height: UIScreen.screenHeight * 0.45)
                    .edgesIgnoringSafeArea(.bottom)
                    .opacity(delayCompleted ? 1 : 0)
                    .border(Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.5), width: 0.5)
                    .shadow(color: Color(red: 50/255, green: 46/255, blue: 62/255).opacity(0.3), radius: 20)


                FroopLocationConfirmationView(froopData: froopData, changeView: changeView)
                    .transition(.move(edge: .bottom))
                    .opacity(delayCompleted ? 1 : 0)

            }

            
            
        }
        .background(Color.clear)
        .environmentObject(locationViewModel)
        .environmentObject(froopData)
        .environmentObject(homeViewModel)
//        .edgesIgnoringSafeArea(.bottom)
//        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        
    }
    
    func calculateOffset(for screenSize: ScreenSizeCategory) -> CGFloat {
        switch screenSize {
            case .size430x932:
                return -0 // This size works
            case .size428x926:
                return -0 // This size works
            case .size414x896:
                return -35 // This size works
            case .size393x852:
                return -35 // Replace with the appropriate value for this screen size
            case .size390x844:
                return -35 // Replace with the appropriate value for this screen size
            case .size375x812:
                return -35 // Replace with the appropriate value for this screen size
            default:
                return 0
        }
    }
}




