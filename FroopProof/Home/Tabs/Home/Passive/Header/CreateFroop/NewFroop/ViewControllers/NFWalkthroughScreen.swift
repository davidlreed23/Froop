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
    @Published var froopTypeData: FroopType?
    @ObservedObject var myData = MyData.shared
    @Published var nextView: Bool = false
    @Published var pageNumber: Int = 1
    @Published var currentViewBuildOrder: [Int] = [1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    @Published var froopAdded = false
    @Published var showNFWalkthroughScreen = false

    
    func configureViewBuildOrder() {
        guard let viewPositions = froopTypeData?.viewPositions else { return }
        var order: [(position: Int, value: Int)] = []

        for (index, value) in viewPositions.enumerated() {
            if value > 0 {
                // Append a tuple of (position, value) to 'order'
                order.append((position: index + 1, value: value))
            }
        }

        // Sort by the values, then map to the positions
        currentViewBuildOrder = order.sorted(by: { $0.value < $1.value }).map { $0.position }
        print("✅ currentViewBuildOrder \(String(describing: currentViewBuildOrder))")
    }
    
    func currentPageView(locationViewModel: LocationSearchViewModel) -> some View {
        guard let nextPageIndex = currentViewBuildOrder.indices.contains(pageNumber - 1) ? currentViewBuildOrder[pageNumber - 1] : nil else {
            return AnyView(Text("End of Flow"))
        }
        
        switch nextPageIndex {
            case 1:
                return AnyView(FroopTypeOrTemplate(froopData: froopData).environmentObject(locationViewModel))
            case 2:
                return AnyView(FroopLocationView(froopData: froopData).environmentObject(locationViewModel))
            case 3:
                return AnyView(FroopDateView(froopData: froopData).environmentObject(locationViewModel))
            case 4:
                return AnyView(FroopNameView(froopData: froopData).environmentObject(locationViewModel))
            case 5:
                return AnyView(FroopSummaryView(froopData: froopData).environmentObject(locationViewModel))
            case 6:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 7:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 8:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 9:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 10:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 11:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 12:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 13:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 14:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 15:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 16:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 17:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 18:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 19:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            case 20:
                return AnyView(EmptyView().environmentObject(locationViewModel))
            default:
                return AnyView(Text("Invalid Page"))
        }
    }
    
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
    @Binding var froopAdded: Bool
    
    private func currentPageView() -> some View {
        changeView.currentPageView(locationViewModel: locationViewModel)
    }
    
    var body: some View {
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
            
            // Dynamically serve the current page view based on the flow defined in ChangeView
            currentPageView() // This is where the currentPageView is incorporated into the ZStack
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                .animation(.default, value: changeView.pageNumber) // Animate the transition between views
        }
    }
}



//
//  NFWalkthroughScreen.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

//import SwiftUI
//import iPhoneNumberField
//import Firebase
//import FirebaseFirestore
//import FirebaseFirestoreSwift
//
//
//
//class ChangeView: ObservableObject {
//    static let shared = ChangeView()
//    @ObservedObject var printControl = PrintControl.shared
//    @ObservedObject var froopData: FroopData = FroopData()
//    // @ObservedObject var froopDataListener = FroopDataListener.shared
//    @Published var froopTypeData: FroopType?
//    @ObservedObject var myData = MyData.shared
//    @Published var nextView: Bool = false
//    @Published var pageNumber: Int = 1
//    @Published var currentViewBuildOrder: [Int] = []
//    
//    func configureViewBuildOrder() {
//        guard let viewPositions = froopTypeData?.viewPositions else { return }
//        var order: [(position: Int, value: Int)] = []
//
//        for (index, value) in viewPositions.enumerated() {
//            if value > 0 {
//                // Append a tuple of (position, value) to 'order'
//                order.append((position: index + 1, value: value))
//            }
//        }
//
//        // Sort by the values, then map to the positions
//        currentViewBuildOrder = order.sorted(by: { $0.value < $1.value }).map { $0.position }
//        print("✅ currentViewBuildOrder \(String(describing: currentViewBuildOrder))")
//    }
//    
//    func changeThePageNumber() {
//        PrintControl.shared.printProfile("-ChangeView: Function: changeThePageNumber is firing!")
//        if self.nextView == true {
//            self.pageNumber += 1
//            self.nextView = false
//        }
//    }
//}
//
//struct NFWalkthroughScreen: View {
//    @Environment(\.colorScheme) var colorScheme
//    @StateObject var locationViewModel = LocationSearchViewModel()
//    @ObservedObject var myData = MyData.shared
//    @ObservedObject var changeView = ChangeView.shared
//    @State private var homeViewModel = HomeViewModel()
//    @Binding var showNFWalkthroughScreen: Bool
//    @Binding var froopAdded: Bool
//    
//    private var currentPageView: some View {
//        Group {
//            if let nextPage = changeView.currentViewBuildOrder.indices.contains(changeView.pageNumber - 1) ? changeView.currentViewBuildOrder[changeView.pageNumber - 1] : nil {
//                switch nextPage {
//                    case 1:
//                        FroopTypeOrTemplate(froopData: changeView.froopData)
//                            .environmentObject(locationViewModel)
//                            .transition(.push(from: .bottom))
//                    case 2:
//                        FroopLocationView(changeView: changeView, froopData: changeView.froopData, homeViewModel: $homeViewModel)
//                            .environmentObject(locationViewModel)
//                            .transition(.push(from: .bottom))
//                    case 3:
//                        FroopDateView(changeView: changeView, froopData: changeView.froopData, homeViewModel: $homeViewModel)
//                            .environmentObject(locationViewModel)
//                            .transition(.push(from: .bottom))
//                    case 4:
//                        FroopNameView(froopData: changeView.froopData)
//                            .environmentObject(locationViewModel)
//                            .transition(.push(from: .bottom))
//                    case 5:
//                        FroopSummaryView(froopData: changeView.froopData, changeView: changeView, showNFWalkthroughScreen: $showNFWalkthroughScreen, froopAdded: $froopAdded)
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 6:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 7:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 8:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 9:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 10:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 11:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 12:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 13:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 14:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 15:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 16:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 17:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 18:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 19:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    case 20:
//                        EmptyView() // Until We add more views.
//                            .environmentObject(locationViewModel)
//                            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
//                    default:
//                        Text("Invalid page number")
//                            .transition(.opacity) // Apply transition here
//                }
//            }
//                .animation(.default, value: changeView.pageNumber) // Control the animation when pageNumber changes
//        }
//    }
//    
//    var body: some View {
//        // For Slide Animation...
//        
//        ZStack {
//            VStack {
//                HStack {
//                    Button {
//                        changeView.pageNumber -= 1
//                    } label: {
//                        Image(systemName: "arrow.backward.square.fill")
//                            .font(.system(size: 24))
//                            .foregroundColor(colorScheme == .dark ? Color(red: 50/255, green: 46/255, blue: 62/255) : Color(red: 50/255, green: 46/255, blue: 62/255))
//                            .opacity(changeView.pageNumber >= 2 ? 0.0 : 1.0)
//                    }
//                    Spacer()
//                }
//                Spacer()
//            }
//            .padding(.top, 20)
//            .padding(.leading, 20)
//            // Changing Between Views....
//        }
//    }
//}
