//
//  OnboardOne.swift
//  Design_Layouts
//
//  Created by David Reed on 9/21/23.
//

import SwiftUI
import MapKit
import Firebase
import FirebaseStorage
import Kingfisher

enum ProfileNameFocus: Hashable {
    case first
    case second
    case third
    case fourth
}

struct OnboardTwo: View {
    @ObservedObject var myData = MyData.shared
    @ObservedObject var accountSetupManager = AccountSetupManager.shared
    @FocusState private var focusedField: ProfileNameFocus?
    @State var firstName: String = ""
    @State var lastName: String = ""
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
                    .fill(Color(red: 0/255, green: 200/255, blue: 226/255))
                    .frame(height: UIScreen.main.bounds.height / 2)
                
                Spacer()
            }
            
            
            VStack {
                Text("HINT:  USE YOUR REAL NAME.")
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .padding(.top, UIScreen.main.bounds.height / 2 + 10)
                
                Text("Your information is private, and can only be seen by friends you choose to share your information with.")
                    .font(.system(size: 18))
                    .fontWeight(.light)
                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(.top, 25)
                    .multilineTextAlignment(.center)
                
                Text("Unlike other social platforms, Froop is designed for interactions in the real world.")
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
            
            VStack (spacing: 25){
                VStack (alignment: .leading){
                    Text("FIRST NAME")
                        .font(.system(size: 14))
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.white)
                        .opacity(0.75)
                        .offset(y: 8)
                    
                    ZStack (alignment: .leading){
                        
                        TextField("", text: $myData.firstName)
                            .focused($focusedField, equals: .first)
                            .font(.system(size: 30))
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .fontWeight(.thin)
                            .padding(.leading, 15)
                            .padding(.top, 2)
                            .padding(.bottom, 2)
                            .padding(.trailing, 10)
                            .background(.white)
                            .border(.gray, width: 0.25)
                        
                        Text(MyData.shared.firstName != "" ? "" : "Tap Here To Edit")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                            .opacity(0.5)
                            .fontWeight(.thin)
                            .padding(.leading, 15)
                            .padding(.top, 2)
                            .padding(.bottom, 2)
                            .padding(.trailing, 10)
                            .background(.clear)
                        
                    }
                }
                
                VStack (alignment: .leading) {
                    Text("LAST NAME")
                        .font(.system(size: 14))
                        .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        .foregroundColor(.white)
                        .opacity(0.75)
                        .offset(y: 8)
                    
                    ZStack (alignment: .leading){
                        
                        TextField("", text: $myData.lastName)
                            .focused($focusedField, equals: .second)
                        
                            .font(.system(size: 30))
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .fontWeight(.thin)
                            .padding(.leading, 15)
                            .padding(.top, 2)
                            .padding(.bottom, 2)
                            .padding(.trailing, 10)
                            .background(.white)
                            .border(.gray, width: 0.25)
                        
                        Text(MyData.shared.lastName != "" ? "" : "Tap Here To Edit")
                            .font(.system(size: 30))
                            .foregroundColor(.gray)
                            .opacity(0.5)
                            .fontWeight(.thin)
                            .padding(.leading, 15)
                            .padding(.top, 2)
                            .padding(.bottom, 2)
                            .padding(.trailing, 10)
                            .background(.clear)
                    }
                }
                
                Spacer()
            }
            .ignoresSafeArea(.keyboard)
            .frame(width: UIScreen.main.bounds.width - 100)
            .padding(.top, 120)
            
            VStack (spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.001))
                    .frame(height: UIScreen.main.bounds.height / 4.5)
                    .onTapGesture {
                        focusedField = .first
                    }
                Rectangle()
                    .fill(Color.white.opacity(0.001))
                    .frame(height: UIScreen.main.bounds.height / 5)
                    .onTapGesture {
                        focusedField = .second
                    }
                Spacer()
            }
            
            Button () {
                
            } label: {
                HStack {
                    Spacer()
                    Button {
                        focusedField = nil
                        selectedTab = .third
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
        .ignoresSafeArea()
    }
}

