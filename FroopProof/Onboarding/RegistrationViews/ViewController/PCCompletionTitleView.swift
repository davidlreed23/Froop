//
//  PCCompletionTitleView.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import UIKit
import iPhoneNumberField

struct ProfileCompletionTitleView: View {
    @ObservedObject var myData = MyData.shared
    
    
    var body: some View {
        ZStack {
            ZStack (alignment: .center) {
                Image("friends")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.2)
                    .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight)
                    .mask {
                        Rectangle()
                            .frame(width: UIScreen.screenWidth, height: UIScreen.screenHeight)
                    }
            }
            
            ZStack() {
                
                VStack{
                    AdaptiveImage(
                        light:
                            Image("FroopLogoWhite")
                            .resizable()
                        ,
                        dark:
                            Image("FroopLogoWhite")
                            .resizable()
                    )
                    .onTapGesture {
                        print(myData)
                        print("""
                          MyData:
                          - firstName: \(myData.firstName)
                          - lastName: \(myData.lastName)
                          - phoneNumber: \(myData.phoneNumber)
                          - addressNumber: \(myData.addressNumber)
                          - addressStreet: \(myData.addressStreet)
                          - unitName: \(myData.unitName)
                          - addressCity: \(myData.addressCity)
                          - addressState: \(myData.addressState)
                          - addressZip: \(myData.addressZip)
                          - addressCountry: \(myData.addressCountry)
                          - profileImageUrl: \(myData.profileImageUrl)
                          - coordinate: \(myData.coordinate)
                          - badgeCount: \(myData.badgeCount)
                          - fcmToken: \(myData.fcmToken)
                          - OTPVerified: \(myData.OTPVerified)
                          - froopUserID: \(myData.froopUserID)
                          """)
                    }
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 300, alignment: .center)
                    .accessibility(hidden: true)
                    .padding(.top, 125)
                    
                    Text("Do Anything with Anyone, Anywhere!")
                        .font(.title)
                        .foregroundColor(Color(red: 206/255, green: 255/255, blue: 28/255))
                        .multilineTextAlignment(.center)
                        .padding(.top, 25)
                    
                    VStack (alignment: .center, spacing: 20){
                        Text("Welcome!")
                        
                        Text("Lets begin with creating your profile")
                    }
                    .font(.system(size: 28))
                    .fontWeight(.regular)
                    .foregroundStyle(.white)
                    .padding(.top, UIScreen.screenHeight * 0.1)
                    .padding(.horizontal, 50)
                    .multilineTextAlignment(.center)
                    Spacer()
                }
            }
            .ignoresSafeArea()
        }
    }
}
