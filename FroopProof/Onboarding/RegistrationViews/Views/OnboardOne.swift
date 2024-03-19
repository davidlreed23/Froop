//
//  ProfileCompletionView1.swift
//  FroopProof
//
//  Created by David Reed on 1/19/23.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Firebase

struct OnboardOne: View {
    @ObservedObject var myData = MyData.shared
    @ObservedObject var printControl = PrintControl.shared
    // @ObservedObject var froopDataListener = FroopDataListener.shared
    @Binding var selectedTab: OnboardingTab
    
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 1
    var uid = Auth.auth().currentUser?.uid ?? ""
    
    var body: some View {
        ZStack (alignment: .center){
            Rectangle()
                .fill(Color(red: 50/255, green: 46/255, blue: 62/255))
                .ignoresSafeArea()
            HStack{
                Spacer()
                VStack {
                    ProfileCompletionTitleView()
                    Spacer()
                }
                Spacer()
            }
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Button {
                        selectedTab = .second
                    } label: {
                        VStack {
                            Spacer()
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundColor(Color(red: 250/255, green: 0/255, blue: 95/255))
                                    .frame(width: 110, height: 40)
                                
                                Text("START")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            }
                            .offset(x: 15)
                            .padding(.bottom, 200)
                            .padding(.trailing, 25)
                        }
                    }
                }
                Spacer()
            }
        }
        .ignoresSafeArea(.keyboard)
        .ignoresSafeArea()
        .onAppear {
            MyData.shared.froopUserID = uid
            fetchAndUpdateUserData()
        }
        
    }
    
    func fetchAndUpdateUserData() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User is not logged in.")
            return
        }
        
        let db = Firestore.firestore()
        let userDocRef = db.collection("users").document(uid)
        
        userDocRef.getDocument { (document, error) in
            guard let document = document, document.exists else {
                print("Document does not exist")
                return
            }
            
            let data = document.data()
            
            DispatchQueue.main.async {
                // Update MyData properties with values from Firestore
                if let froopUserID = data?["froopUserID"] as? String {
                    MyData.shared.froopUserID = froopUserID
                }
                if let timeZone = data?["timeZone"] as? String {
                    MyData.shared.timeZone = timeZone
                }
                if let firstName = data?["firstName"] as? String {
                    MyData.shared.firstName = firstName
                }
                if let lastName = data?["lastName"] as? String {
                    MyData.shared.lastName = lastName
                }
                if let phoneNumber = data?["phoneNumber"] as? String {
                    MyData.shared.phoneNumber = phoneNumber
                }
                if let addressNumber = data?["addressNumber"] as? String {
                    MyData.shared.addressNumber = addressNumber
                }
                if let addressStreet = data?["addressStreet"] as? String {
                    MyData.shared.addressStreet = addressStreet
                }
                if let unitName = data?["unitName"] as? String {
                    MyData.shared.unitName = unitName
                }
                if let addressCity = data?["addressCity"] as? String {
                    MyData.shared.addressCity = addressCity
                }
                if let addressState = data?["addressState"] as? String {
                    MyData.shared.addressState = addressState
                }
                if let addressZip = data?["addressZip"] as? String {
                    MyData.shared.addressZip = addressZip
                }
                if let addressCountry = data?["addressCountry"] as? String {
                    MyData.shared.addressCountry = addressCountry
                }
                if let profileImageUrl = data?["profileImageUrl"] as? String {
                    MyData.shared.profileImageUrl = profileImageUrl
                }
                if let fcmToken = data?["fcmToken"] as? String {
                    MyData.shared.fcmToken = fcmToken
                }
                if let OTPVerified = data?["OTPVerified"] as? Bool {
                    MyData.shared.OTPVerified = OTPVerified
                }
                if let premiumAccount = data?["premiumAccount"] as? Bool {
                    MyData.shared.premiumAccount = premiumAccount
                }
                if let professionalAccount = data?["professionalAccount"] as? Bool {
                    MyData.shared.professionalAccount = professionalAccount
                }
                if let professionalTemplates = data?["professionalTemplates"] as? [String] {
                    MyData.shared.professionalTemplates = professionalTemplates
                }
                if let creationDate = data?["creationDate"] as? Date {
                    MyData.shared.creationDate = creationDate
                }
                if let userDescription = data?["userDescription"] as? String {
                    MyData.shared.userDescription = userDescription
                }
            }
        }
    }
}

