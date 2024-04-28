//
//  FroopFlightDataManager.swift
//  FroopProof
//
//  Created by David Reed on 4/12/24.
//

import Foundation
import Combine
import FirebaseFirestore
import CoreLocation

class FroopFlightDataManager: ObservableObject {
    static let shared = FroopFlightDataManager()
    @Published var flightDetails: [FlightDetail] = []
    @Published var airlineCodes = AirlineCodes()
    @Published var airportCodes = AirportCodes()

    
    @Published var flightNumber: String = ""
    @Published var flightNumberText: String = ""
    @Published var flightCarrierText: String = ""
    @Published var flights: [FlightDetail] = []
    @Published var departureAirport: String = ""
    @Published var arrivalAirport: String = ""
    @Published var arrivalAirportText: String = ""
    @Published var flightCarrier: String = ""
    @Published var flightNum: String = ""
    
    @Published var flightSearchResults: [String] = []
    @Published var airportSearchResults: [String] = []
    @Published var airportCode = ""
    @Published var airportName: String = "Enter Destination Airport Code"
    @Published var airlineCode: String = ""
    @Published var airlineName: String = "Enter Flight Number"
    @Published var flightNumberTextFieldValue: String = ""
    @Published var airportCodeTextFieldValue: String = ""
    
    @Published var showDestination: Bool = false
    @Published var list1Manage: Bool = false
    @Published var list2Manage: Bool = false
    @Published var disableAirportText: Bool = false
    @Published var showFlightData: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showAlert = false
    @Published var isAirportPickup: Bool = false
    @Published var locDerivedTitle: String? = nil
    @Published var locDerivedSubtitle: String? = nil

    let timezoneIdentifiers: [String: (standard: String, daylight: String)] = [
        "America/Los_Angeles": ("PST", "PDT"),  // Pacific Time
        "America/Denver": ("MST", "MDT"),       // Mountain Time
        "America/Chicago": ("CST", "CDT"),      // Central Time
        "America/New_York": ("EST", "EDT"),     // Eastern Time
        "America/Anchorage": ("AKST", "AKDT"),  // Alaska Time
        "Pacific/Honolulu": ("HST", "HST")      // Hawaii Time, no daylight saving
    ]
    
    // Constants for API access
    private let session: URLSession
    private let baseURL = URL(string: "https://aerodatabox.p.rapidapi.com")!
    private let apiKey = "7198b1b044msheacb7855ea7a8d1p13e8eejsn7c60a7bd4ad7"
    private let apiHost = "aerodatabox.p.rapidapi.com"
    private var cancellables = Set<AnyCancellable>()
    
    
    init(session: URLSession = .shared) {
        self.session = session
    }

    // Function to fetch flight details
    func fetchFlightDetails(for flightNumber: String, date: String, completion: @escaping (Result<[FlightDetail], Error>) -> Void) {
        let urlString = "https://aerodatabox.p.rapidapi.com/flights/number/\(flightNumber)/\(date)?withAircraftImage=true&withLocation=true"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "URLCreationError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("7198b1b044msheacb7855ea7a8d1p13e8eejsn7c60a7bd4ad7", forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("aerodatabox.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            print("1️⃣\(String(describing: data))")
            print("2️⃣\(String(describing: response))")
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    completion(.failure(NSError(domain: "HTTPError", code: -2, userInfo: [NSLocalizedDescriptionKey: "Non-200 HTTP response"])))
                    
                    return
                }
                
                guard let data = data else {
                    print(data as Any)
                    completion(.failure(NSError(domain: "DataError", code: -3, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                    return
                }
                
                do {
                    let results = try JSONDecoder().decode([FlightDetail].self, from: data)
                    completion(.success(results))
                } catch let DecodingError.dataCorrupted(context) {
                    print(context)
                } catch let DecodingError.keyNotFound(key, context) {
                    print("Key '\(key)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch let DecodingError.valueNotFound(value, context) {
                    print("Value '\(value)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch let DecodingError.typeMismatch(type, context)  {
                    print("Type '\(type)' mismatch:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch {
                    print("error: ", error)
                }
            }
        }.resume()
    }
    
    func fetchAddressTitleAndSubtitle(for coordinate: CLLocationCoordinate2D) async -> (title: String?, subtitle: String?) {
        // Guard to check if the coordinate is valid
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            print("Invalid coordinate")
            return (nil, nil)
        }

        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let placemark = placemarks.first
            
            let title = placemark?.name
            let subtitleComponents = [placemark?.locality, placemark?.administrativeArea]
                .compactMap { $0 }
                .joined(separator: ", ")
            
            return (title, subtitleComponents.isEmpty ? nil : subtitleComponents)
        } catch {
            print("Failed to fetch address: \(error)")
            return (nil, nil)
        }
    }
    
    func fetchFlightDetails(for flightNumber: String, date: String) async throws -> [FlightDetail] {
        let urlString = "https://aerodatabox.p.rapidapi.com/flights/number/\(flightNumber)/\(date)?withAircraftImage=true&withLocation=true"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "Invalid URL", code: -1001, userInfo: nil)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Secrets.rapidAPI, forHTTPHeaderField: "X-RapidAPI-Key")
        request.setValue("aerodatabox.p.rapidapi.com", forHTTPHeaderField: "X-RapidAPI-Host")

        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw NSError(domain: "Received non-200 HTTP response", code: -1002, userInfo: nil)
        }
        
        do {
            let decodedFlights = try JSONDecoder().decode([FlightDetail].self, from: data)
            
            await MainActor.run {
                self.isLoading = false
                self.flights = decodedFlights
                self.showFlightData = true
            }
            return decodedFlights
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            throw error
        }
    }
    
    func dateFromUTCString(_ utcString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mmZ"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.date(from: utcString)
    }
        
    func formatTime(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        return dateFormatter.string(from: date)
    }
    
    func convertToDate(from dateString: String, timeZoneIdentifier: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // Adjust this to match your API
        if let timeZone = TimeZone(identifier: timeZoneIdentifier) {
            formatter.timeZone = timeZone
        }
        return formatter.date(from: dateString)
    }
    
}








