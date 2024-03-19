//
//  LocationResultsCell.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationSearchResultCell: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var locationServices = LocationServices.shared
    // @ObservedObject var froopDataListener = FroopDataListener.shared
 
    
    let title: String
    let subtitle: String
    @State private var location: FroopData?
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color.gray.opacity(0.5), lineWidth: 0.5) // Border inside the shape
                .fill(Color.primary.opacity(0.4))
                .frame(width: UIScreen.screenWidth - 30, height: 75)

            HStack {
                Image(systemName: "mappin.circle.fill")
                    .resizable()
                    .foregroundColor(colorScheme == .dark ? .white : .white)
                    .accentColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .frame(width: 40, height: 40)
                    
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .white)

                    
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(colorScheme == .dark ? .white : .white)

                        .fontWeight(.light)
                        .frame(minWidth: 0, maxWidth: UIScreen.screenWidth * 0.65)
                    
                    Divider()
                }
                .padding(.leading, 8)
                .padding(.vertical, 4)
            }
            .padding(.leading)
            
            
        }
        .padding(.leading, 15)
        .padding(.trailing, 15)
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

