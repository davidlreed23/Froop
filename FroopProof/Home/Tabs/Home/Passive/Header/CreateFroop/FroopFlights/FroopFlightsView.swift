//
//  FroopFlightsView.swift
//  FroopProof
//
//  Created by David Reed on 4/12/24.
//

import SwiftUI
import Combine
import MapKit
import CoreLocation


struct FroopFlightsView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var printControl = PrintControl.shared
    @ObservedObject var appStateManager = AppStateManager.shared
    @ObservedObject var froopData = FroopData.shared
    @ObservedObject var changeView = ChangeView.shared
    @ObservedObject var flightManager = FroopFlightDataManager.shared
    @ObservedObject var timeZoneManager = TimeZoneManager.shared
    
    @State private var keyboard: UIKeyboardType = .default
    @State var currentFocus: TextFieldFocus = .none
    @State private var showInvalidFlightAlert = false
    @State var animationAmount = 1.0
    @State private var isEditing = false
    
    var onFroopNamed: (() -> Void)?
    
    var body: some View {
        
        ZStack {
            BackgroundLayer()
            if flightManager.flightNum != "" {
                FlightFetchButton()
            }
            FlightDataDisplay()
        }
        //        .padding(.top, UIScreen.screenHeight * 0.075)
        .modifier(KeyboardAdaptive())
        .alert(isPresented: $flightManager.showAlert) {
            Alert(title: Text("Error"), message: Text(flightManager.errorMessage), dismissButton: .default(Text("OK")))
        }
    }
}


private func formatDateForJSON(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "YYYY-MM-dd"  // Set the date format to what your API expects
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)  // Adjust if your API expects the date in UTC
    return dateFormatter.string(from: date)
}

struct FlightDataDisplay: View {
    @ObservedObject var flightManager = FroopFlightDataManager.shared
    @ObservedObject var timeZoneManager = TimeZoneManager.shared
    @ObservedObject var froopData = FroopData.shared
    @ObservedObject var changeView = ChangeView.shared
    
    @FocusState private var focusedField: FieldFocus?
    @FocusState private var enumFlightCarrier: Bool
    @FocusState private var enumFlightNum: Bool
    @FocusState private var enumAirport: Bool
    
    var body: some View {
        Rectangle()
            .foregroundColor(flightManager.showFlightData ? .black : .clear)
            .opacity(0.25)
        
        VStack(spacing: 20) {
            VStack() {
                Text("FLIGHT DETIALS")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.white.opacity(1))
                HStack {
                    Text(flightManager.flightCarrier.count == 2 && flightManager.flightSearchResults == [] ? "UNRECOGNIZED" : "FLIGHT NUMBER \(flightManager.flightNumberText)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .padding(.top, UIScreen.screenHeight * 0.01)
                    Spacer()
                }
                ZStack {
                    HStack(spacing: UIScreen.screenWidth * 0.01 ) {
                        Spacer()
                        ZStack {
                            TextField("", text: $flightManager.flightCarrier)
                                .keyboardType(.default)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 24))
                                .multilineTextAlignment(.center)
                                .fontWeight(.light)
                                .focused($enumFlightCarrier)
                                .onReceive(Just(flightManager.flightCarrier)) { newValue in
                                    let filtered = newValue.uppercased().filter { "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".contains($0) }
                                    if filtered != newValue || filtered.count > 2 {
                                        self.flightManager.flightCarrier = String(filtered.prefix(2))
                                    }
                                }
                                .onChange(of: flightManager.flightCarrier.count) { oldValue, newValue in
                                    if newValue < 2 {
                                        flightManager.list1Manage = false
                                    }
                                }
                                .frame(width: UIScreen.screenWidth * 0.19)
                            Text("AA")
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 18))
                                .foregroundStyle(flightManager.flightCarrier == "" ? Color.gray.opacity(0.75) : .clear)
                                .fontWeight(.light)
                                .frame(width: UIScreen.screenWidth * 0.19)
                                .onAppear {
                                    enumFlightCarrier = true
                                }
                        }
                        
                        ZStack(alignment: .leading) {
                            TextField("", text: $flightManager.flightNum)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.system(size: 24))
                                .fontWeight(.light)
                                .focused($enumFlightNum)
                                .frame(width: UIScreen.screenWidth * 0.6)
                            VStack (alignment: .leading) {
                                Text("0000")
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.system(size: 18))
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(flightManager.flightCarrier == "" ? Color.gray.opacity(0.75) : .clear)
                                    .fontWeight(.light)
                                    .frame(width: 75)
                            }
                        }
                        Spacer()
                    }
                    RoundedRectangle(cornerRadius: 5)
                        .background(.clear)
                        .foregroundColor(.clear)
                        .frame(height: 50)
                        .border(Color(red: 33/255, green: 31/255, blue: 39/255))
                }
                .onTapGesture {
                    flightManager.list1Manage = true
                    flightManager.flightNum = ""
                    flightManager.showDestination = false
                    enumFlightCarrier = true
                    flightManager.flightCarrier = ""
                    flightManager.flightNumberText = ""
                    flightManager.flightCarrierText = ""
                    flightManager.arrivalAirportText = ""
                    flightManager.arrivalAirport = ""
                    flightManager.disableAirportText = false
                    flightManager.airportSearchResults = []
                    
                }
                .onChange(of: flightManager.flightCarrier) { oldValue, newValue in
                    withAnimation {
                        if newValue.count == 2 {  // Start searching from 2 characters
                            flightManager.flightSearchResults = flightManager.airlineCodes.searchAirlines(query: newValue)
                        } else {
                            flightManager.flightSearchResults = []
                        }
                    }
                }
                .onChange(of: flightManager.flightNum) { oldValue, newValue in
                    if newValue.count >= 4 {
                        enumAirport = true
                        flightManager.list2Manage = false
                    }
                }
                if !flightManager.flightSearchResults.isEmpty && !flightManager.list1Manage{
                    ScrollView(showsIndicators: false) {
                        ForEach(flightManager.flightSearchResults, id: \.self) { result in
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .frame(height: 50)
                                    .background(.clear)
                                
                                Text(result)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .background(Color.clear)
                            }
                            .padding(.bottom, 1)
                            .frame(maxHeight: 65)
                            .onTapGesture {
                                enumFlightCarrier = false
                                enumFlightNum = true
                                flightManager.flightNumberText = String(result)
                                flightManager.list1Manage = true
                            }
                        }
                    }
                    .frame(minHeight: 0, maxHeight: 200) // Control the height of the drop-down list
                    .transition(.flipFromBottom(duration: 0.25).combined(with: .opacity))
                    .animation(.easeOut, value: flightManager.flightSearchResults.isEmpty)
                    .background(Color.clear)
                    
                }
                
            }
            .padding(.top, UIScreen.screenHeight * 0.05)
            
            VStack() {
                HStack {
                    Text("DESTINATION: \(flightManager.arrivalAirportText)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.75))
                    Spacer()
                }
                
                TextField("Enter Airport", text: $flightManager.arrivalAirport)
                    .keyboardType(.default)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 24))
                    .fontWeight(.light)
                    .focused($enumAirport)
                    .frame(width: UIScreen.screenWidth * 0.8, height: 40)
                    .disabled(flightManager.disableAirportText)
                    .onReceive(Just(flightManager.arrivalAirport)) { newValue in
                        let filtered = newValue.uppercased()
                        if filtered != newValue {
                            self.flightManager.arrivalAirport = filtered
                        }
                    }
                    .onChange(of: flightManager.arrivalAirport) { oldValue, newValue in
                        withAnimation {
                            if newValue.count >= 3 {
                                flightManager.airportSearchResults = flightManager.airportCodes.searchAirports(query: newValue)
                            } else {
                                flightManager.airportSearchResults = []
                            }
                            if newValue.count == 0 {
                                flightManager.arrivalAirportText = ""
                            }
                            
                        }
                    }
                
                if !flightManager.airportSearchResults.isEmpty && flightManager.list1Manage == false {
                    ScrollView(showsIndicators: false) {
                        ForEach(flightManager.airportSearchResults, id: \.self) { airport in
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .background(.clear)
                                
                                Text(airport)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.white)
                                    .background(Color.clear)
                            }
                            .padding(.bottom, 1)
                            .frame(width: UIScreen.screenWidth * 0.8, height: 40)
                            .frame(maxHeight: 45)
                            .onTapGesture {
                                flightManager.flightNumber = "\(flightManager.flightCarrier)\(flightManager.flightNum)"
                                flightManager.arrivalAirport = String(airport.prefix(3))
                                flightManager.arrivalAirportText = String(airport)
                                flightManager.list2Manage = true
                                flightManager.disableAirportText = true
                                print("Flight Number: \(flightManager.flightNumber)")
                                //                                    print("Date: \(flightManager.formatDateForJSON(date: flightManager.froopData.froopStartTime))")
                                print("Destination: \(flightManager.arrivalAirport)")
                            }
                        }
                    }
                    .frame(maxHeight: UIScreen.screenHeight * 0.2)  // Limiting the size of the dropdown
                    .transition(.flipFromBottom(duration: 0.25).combined(with: .opacity))
                    .animation(.easeOut, value: flightManager.airportSearchResults.isEmpty)
                }
            }
            .onChange(of: flightManager.flightNum) { oldValue, newValue in
                if newValue.count > 0 {
                    withAnimation(.smooth) {
                        flightManager.showDestination = false
                    }
                } else {
                    flightManager.showDestination = false
                }
            }
            .opacity(flightManager.showDestination ? 1 : 0)
            .padding(.top, 0)
            .background(.clear)
            
            Spacer()
        }
        .frame(width: UIScreen.screenWidth * 0.8)
        .padding(.leading, UIScreen.screenWidth * 0.01)
        .padding(.trailing, UIScreen.screenWidth * 0.01)
        .blur(radius: flightManager.showFlightData ? 5 : 0)
        
        if flightManager.showFlightData {
            VStack {
                if flightManager.showFlightData {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundColor(.offWhite)
                            .onTapGesture {
                                print("Printing Departure Date")
                                print(flightManager.dateFromUTCString(flightManager.flights[safe: 0]?.departure.scheduledTime.utc ?? "") as Any)
                                print("Printing Arrival Date")
                                print(flightManager.dateFromUTCString(flightManager.flights[safe: 0]?.arrival.scheduledTime.utc ?? "") as Any)
                            }
                        
                        VStack {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(flightManager.flights[0].departure.airport.iata)
                                        .font(.system(size: 32))
                                        .fontWeight(.bold)
                                    Text(flightManager.flights[0].departure.airport.municipalityName)
                                }
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .padding(.leading, 20)
                                
                                Spacer()
                                
                                VStack(alignment: .center) {
                                    Image(systemName: "airplane.departure")
                                        .foregroundColor(Color(red: 100/255, green: 155/255, blue: 255/255))
                                        .font(.system(size: 24))
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text(flightManager.flights[0].arrival.airport.iata)
                                        .font(.system(size: 32))
                                        .fontWeight(.bold)
                                    Text(flightManager.flights[0].arrival.airport.municipalityName)
                                }
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .padding(.trailing, 20)
                            }
                            .padding(.top, 25)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("\(flightManager.flights[0].airline.name) Airlines")
                                            .font(.system(size: 20))
                                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                        
                                        Spacer()
                                        
                                        Text(flightManager.flights[0].number)
                                            .font(.system(size: 16))
                                            .fontWeight(.bold)
                                            .foregroundColor(Color(red: 249/255, green: 0/255, blue: 98/255))
                                    }
                                    Text(flightManager.flights[0].aircraft?.model ?? "Unknown Aircraft Model")
                                        .font(.system(size: 14))
                                        .fontWeight(.regular)
                                }
                                .frame(height: 35)
                                
                            }
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                            .padding(.top, 10)
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                            
                            HStack {
                                Spacer()
                                Text(timeZoneManager.formatDate(for: froopData.froopStartTime, in: nil, formatType: DateForm.froopFlightView))
                                Spacer()
                            }
                            .padding(.top, 20)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Departing")
                                        .font(.system(size: 16))
                                        .fontWeight(.semibold)
                                    
                                    if let utcDate = flightManager.dateFromUTCString(flightManager.flights[safe: 0]?.departure.scheduledTime.utc ?? "") {
                                        let adjustedDate = DateUtilities.adjustDateByOffsets(date: utcDate, dstOffset: timeZoneManager.departingTimeZone?.dstOffset, rawOffset: timeZoneManager.departingTimeZone?.rawOffset)
                                        Text("\(timeZoneManager.formatTime(from: utcDate, timeZoneIdentifier: timeZoneManager.departingTimeZone?.timeZoneId ?? TimeZone.current.identifier))")
                                            .font(.system(size: 14))
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(red: 100/255, green: 155/255, blue: 255/255))
                                    } else {
                                        Text("Time not available")
                                    }
                                    
                                    if let departingTimeZone = timeZoneManager.departingTimeZone {
                                        Text("\(departingTimeZone.timeZoneName)")
                                            .font(.system(size: 12))
                                            .fontWeight(.regular)
                                    }
                                }
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .padding(.leading, 20)
                                
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 5) {
                                    Text("Arriving")
                                        .font(.system(size: 16))
                                        .fontWeight(.semibold)
                                    
                                    if let utcDate = flightManager.dateFromUTCString(flightManager.flights[safe: 0]?.arrival.scheduledTime.utc ?? "") {
                                        let adjustedDate = DateUtilities.adjustDateByOffsets(date: utcDate, dstOffset: timeZoneManager.arrivingTimeZone?.dstOffset, rawOffset: timeZoneManager.arrivingTimeZone?.rawOffset)
                                        Text("\(timeZoneManager.formatTime(from: utcDate, timeZoneIdentifier: timeZoneManager.arrivingTimeZone?.timeZoneId ?? TimeZone.current.identifier))")
                                            .font(.system(size: 14))
                                            .fontWeight(.semibold)
                                            .foregroundColor(Color(red: 100/255, green: 155/255, blue: 255/255))
                                    } else {
                                        Text("Time not available")
                                    }
                                    
                                    if let arrivingTimeZone = timeZoneManager.arrivingTimeZone {
                                        Text("\(arrivingTimeZone.timeZoneName)")
                                            .font(.system(size: 12))
                                            .fontWeight(.regular)
                                    }
                                }
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                .padding(.trailing, 20)
                                .onAppear {
                                    if let departure = flightManager.flights[safe: 0]?.departure,
                                       let arrival = flightManager.flights[safe: 0]?.arrival {
                                        timeZoneManager.updateTimeZonesForFlight(
                                            departureLat: departure.airport.location.lat,
                                            departureLon: departure.airport.location.lon,
                                            arrivalLat: arrival.airport.location.lat,
                                            arrivalLon: arrival.airport.location.lon,
                                            apiKey: Secrets.googleTimeZoneAPI
                                        )
                                    }
                                }
                            }
                            .padding(.top, 10)
                            
                            Spacer()
                            
                            VStack (spacing: 2) {
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                    .padding(.leading, 5)
                                    .padding(.trailing, 5)
                                    .padding(.top, 25)
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                    .padding(.leading, 25)
                                    .padding(.trailing, 25)
                            }
                            .opacity(0.5)
                            
                            Spacer()
                            
                            HStack {
                                VStack(alignment: .center) {
                                    Text("Is this your Flight?")
                                        .font(.system(size: 22))
                                        .fontWeight(.bold)
                                }
                                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                
                            }
                            .padding(.top, 10)
                            
                            HStack {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .frame(width: UIScreen.screenWidth * 0.25, height: 50)
                                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                    
                                    Text("Change")
                                        .font(.system(size: 16))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .onTapGesture {
                                    flightManager.showFlightData = false
                                }
                                
                                Spacer()
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .frame(width: UIScreen.screenWidth * 0.25, height: 50)
                                        .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                                    
                                    Text("Yes")
                                        .font(.system(size: 16))
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                                .onTapGesture {
                                    froopData.flightData = flightManager.flights[0]
                                    froopData.froopName = "Pick up \(MyData.shared.firstName) from Airport"
                                    froopData.froopStartTime = flightManager.convertToDate(from: flightManager.flights[0].arrival.scheduledTime.local, timeZoneIdentifier: "") ?? Date()
                                    froopData.froopLocationtitle = flightManager.locDerivedTitle ?? ""
                                    froopData.froopLocationsubtitle = flightManager.locDerivedSubtitle ?? ""
                                    froopData.froopDuration = 7200
                                    print("FroopData.locationTitle: \(froopData.froopLocationtitle)")
                                    print("FroopData.locationSubtitle: \(froopData.froopLocationsubtitle)")
                                    print("flightManager.title: \(String(describing: flightManager.locDerivedTitle))")
                                    print("flightManager.subtitle: \(String(describing: flightManager.locDerivedSubtitle))")

                                    changeView.pageNumber = 4
                                    
                                }
                                
                            }
                            .padding(.top, 15)
                            .padding(.leading, 50)
                            .padding(.trailing, 50)
                            .padding(.bottom, 50)
                            
                            Spacer()
                        }
                    }
                    .frame(width: UIScreen.screenWidth * 0.8, height: UIScreen.screenHeight * 0.45)
                    
                }
                Spacer()
            }
            .padding(.top, UIScreen.screenHeight * 0.15)
        }
    }
}

struct FlightFetchButton: View {
    @ObservedObject var flightManager = FroopFlightDataManager.shared
    @ObservedObject var froopData = FroopData.shared
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    flightManager.flightNumber = "\(flightManager.flightCarrier)\(flightManager.flightNum)"
                    
                    Task {
                        do {
                            let flightDetails = try await flightManager.fetchFlightDetails(for: flightManager.flightNumber, date: formatDateForJSON(date: froopData.froopStartTime))
                            // Use the result (flightDetails) as needed
                            
                            // Further asynchronous actions regarding flightDetails can continue here
                            if flightManager.isAirportPickup {
                                let airportCoordinate = CLLocationCoordinate2D(latitude: flightDetails[0].arrival.airport.location.lat, longitude: flightDetails[0].arrival.airport.location.lon)
                                froopData.froopLocationCoordinate = airportCoordinate
                                let (title, subtitle) = await flightManager.fetchAddressTitleAndSubtitle(for: airportCoordinate)
                                await MainActor.run {
                                    flightManager.locDerivedTitle = title
                                    flightManager.locDerivedSubtitle = subtitle
                                }
                            }
                        } catch {
                            print("An error occurred: \(error.localizedDescription)")
                            // Handle errors such as network issues or decoding failures
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .frame(width: 150, height: 40)
                            .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
                        Text("Find Flight")
                            .font(.system(size: 20))
                            .foregroundColor(Color.white)
                            .fontWeight(.thin)
                    }
                }
                .disabled(flightManager.flightNum.isEmpty)
                .padding(.top, UIScreen.screenHeight * 0.25)
                .padding(.trailing, UIScreen.screenWidth * 0.1)
                
            }
            Spacer()
        }
    }
}

struct BackgroundLayer: View {
    @ObservedObject var flightManager = FroopFlightDataManager.shared
    @ObservedObject var froopData = FroopData.shared
    
    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(Color(red: 50/255, green: 46/255, blue: 62/255))
            VStack {
                Rectangle()
                    .foregroundColor(Color(red: 33/255, green: 31/255, blue: 39/255))
                Spacer()
            }
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 25)
                    .foregroundColor(Color(red: 33/255, green: 31/255, blue: 39/255))
                    .frame(height: UIScreen.screenHeight * 0.4)
                RoundedRectangle(cornerRadius: 25)
                    .foregroundColor(Color(red: 48/255, green: 46/255, blue: 55/255))
                    .frame(height: UIScreen.screenHeight * 0.6)
            }
        }
    }
}
