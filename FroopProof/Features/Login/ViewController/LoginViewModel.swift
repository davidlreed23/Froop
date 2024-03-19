//
//  LoginViewModel.swift
//  FroopProof
//
//  Created by David Reed on 1/18/23.
//

import SwiftUI
import UIKit
import Foundation
import FirebaseAuth
import Firebase
import CryptoKit
import AuthenticationServices
import GoogleSignInSwift
import GoogleSignIn


class LoginViewModel: ObservableObject {
    @ObservedObject var accountManager = AccountSetupManager.shared
    // MARK: View Properties
    @Published var mobileNo: String = ""
    @Published var otpCode: String = ""
    
    @Published var CLIENT_CODE: String = ""
    @Published var showOTPField: Bool = false
    
    // MARK: Error Properties
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: App Log Status
    @AppStorage("log_status") var logStatus: Bool = false
    
    // MARK: Apple Sign in Properties
    @Published var nonce: String = ""
    
    // MARK: Firebase API's
    func getOTPCode(){
        PrintControl.shared.printLogin("-LoginViewModel: Function: getOTPCode firing")
        UIApplication.shared.closeKeyboard()
        PrintControl.shared.printLogin("Getting OTP Code")
        Task{
            do{
                // MARK: Disable it when testing with Real Device
                Auth.auth().settings?.isAppVerificationDisabledForTesting = true
                
                PrintControl.shared.printLogin("+1\(mobileNo)")
                let formattedMobileNo = self.mobileNo.replacingOccurrences(of: "[()\\- ]", with: "", options: .regularExpression)
                PrintControl.shared.printLogin("Before calling verifyPhoneNumber")
                let code = try await PhoneAuthProvider.provider().verifyPhoneNumber("+1\(formattedMobileNo)", uiDelegate: nil)
                PrintControl.shared.printLogin("After calling verifyPhoneNumber")
                await MainActor.run(body: {
                    CLIENT_CODE = code
                    // MARK: Enabling OTP Field When It's Success
                    withAnimation(.easeInOut){showOTPField = true}
                    PrintControl.shared.printLogin("OTP Code Success")
                })
            }catch{
                await handleError(error: error)
            }
        }
    }
    
    func verifyOTPCode(){
        PrintControl.shared.printLogin("-LoginView: Function: verifyOTPCode firing")
        UIApplication.shared.closeKeyboard()
        PrintControl.shared.printLogin("verifying OTP Code")
        Task{
            do{
                let credential = PhoneAuthProvider.provider().credential(withVerificationID: CLIENT_CODE, verificationCode: otpCode)
                
                try await Auth.auth().signIn(with: credential)
                
                // MARK: User Logged in Successfully
                PrintControl.shared.printLogin("Success!")
                await MainActor.run(body: {
                    withAnimation(.easeInOut){logStatus = true}
                })
            }catch{
                await handleError(error: error)
            }
        }
    }
    
    // MARK: Handling Error
    private func handleError(error: Error)async{
        PrintControl.shared.printLogin("-LoginView: Function: handleError firing")
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            PrintControl.shared.printErrorMessages("Error in handleError: \(errorMessage)")
            showError = true
        })
    }
    
    // MARK: Apple Sign in API
    func appleAuthenticate(credential: ASAuthorizationAppleIDCredential) {
        PrintControl.shared.printLogin("-LoginView: Function: appleAuthenticate firing")

        guard let token = credential.identityToken else {
            PrintControl.shared.printLogin("Error with firebase: identity token is missing")
            return
        }

        guard let tokenString = String(data: token, encoding: .utf8) else {
            PrintControl.shared.printLogin("Error with Token: unable to convert token to string")
            return
        }

        let firebaseCredential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)

        Auth.auth().signIn(with: firebaseCredential) { [weak self] (result, err) in
            if let error = err {
                PrintControl.shared.printLogin(error.localizedDescription)
                return
            }

            // User Successfully Logged Into Firebase
            PrintControl.shared.printLogin("Logged In Success")

            guard let uid = Auth.auth().currentUser?.uid else { return }
            self?.checkUserDocumentExists(uid: uid) { exists in
                if exists {
                    // User document exists, so you might want to update specific fields or skip creation of subcollections.
                    // You can define your logic here based on your app's requirements.
                    DispatchQueue.main.async {
                        self?.logStatus = true
                    }
                } else {
                    // User document doesn't exist, safe to proceed with creating the user document and subcollections.
                    self?.accountManager.createUserAndCollections(uid: uid) { error in
                        if let error = error {
                            PrintControl.shared.printErrorMessages("Error creating user and collections: \(error.localizedDescription)")
                            return
                        }
                        DispatchQueue.main.async {
                            self?.logStatus = true
                        }
                    }
                }
            }
        }
    }

    private func checkUserDocumentExists(uid: String, completion: @escaping (Bool) -> Void) {
        let userDocRef = Firestore.firestore().collection("users").document(uid)
        userDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // The user document exists.
                completion(true)
            } else {
                // The user document does not exist or error occurred.
                completion(false)
            }
        }
    }
}


final class Application_utility {
    static var rootViewController: UIViewController {
        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            fatalError("Unable to get UIWindowScene")
        }
        
        guard let root = screen.windows.first?.rootViewController else {
            fatalError("Unable to get rootViewController")
        }
        
        return root
    }
}

// MARK: Apple Sign in Helpers
func sha256(_ input: String) -> String {
    PrintControl.shared.printLogin("-LoginViewModel: Function: sha256 firing")
    let inputData = Data(input.utf8)
    let hashedData = SHA256.hash(data: inputData)
    let hashString = hashedData.compactMap {
        return String(format: "%02x", $0)
    }.joined()
    
    return hashString
}

func randomNonceString(length: Int = 32) -> String {
    PrintControl.shared.printLogin("-LoginViewModel: Function randomNonceString firing")
    precondition(length > 0)
    let charset: Array<Character> =
    Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length
    
    while remainingLength > 0 {
        let randoms: [UInt8] = (0 ..< 16).map { _ in
            var random: UInt8 = 0
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if errorCode != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
            }
            return random
        }
        
        randoms.forEach { random in
            if remainingLength == 0 {
                return
            }
            
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    
    return result
}
