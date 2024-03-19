//
//  OnboardThree.swift
//  FroopProof
//
//  Created by David Reed on 9/21/23.
//


import SwiftUI

struct OnboardFour: View {
    @ObservedObject var myData = MyData.shared
    @ObservedObject var locationManager = LocationManager.shared
    @State var address: String = ""
    @State var city: String = ""
    @State var state: String = ""
    @State var zipcode: String = ""
    @State private var isKeyboardShown: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @Binding var selectedTab: OnboardingTab

    let imageW: Font.Weight = .thin
    let fontS = Font.system(size: 35)
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white)
                .ignoresSafeArea()
            VStack {
                
                Rectangle()
                    .foregroundColor(Color(red: 250/255, green: 0/255, blue: 95/255))
                    .frame(height: UIScreen.main.bounds.height / 2)
                Spacer()
            }
            VStack {
                Text("SETUP HOME ADDRESS")
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .padding(.top, UIScreen.main.bounds.height / 2 + 10)
                
                Text("It's great to set your home address so you can quickly reference it when creating Froops in the future.")
                    .font(.system(size: 18))
                    .fontWeight(.light)
                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(.top, 25)
                    .multilineTextAlignment(.center)
                
                Text("Remember, Froop does not use or share your information with other users or anyone outside of the platform.")
                    .font(.system(size: 18))
                    .fontWeight(.light)
                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(.top, 10)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            
            VStack (spacing: 10){
                VStack (alignment: .leading) {
                    Text("STREET ADDRESS")
                        .font(.system(size: 14))
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.white)
                        .opacity(0.75)
                        .offset(y: 8)
                    ZStack (alignment: .leading){
                        
                        TextField("", text: $myData.addressStreet)
                            .font(.system(size: 30))
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .fontWeight(.thin)
                            .padding(.leading, 15)
                            .padding(.top, 2)
                            .padding(.bottom, 2)
                            .padding(.trailing, 10)
                            .background(.white)
                            .border(.gray, width: 0.25)
                        
                        Text(myData.addressStreet != "" ? "" : "123 Main Street")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                            .fontWeight(.thin)
                            .padding(.leading, 15)
                            .padding(.top, 2)
                            .padding(.bottom, 2)
                            .padding(.trailing, 10)
                            .background(.clear)
                    }
                }
                
                    
                    VStack (alignment: .leading) {
                        Text("CITY")
                            .font(.system(size: 14))
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(.white)
                            .opacity(0.75)
                            .offset(y: 8)
                        
                    
                    
                    ZStack (alignment: .leading){
                        
                        
                        TextField("", text: $myData.addressCity)
                            .font(.system(size: 30))
                            .fontWeight(.thin)
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .padding(.leading, 15)
                            .padding(.top, 2)
                            .padding(.bottom, 2)
                            .padding(.trailing, 10)
                            .background(.white)
                            .border(.gray, width: 0.25)
                        
                        Text(myData.addressCity != "" ? "" : "Los Angeles")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                            .fontWeight(.thin)
                            .padding(.leading, 15)
                            .padding(.top, 2)
                            .padding(.bottom, 2)
                            .padding(.trailing, 10)
                            .background(.clear)
                    }
                }
                HStack {
                    VStack (alignment: .leading) {
                        Text("STATE")
                            .font(.system(size: 14))
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(.white)
                            .opacity(0.75)
                            .offset(y: 8)
                        
                        ZStack (alignment: .leading){
                            
                            TextField("", text: $myData.addressState)
                                .font(.system(size: 30))
                                .fontWeight(.thin)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .padding(.leading, 15)
                                .padding(.top, 2)
                                .padding(.bottom, 2)
                                .padding(.trailing, 10)
                                .background(.white)
                                .border(.gray, width: 0.25)
                            
                            Text(myData.addressState != "" ? "" : "CA")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                                .fontWeight(.thin)
                                .padding(.leading, 15)
                                .padding(.top, 2)
                                .padding(.bottom, 2)
                                .padding(.trailing, 10)
                                .background(.clear)
                        }
                    }
                    VStack (alignment: .leading) {
                        Text("ZIP CODE")
                            .font(.system(size: 14))
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(.white)
                            .opacity(0.75)
                            .offset(y: 8)
                        
                        ZStack (alignment: .leading){
                            
                            TextField("90210", text: $myData.addressZip)
                                .keyboardType(.numberPad)
                                .font(.system(size: 30))
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .fontWeight(.thin)
                                .padding(.leading, 15)
                                .padding(.top, 2)
                                .padding(.bottom, 2)
                                .padding(.trailing, 10)
                                .background(.white)
                                .border(.gray, width: 0.25)
                            
                            Text(myData.addressZip != "" ? "" : "90210")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                                .fontWeight(.thin)
                                .padding(.leading, 15)
                                .padding(.top, 2)
                                .padding(.bottom, 2)
                                .padding(.trailing, 10)
                                .background(.clear)
                        }
                    }
                }
//                Button () {
//                    
//                } label: {
//                    HStack {
//                        Spacer()
//                        Button {
//                            UIApplication.shared.endEditing()
//                            selectedTab = .fifth
//                        } label: {
//                            ZStack {
//                                RoundedRectangle(cornerRadius: 10)
//                                    .frame(width: 75, height: 35)
//                                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
//                                Text("Save")
//                                    .font(.system(size: 18))
//                                    .fontWeight(.regular)
//                                    .foregroundColor(.white)
//                            }
//                        }
//                    }
//                }
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width - 100)
            .padding(.top, 120)
            
            Button () {
               
            } label: {
                HStack {
                    Spacer()
                    Button {
                        UIApplication.shared.endEditing()
                        selectedTab = .fifth
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 75, height: 35)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            Text("Save")
                                .font(.system(size: 18))
                                .fontWeight(.regular)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .offset(y: -50)
            .padding(.trailing, 25)
            
        }
        .onAppear {
            populateCurrentAddress()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
                .merge(
                    with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
                )
        ) { notification in
            guard let userInfo = notification.userInfo else { return }
            
            let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            
            let duration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.0
            
            withAnimation(.easeInOut(duration: duration)) {
                if notification.name == UIResponder.keyboardWillShowNotification {
                    keyboardHeight = endFrame?.height ?? 0
                } else {
                    keyboardHeight = 0
                }
            }
        }
//        .offset(y: isKeyboardShown ? 0 : keyboardHeight / 2)
        .ignoresSafeArea()
     
    }
    func populateCurrentAddress() {
        locationManager.getCurrentAddress { placemark in
            guard let placemark = placemark else { return }
            
            DispatchQueue.main.async {
                print([placemark.subThoroughfare, placemark.thoroughfare])
                
                // Update your address fields here
                self.myData.addressStreet = [placemark.subThoroughfare, placemark.thoroughfare]
                    .compactMap { $0 }
                    .joined(separator: " ")
                self.myData.addressCity = placemark.locality ?? ""
                self.myData.addressState = placemark.administrativeArea ?? ""
                self.myData.addressZip = placemark.postalCode ?? ""
            }
        }
    }
}


