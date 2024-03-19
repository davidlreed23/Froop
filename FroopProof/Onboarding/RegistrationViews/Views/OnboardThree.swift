//
//  OnboardTwo.swift
//  FroopProof
//
//  Created by David Reed on 9/21/23.
//

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

enum ActiveAlert {
    case none, invalidPhoneNumber, verified
}

struct OnboardThree: View {
    @ObservedObject var myData = MyData.shared
    @FocusState private var focusedField: ProfileNameFocus?
    @State var phoneNumber: String = ""
    @State var OTPCode: String = ""
    @State private var OTPSent: Bool = false
    @State private var isKeyboardShown: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    @State private var isShowingOTPAlert = false
    @State private var formattedPhoneNumber: String = ""
    @State private var activeAlert: ActiveAlert = .none
    @State private var showAlert: Bool = false
    @State private var alertMessage = ""
    @State private var enteredOTP: String = ""
    @State private var OTPVerified: Bool = false
    @Binding var selectedTab: OnboardingTab

    var otpAlert: Alert {
        Alert(title: Text("Enter OTP"),
              message: Text("Please enter the received OTP code:"),
              primaryButton: .default(Text("Verify"), action: {
            verifyOTP(enteredOTP: enteredOTP)
        }),
              secondaryButton: .cancel()
        )
    }
    
    @AppStorage("ProfileCompletionCurrentPage") var ProfileCompletionCurrentPage = 4
    
    let imageW: Font.Weight = .thin
    let fontS = Font.system(size: 35)
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(.white)
                .ignoresSafeArea()
            
            VStack {
                
                Rectangle()
                    .fill(Color(red: 185/255, green: 229/255, blue: 25/255))
                    .frame(height: UIScreen.main.bounds.height / 2)
                
                Spacer()
            }
            .onAppear {
                fetchAndDisplayExistingPhoneNumber()
                formattedPhoneNumber = formatPhoneNumber(myData.phoneNumber)
            }
            
            ///BOTTOM SCREEN CONTENT
            VStack {
                Text("MOBILE NUMBER VERIFICATION")
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .padding(.top, UIScreen.main.bounds.height / 2 + 10)
                
                Text("Let's verify the phone number attached to this device.")
                    .font(.system(size: 18))
                    .fontWeight(.light)
                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(.top, 25)
                    .multilineTextAlignment(.center)
                
                Text("With Froop, each person's phone number is the primary way of finding and connecting with other users on the platform.")
                    .font(.system(size: 18))
                    .fontWeight(.light)
                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                    .opacity(0.8)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(.top, 25)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            
            VStack (spacing: 60){
                VStack {
                    
                    ///PHONE TEXT FIELD
                    VStack (alignment: .leading){
                        Text("ADD PHONE NUMBER \(String(describing: OTPSent))")
                            .font(.system(size: 14))
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .offset(y: 8)
                        
                        ZStack (alignment: .leading){
                            
                            TextField("", text: $formattedPhoneNumber)
                                .focused($focusedField, equals: .third)
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
                                .onChange(of: formattedPhoneNumber) { oldValue, newValue in
                                    formattedPhoneNumber = newValue.formattedPhoneNumber
                                    myData.phoneNumber = removePhoneNumberFormatting(newValue)
                                }
                            //                                .disabled(myData.OTPVerified)
                            
                            Text(formattedPhoneNumber != "" ? "" : "(123) 456-7890")
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
                    
                }
                
                VStack {
                    ZStack {
                        VStack (alignment: .leading){
                            Text(myData.OTPVerified ? "ALREADY VERIFIED \(String(describing: myData.OTPVerified))_\(String(describing: OTPVerified))" : "VERIFICATION CODE \(String(describing: myData.OTPVerified))_\(String(describing: OTPVerified))")
                                .font(.system(size: 14))
                                .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .opacity(0.95)
                                .offset(y: 8)
                            
                            TextField(
                                myData.OTPVerified ? "Verification Confirmed." :
                                    (myData.OTPVerified ? "Verification Confirmed." : "Enter OTP Code Here."),
                                text: $OTPCode
                            )
                            .font(.system(size: 24))
                            .fontWeight(.thin)
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .padding(.leading, 15)
                            .padding(.top, 2)
                            .padding(.bottom, 2)
                            .padding(.trailing, 10)
                            .background(.white)
                            .border(.gray, width: 0.25)
                            .disabled(OTPVerified)
                        }
                        .opacity(myData.OTPVerified ? 1 : OTPSent ? 1 : 0.0)
                        
                        VStack {
                            VStack (alignment: .leading){
                                Text(myData.OTPVerified ? "ALREADY VERIFIED \(String(describing: myData.OTPVerified))_\(String(describing: OTPVerified))" : "VERIFICATION CODE \(String(describing: myData.OTPVerified))_\(String(describing: OTPVerified))")
                                    .font(.system(size: 14))
                                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                    .opacity(0.25)
                                    .offset(y: 8)
                                
                                TextField(
                                    myData.OTPVerified ? "Verification Confirmed." :
                                        (OTPVerified ? "Already Verified." : "Enter OTP Code Here."),
                                    text: $OTPCode
                                )
                                .focused($focusedField, equals: .fourth)
                                .keyboardType(.numberPad)
                                .font(.system(size: 24))
                                .fontWeight(.thin)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .padding(.leading, 15)
                                .padding(.top, 2)
                                .padding(.bottom, 2)
                                .padding(.trailing, 10)
                                .background(.white)
                                .border(.gray, width: 0.25)
                                .disabled(OTPVerified)
                            }
                            .opacity(OTPSent ? 1.0 : 0.0)
                        }
                    }
                    .opacity(isValidPhoneNumber(formattedPhoneNumber) ? 1 : 0)
                }
                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width - 100)
            .padding(.top, 120)
            
            VStack (spacing: 0) {
                Rectangle()
                    .fill(Color.white.opacity(0.001))
                    .frame(height: UIScreen.main.bounds.height / 4.5)
                    .onTapGesture {
                        if OTPVerified {
                            activeAlert = .verified
                            showAlert = true
                            print(showAlert)
                        } else {
                            focusedField = .third
                            print(showAlert)
                        }
                    }
                Rectangle()
                    .fill(Color.white.opacity(0.001))
                    .frame(height: UIScreen.main.bounds.height / 5)
                    .onTapGesture {
                        if !OTPVerified {
                            focusedField = .fourth
                            print(showAlert)
                        } else {
//                            activeAlert = .verified
//                            showAlert = true
                            print(showAlert)
                        }
                    }
                Spacer()
            }
            
            ///BUTTONS
            VStack {
                ZStack {
                    
                    if myData.OTPVerified {
                        
                        EmptyView()
//
                    } else {
                        
                        Button {
                            focusedField = nil
                            //                                hideKeyboard()
                            if isValidPhoneNumber(formattedPhoneNumber) {
                                if formattedPhoneNumber == "(123) 456-7890" {
                                    OTPSent = true
                                    sendOTP(phoneNumber: formattedPhoneNumber)
                                } else {
                                    sendOTP(phoneNumber: formattedPhoneNumber)
                                }
                            } else {
                                showAlert = true
                            }
                        } label: {
                            HStack {
                                Spacer()
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .frame(width: 100, height: 35)
                                        .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                    Text(OTPSent ? "Resend" : "Get Code")
                                        .font(.system(size: 18))
                                        .fontWeight(.regular)
                                        .foregroundColor(.white)
                                }
                                .opacity(myData.OTPVerified ? 0 : 1)
                            }
                        }
                        .opacity(isValidPhoneNumber(formattedPhoneNumber) ? 1 : 0)
                    }
                }
                .padding(.top, 200)
                .padding(.trailing, 50)
                Spacer()
            }
            
            Button () {
               
            } label: {
                HStack {
                    Spacer()
                    Button {
                        if myData.OTPVerified {
                            selectedTab = .fourth
                        } else {
                            if OTPVerified {
                                selectedTab = .fourth
                            } else {
                                verifyOTP(enteredOTP: OTPCode)
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 75, height: 35)
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            Text(myData.OTPVerified ? "Next" : (OTPVerified ? "Save" : "Verify"))
                                .font(.system(size: 18))
                                .fontWeight(.regular)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .offset(y: -50)
            .padding(.trailing, 25)
            .opacity(OTPCode != "" || OTPVerified ? 1 : 0)
            
        }
        .alert(isPresented: $showAlert) {
            switch activeAlert {
                case .invalidPhoneNumber:
                    return Alert(
                        title: Text("Phone Number is invalid"),
                        message: Text("Please enter a valid phone number."),
                        dismissButton: .default(Text("OK"))
                    )
                case .verified:
                    return Alert(
                        title: Text("Verified"),
                        message: Text("Your Phone Number has been Verified, and has been linked to your account. You can proceed with setting up your profile."),
                        dismissButton: .default(Text("OK"))
                    )
                default:
                    return Alert(title: Text("Unexpected Alert"))
            }
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
    
    func sendOTP(phoneNumber: String) {
        // Remove non-numeric characters
        let cleanedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Prepend the country code to get it in E.164 format. Assume 1 as the country code for the USA.
        let e164FormattedNumber = "+1" + cleanedPhoneNumber
        
        PhoneAuthProvider.provider().verifyPhoneNumber(e164FormattedNumber, uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                // Handle the error
                print(error.localizedDescription)
                return
            }
            // If there's no error, save the verificationID
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            OTPSent = true
            isShowingOTPAlert = true
        }
    }
    
    func verifyOTP(enteredOTP: String) {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else { return }
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: enteredOTP)

        if let currentUser = Auth.auth().currentUser {
            currentUser.link(with: credential) { (authResult, error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                OTPVerified = true
                myData.OTPVerified = true
                OTPCode = "Verification Confirmed."
            }
        }
    }
    
    func removePhoneNumberFormatting(_ phoneNumber: String) -> String {
        let cleanedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return cleanedPhoneNumber
    }
    
    func formatPhoneNumber(_ phoneNumber: String) -> String {
        let cleanedPhoneNumber = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        let mask = "(XXX) XXX-XXXX"
        var result = ""
        var index = cleanedPhoneNumber.startIndex
        for ch in mask where index < cleanedPhoneNumber.endIndex {
            if ch == "X" {
                result.append(cleanedPhoneNumber[index])
                index = cleanedPhoneNumber.index(after: index)
            } else {
                result.append(ch)
            }
        }
        return result
    }
    
    func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        PrintControl.shared.printLogin("-Login: Function: isValidPhoneNumber firing")
        
        // Strip out non-numeric characters
        let numericOnlyString = phoneNumber.filter { $0.isNumber }
        
        // Ensure there are exactly 10 digits
        guard numericOnlyString.count == 10 else {
            return false
        }
        
        // Now, verify if the input format matches any of the desired formats
        let phoneNumberPatterns = [
            "^\\(\\d{3}\\) \\d{3}-\\d{4}$",  // (123) 999-9999
            "^\\d{10}$",                    // 1239999999
            "^\\d{3}\\.\\d{3}\\.\\d{4}$",  // 123.999.9999
            "^\\d{3} \\d{3} \\d{4}$"       // 123 999 9999
        ]
        
        return phoneNumberPatterns.contains { pattern in
            let predicate = NSPredicate(format: "SELF MATCHES %@", pattern)
            return predicate.evaluate(with: phoneNumber)
        }
    }
    
    func fetchAndDisplayExistingPhoneNumber() {
        if let existingPhoneNumber = Auth.auth().currentUser?.phoneNumber, !existingPhoneNumber.isEmpty {
            // Remove the country code
            let phoneNumberWithoutCountryCode = existingPhoneNumber.hasPrefix("+1") ? String(existingPhoneNumber.dropFirst(2)) : existingPhoneNumber
            
            // Update state properties
            myData.phoneNumber = phoneNumberWithoutCountryCode
            formattedPhoneNumber = formatPhoneNumber(phoneNumberWithoutCountryCode)
            
            // Update the OTP verification flag
            OTPVerified = true
            myData.OTPVerified = true
        }
    }
    
    private func hideKeyboard() {
        PrintControl.shared.printLogin("-CustomTextFieldOTP: Function: hideKeyboard firing")
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}

