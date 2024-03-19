//
//  NFWalkthroughScreen.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import iPhoneNumberField
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift



class ChangeView: ObservableObject {
    static let shared = ChangeView()
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var froopData: FroopData = FroopData()
    // @ObservedObject var froopDataListener = FroopDataListener.shared
    @ObservedObject var myData = MyData.shared
    @Published var nextView: Bool = false
    @Published var pageNumber: Int = 1
    
    func changeThePageNumber() {
        PrintControl.shared.printProfile("-ChangeView: Function: changeThePageNumber is firing!")
        if self.nextView == true {
            self.pageNumber += 1
            self.nextView = false
        }
    }
}

struct NFWalkthroughScreen: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var locationViewModel = LocationSearchViewModel()
    @ObservedObject var myData = MyData.shared
    @ObservedObject var changeView = ChangeView.shared
    @State private var homeViewModel = HomeViewModel()
    @Binding var showNFWalkthroughScreen: Bool
    @Binding var froopAdded: Bool
    
    var body: some View {
        // For Slide Animation...
        
        ZStack {
            VStack {
                HStack {
                    Button {
                        changeView.pageNumber -= 1
                    } label: {
                        Image(systemName: "arrow.backward.square.fill")
                            .font(.system(size: 24))
                            .foregroundColor(colorScheme == .dark ? Color(red: 50/255, green: 46/255, blue: 62/255) : Color(red: 50/255, green: 46/255, blue: 62/255))
                            .opacity(changeView.pageNumber >= 2 ? 0.0 : 1.0)
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding(.top, 20)
            .padding(.leading, 20)
            // Changing Between Views....
            Group {
                switch changeView.pageNumber {
                    case 1:
                        FroopTypeOrTemplate(froopData: changeView.froopData)
                            .environmentObject(locationViewModel)
                            .transition(.push(from: .bottom)) // Apply transition here
                    case 2:
                        FroopLocationView(changeView: changeView, froopData: changeView.froopData, homeViewModel: $homeViewModel)
                            .environmentObject(locationViewModel)
                            .transition(.push(from: .bottom)) // Apply transition here
                    case 3:
                        FroopDateView(changeView: changeView, froopData: changeView.froopData, homeViewModel: $homeViewModel)
                            .environmentObject(locationViewModel)
                            .transition(.push(from: .bottom)) // Apply transition here
                    case 4:
                        FroopNameView(froopData: changeView.froopData)
                            .environmentObject(locationViewModel)
                            .transition(.push(from: .bottom)) // Apply transition here
                    case 5:
                        FroopSummaryView(froopData: changeView.froopData, changeView: changeView, showNFWalkthroughScreen: $showNFWalkthroughScreen, froopAdded: $froopAdded)
                            .environmentObject(locationViewModel)
                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                    default:
                        Text("Invalid page number")
                            .transition(.opacity) // Apply transition here
                }
            }
            .animation(.default, value: changeView.pageNumber) // Control the animation when pageNumber changes
        }
    }
}
