//
//  DatePickViewCopy.swift
//  FroopProof
//
//  Created by David Reed on 12/3/23.
//

import SwiftUI
import UIKit
import Foundation

struct DatePickViewCopy: View {
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var dataController = DataController.shared
    @ObservedObject var printControl = PrintControl.shared
    // @ObservedObject var froopDataListener = FroopDataListener.shared
    @Binding var transClock: Bool
    @Binding var datePicked: Bool
    @ObservedObject var froopData: FroopData
//    @State var selectedDate = Date()
    @State private var isTouched = false
    @State private var shrink: CGFloat = 0
  
    let dateFormatter = DateFormatter()
    var dateString: String {
        dateFormatter.dateFormat = "MMMM yyyy"
        return dateFormatter.string(from: self.froopData.froopStartTime)
    }
    var selectedDateString: String {
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        return dateFormatter.string(from: self.froopData.froopStartTime)
    }
    
    
    var body: some View {
        ZStack {
            VStack {
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(Color(red: 50/255, green: 46/255, blue: 62/255))
                        .opacity(0.8)
                        .frame(width: UIScreen.screenWidth, height: transClock ? UIScreen.screenHeight * 0.075 : UIScreen.screenHeight * 0.43)
                        .transition(.move(edge: .bottom))
                        .onTapGesture {
//                            shrink = shrink + 10
                            datePicked = true
                        }
                        .offset(y: -25)
                        .ignoresSafeArea()
                    VStack (spacing: 0){
                        Text(datePicked ? selectedDateString : "When is it happening?")
                            .font(.system(size: 32, weight: .thin))
                            .foregroundColor(.white)
                            .frame(maxWidth: UIScreen.screenWidth - 30)
                            .multilineTextAlignment(.center)
                            .padding(.top, UIScreen.screenHeight * 0.14)
                        
                        if datePicked {
                            Text("Confirm Date?")
                                .font(.system(size: 28, weight: .thin))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .frame(width: 225, height: 45)
                                .border(Color.gray, width: 1)
                                .padding(.top)
                                .onTapGesture {
                                    withAnimation(.spring()) {
                                        transClock = true
                                    }
                                }
                        }
                        
                    }
                    .opacity(transClock ? 0 : 1)
                    .animation(Animation.easeInOut(duration: 0.4), value: datePicked)
                    
                }
                Spacer()
            }
            .padding(.top, 115)
            VStack (spacing: 0) {

                
                //MARK:  Custom Bar Navigation for DatePicker
                VStack {
                    ZStack {
                        Rectangle()
                            .fill(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .opacity(1)
                            .frame(height: 75)
                        
                        HStack {
                            
                            Spacer()
                            
                            ZStack{
                                
                                Text(dateString)
                                    .font(.title2)
                                    .fontWeight(.light)
                                    .opacity(transClock ? 0 : 1)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .semibold))
                                    .multilineTextAlignment(.center)
                                VStack (spacing: 0){
                                    Text(selectedDateString)
                                        .font(.title2)
                                        .fontWeight(.light)
                                        .opacity(transClock ? 1 : 0)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .semibold))
                                        .multilineTextAlignment(.center)
                                    Image(systemName: "chevron.down")
                                        .padding(.top, 1)
                                        .foregroundColor(.gray)
                                        .opacity(transClock ? 1 : 0)
                                }
                                .padding(.top, 0)
                                Rectangle()
                                    .fill(Color(red: 50/255, green: 46/255, blue: 62/255))
                                    .opacity(0.001)
                                    .frame(width: 200, height: 75)
                                    .onTapGesture {
                                        withAnimation(.spring()) {
                                            transClock = false
                                        }
                                    }
                            }
                            
                            Spacer()
                            
                        }
                    }
                }
                .offset(y: transClock ? UIScreen.screenHeight * -0.36 : UIScreen.screenHeight * 0)
                .padding(.top, UIScreen.screenHeight * 0.35)
                .padding(.bottom, 5)
                
                VStack {
                    DatePicker(
                        "Froop Date",
                        selection: Binding(
                            get: { froopData.froopStartTime },
                            set: { newValue in
                                let calendar = Calendar.current
                                let dateComponents = calendar.dateComponents([.year, .month, .day], from: newValue)
                                let newDate = calendar.date(from: dateComponents)!
                                froopData.froopStartTime = newDate
                            }
                        ),
                        displayedComponents: .date)
                    .environment(\.timeZone, TimeZone.current)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .opacity(transClock ? 0 : 1)
                    .onAppear {
                        shrink = UIScreen.screenWidth - 90
                    }
                }
                .frame(maxWidth: UIScreen.screenWidth - 30)
                .padding(.top, 5)

                Spacer()

            }
            .offset(y: 100)
            TouchCaptureView {
                if !isTouched {
                    isTouched = true
                    datePicked = true
                }
            }
            .background(Color.clear)
            .opacity(isTouched ? 0.0 : 1.0)
        }
        
    }
    
    func moveToPreviousMonth() {
        PrintControl.shared.printTime("-DatePickView: Function: moveToPreviousMonth is firing")
        if Calendar.current.component(.month, from: froopData.froopStartTime) == Calendar.current.component(.month, from: Date()) {
            //Don't update the month
        } else {
            let previousMonth = Calendar.current.date(byAdding: .month, value: -1, to: froopData.froopStartTime)
            froopData.froopStartTime = previousMonth ?? froopData.froopStartTime
        }
    }
    
    func moveToNextMonth() {
        PrintControl.shared.printTime("-DatePickView: Function: moveToNextMonth is firing")
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: froopData.froopStartTime)
        froopData.froopStartTime = nextMonth ?? froopData.froopStartTime
    }
    
}


