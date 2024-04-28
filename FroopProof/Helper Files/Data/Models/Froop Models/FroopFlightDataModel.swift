import Foundation
import Combine
import FirebaseFirestore
import MapKit


// Main structure representing an array of flight details
struct FlightResponse: Codable {
    var flights: [FlightDetail]
}

// Detailed structure of each flight
struct FlightDetail: Codable {
    var greatCircleDistance: GreatCircleDistance
    var departure: FlightEvent
    var arrival: FlightEvent
    var lastUpdatedUtc: String
    var number: String
    var callSign: String?
    var status: String
    var codeshareStatus: String
    var isCargo: Bool
    var aircraft: AircraftDetails?
    var airline: AirlineDetails

    // Direct initializer
    init(greatCircleDistance: GreatCircleDistance, departure: FlightEvent, arrival: FlightEvent, lastUpdatedUtc: String, number: String, callSign: String?, status: String, codeshareStatus: String, isCargo: Bool, aircraft: AircraftDetails?, airline: AirlineDetails) {
        self.greatCircleDistance = greatCircleDistance
        self.departure = departure
        self.arrival = arrival
        self.lastUpdatedUtc = lastUpdatedUtc
        self.number = number
        self.callSign = callSign
        self.status = status
        self.codeshareStatus = codeshareStatus
        self.isCargo = isCargo
        self.aircraft = aircraft
        self.airline = airline
    }

    // Custom initializer for dictionary
    init?(dictionary: [String: Any]) {
        guard let greatCircleDistanceDict = dictionary["greatCircleDistance"] as? [String: Any],
              let departureDict = dictionary["departure"] as? [String: Any],
              let arrivalDict = dictionary["arrival"] as? [String: Any],
              let lastUpdatedUtc = dictionary["lastUpdatedUtc"] as? String,
              let number = dictionary["number"] as? String,
              let status = dictionary["status"] as? String,
              let codeshareStatus = dictionary["codeshareStatus"] as? String,
              let isCargo = dictionary["isCargo"] as? Bool,
              let airlineDict = dictionary["airline"] as? [String: Any]
        else {
            return nil
        }

        self.init(
            greatCircleDistance: GreatCircleDistance(dictionary: greatCircleDistanceDict)!,
            departure: FlightEvent(dictionary: departureDict)!,
            arrival: FlightEvent(dictionary: arrivalDict)!,
            lastUpdatedUtc: lastUpdatedUtc,
            number: number,
            callSign: dictionary["callSign"] as? String,
            status: status,
            codeshareStatus: codeshareStatus,
            isCargo: isCargo,
            aircraft: (dictionary["aircraft"] as? [String: Any]).flatMap { AircraftDetails(dictionary: $0) },
            airline: AirlineDetails(dictionary: airlineDict)!
        )
    }
    
    func toDictionary() -> [String: Any] {
           var dict = [String: Any]()
           dict["greatCircleDistance"] = greatCircleDistance.toDictionary()
           dict["departure"] = departure.toDictionary()
           dict["arrival"] = arrival.toDictionary()
           dict["lastUpdatedUtc"] = lastUpdatedUtc
           dict["number"] = number
           dict["callSign"] = callSign ?? ""
           dict["status"] = status
           dict["codeshareStatus"] = codeshareStatus
           dict["isCargo"] = isCargo
           dict["aircraft"] = aircraft?.toDictionary() ?? [:]
           dict["airline"] = airline.toDictionary()
           return dict
       }
    
    // Static method to create an empty instance of FlightDetail
    static func empty() -> FlightDetail {
        return FlightDetail(
            greatCircleDistance: GreatCircleDistance.empty(),
            departure: FlightEvent.empty(),
            arrival: FlightEvent.empty(),
            lastUpdatedUtc: "",
            number: "",
            callSign: nil,
            status: "",
            codeshareStatus: "",
            isCargo: false,
            aircraft: nil,
            airline: AirlineDetails.empty()
        )
    }
}


// Structure for distance details
struct GreatCircleDistance: Codable, Equatable {
    var meter: Double
    var km: Double
    var mile: Double
    var nm: Double
    var feet: Double

    enum CodingKeys: String, CodingKey {
        case meter
        case km
        case mile
        case nm
        case feet
    }

    // Default initializer
    init(meter: Double, km: Double, mile: Double, nm: Double, feet: Double) {
        self.meter = meter
        self.km = km
        self.mile = mile
        self.nm = nm
        self.feet = feet
    }
    
    // Dictionary initializer
    init?(dictionary: [String: Any]) {
        guard let meter = dictionary["meter"] as? Double,
              let km = dictionary["km"] as? Double,
              let mile = dictionary["mile"] as? Double,
              let nm = dictionary["nm"] as? Double,
              let feet = dictionary["feet"] as? Double
        else {
            return nil
        }
        
        self.init(meter: meter, km: km, mile: mile, nm: nm, feet: feet)
    }

    // Method to convert to dictionary
    func toDictionary() -> [String: Any] {
        return [
            "meter": meter,
            "km": km,
            "mile": mile,
            "nm": nm,
            "feet": feet
        ]
    }
    
    // Static method to create an empty instance with zero values
    static func empty() -> GreatCircleDistance {
        return GreatCircleDistance(meter: 0, km: 0, mile: 0, nm: 0, feet: 0)
    }

    // Equality comparison for conformance to Equatable
    static func ==(lhs: GreatCircleDistance, rhs: GreatCircleDistance) -> Bool {
        return lhs.meter == rhs.meter &&
               lhs.km == rhs.km &&
               lhs.mile == rhs.mile &&
               lhs.nm == rhs.nm &&
               lhs.feet == rhs.feet
    }
}

// Structure for departure and arrival details
struct FlightEvent: Codable {
    var airport: AirportDetails
    var scheduledTime: TimeDetail
    var revisedTime: TimeDetail?
    var runwayTime: TimeDetail?
    var terminal: String?
    var quality: [String]

    
    // Default initializer for fully specified instances
    init(airport: AirportDetails, scheduledTime: TimeDetail, revisedTime: TimeDetail?, runwayTime: TimeDetail?, terminal: String?, quality: [String]) {
        self.airport = airport
        self.scheduledTime = scheduledTime
        self.revisedTime = revisedTime
        self.runwayTime = runwayTime
        self.terminal = terminal
        self.quality = quality
    }
    
    // Initializer from dictionary for more flexible data handling
    init?(dictionary: [String: Any]) {
        guard let airportDict = dictionary["airport"] as? [String: Any],
              let scheduledTimeDict = dictionary["scheduledTime"] as? [String: Any]
        else {
            return nil
        }
        
        let revisedTimeDict = dictionary["revisedTime"] as? [String: Any]
        let runwayTimeDict = dictionary["runwayTime"] as? [String: Any]
        let terminal = dictionary["terminal"] as? String
        let quality = dictionary["quality"] as? [String] ?? []
        
        self.init(
            airport: AirportDetails(dictionary: airportDict)!,
            scheduledTime: TimeDetail(dictionary: scheduledTimeDict)!,
            revisedTime: revisedTimeDict != nil ? TimeDetail(dictionary: revisedTimeDict!) : nil,
            runwayTime: runwayTimeDict != nil ? TimeDetail(dictionary: runwayTimeDict!) : nil,
            terminal: terminal,
            quality: quality
        )
    }
    
    // Convert instance to dictionary for serialization
    func toDictionary() -> [String: Any] {
        return [
            "airport": airport.toDictionary(),
            "scheduledTime": scheduledTime.toDictionary(),
            "revisedTime": revisedTime?.toDictionary() ?? NSNull(),
            "runwayTime": runwayTime?.toDictionary() ?? NSNull(),
            "terminal": terminal ?? NSNull(),
            "quality": quality
        ]
    }
    
    // Static method to create an empty instance with default or nil values
    static func empty() -> FlightEvent {
        return FlightEvent(
            airport: AirportDetails.empty(),
            scheduledTime: TimeDetail.empty(),
            revisedTime: nil,
            runwayTime: nil,
            terminal: nil,
            quality: []
        )
    }
}

extension FlightEvent {
    var timezone: TimeZone? {
        // Assuming `local` format includes offset like "-04:00"
        let offsetPart = scheduledTime.local.suffix(6) // Extracts something like "-04:00"
        return TimeZone(secondsFromGMT: offsetInSeconds(offset: String(offsetPart)))
    }
    private func offsetInSeconds(offset: String) -> Int {
        let parts = offset.split(separator: ":")
        if parts.count == 2, let hours = Int(parts[0]), let minutes = Int(parts[1]) {
            return (hours * 3600) + (minutes * 60 * (hours.signum()))
        }
        return 0
    }
}

// Structure for airport details
struct AirportDetails: Codable {
    var icao: String
    var iata: String
    var name: String
    var shortName: String
    var municipalityName: String
    var location: Coordinate
    var countryCode: String
    var localTimeZoneIdentifier: String?  // Changed to String to store the identifier

    init(icao: String, iata: String, name: String, shortName: String, municipalityName: String, location: Coordinate, countryCode: String, localTimeZone: TimeZone?) {
        self.icao = icao
        self.iata = iata
        self.name = name
        self.shortName = shortName
        self.municipalityName = municipalityName
        self.location = location
        self.countryCode = countryCode
        self.localTimeZoneIdentifier = localTimeZone?.identifier  // Store the identifier
    }
    
    init?(dictionary: [String: Any]) {
        guard let icao = dictionary["icao"] as? String,
              let iata = dictionary["iata"] as? String,
              let name = dictionary["name"] as? String,
              let shortName = dictionary["shortName"] as? String,
              let municipalityName = dictionary["municipalityName"] as? String,
              let locationDict = dictionary["location"] as? [String: Any],
              let countryCode = dictionary["countryCode"] as? String
        else {
            return nil
        }
        
        let localTimeZoneIdentifier = dictionary["localTimeZoneIdentifier"] as? String
        let localTimeZone = localTimeZoneIdentifier.flatMap { TimeZone(identifier: $0) }
        
        guard let location = Coordinate(dictionary: locationDict) else {
            return nil
        }
        
        self.init(
            icao: icao,
            iata: iata,
            name: name,
            shortName: shortName,
            municipalityName: municipalityName,
            location: location,
            countryCode: countryCode,
            localTimeZone: localTimeZone
        )
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "icao": icao,
            "iata": iata,
            "name": name,
            "shortName": shortName,
            "municipalityName": municipalityName,
            "location": location.toDictionary(),
            "countryCode": countryCode,
            "localTimeZoneIdentifier": localTimeZoneIdentifier ?? NSNull()
        ]
    }

    
    func fetchTimeZone(for coordinate: Coordinate, completion: @escaping (Result<TimeZone, Error>) -> Void) {
        // Simulated API call
        let timeZoneId = TimeZone.knownTimeZoneIdentifiers.first { $0.contains("America") } ?? "UTC"
        guard let timeZone = TimeZone(identifier: timeZoneId) else {
            completion(.failure(NSError(domain: "TimeZoneError", code: 1, userInfo: nil)))
            return
        }
        completion(.success(timeZone))
    }

    func createAirportDetailsWithTimeZone(coordinate: Coordinate) {
        fetchTimeZone(for: coordinate) { result in
            switch result {
            case .success(let timeZone):
                let airportDetails = AirportDetails(
                    icao: "KDTW",
                    iata: "DTW",
                    name: "Detroit Metropolitan Wayne County",
                    shortName: "Metropolitan Wayne County",
                    municipalityName: "Detroit",
                    location: coordinate,
                    countryCode: "US",
                    localTimeZone: timeZone
                )
                // Use airportDetails here
                print(airportDetails)
            case .failure(let error):
                print("Error fetching timezone: \(error)")
            }
        }
    }
    
    // Static method to create an empty instance with default or nil values
    static func empty() -> AirportDetails {
        return AirportDetails(
            icao: "",
            iata: "",
            name: "",
            shortName: "",
            municipalityName: "",
            location: Coordinate(lat: 0.0, lon: 0.0),
            countryCode: "",
            localTimeZone: TimeZone.current
        )
    }
}


// Structure for coordinate details
struct Coordinate: Codable {
    var lat: Double
    var lon: Double

    // Full initializer for direct use
    init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
    
    // Initializer from dictionary for dynamic data handling
    init?(dictionary: [String: Any]) {
        guard let lat = dictionary["lat"] as? Double,
              let lon = dictionary["lon"] as? Double
        else {
            return nil
        }
        
        self.init(lat: lat, lon: lon)
    }
    
    // Convert to GeoPoint for use with location-based services
    func toDictionary() -> [String: Any] {
        ["lat": lat, "lon": lon]
    }
    
    func toGeoPoint() -> GeoPoint {
        return GeoPoint(latitude: lat, longitude: lon)
    }
    
    func toCLLocationCoordinate2D() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    // Create an empty coordinate with default values
    static func empty() -> Coordinate {
        return Coordinate(lat: 0.0, lon: 0.0)
    }
}


// Structure for time details
struct TimeDetail: Codable {
    var utc: String
    var local: String
    
    // Full initializer for direct use
    init(utc: String, local: String) {
        self.utc = utc
        self.local = local
    }
    
    // Initializer from dictionary for dynamic data handling
    init?(dictionary: [String: Any]) {
        guard let utc = dictionary["utc"] as? String,
              let local = dictionary["local"] as? String
        else {
            return nil
        }
        
        self.init(utc: utc, local: local)
    }
    
    // Serialize to dictionary for storage or network transfer
    func toDictionary() -> [String: Any] {
        return [
            "utc": utc,
            "local": local
        ]
    }

    // Create an empty TimeDetail with default values
    static func empty() -> TimeDetail {
        return TimeDetail(utc: "", local: "")
    }
}


struct AircraftDetails: Codable {
    var reg: String?   // Optional if not always present
    var modeS: String?
    var model: String
    var image: ImageDetails?  // Optional because it might not always be included

    // Full initializer for direct use
    init(reg: String?, modeS: String?, model: String, image: ImageDetails?) {
        self.reg = reg
        self.modeS = modeS
        self.model = model
        self.image = image
    }
    
    // Initializer from dictionary for dynamic data handling
    init?(dictionary: [String: Any]) {
        let reg = dictionary["reg"] as? String
        let modeS = dictionary["modeS"] as? String
        let model = dictionary["model"] as? String ?? ""
        let image = (dictionary["image"] as? [String: Any]).flatMap { ImageDetails(dictionary: $0) }
        
        self.init(reg: reg, modeS: modeS, model: model, image: image)
    }
    
    // Serialize to dictionary for storage or network transfer
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "model": model
        ]
        
        dict["reg"] = reg ?? NSNull()
        dict["modeS"] = modeS ?? NSNull()
        if let image = image {
            dict["image"] = image.toDictionary()
        } else {
            dict["image"] = NSNull()
        }
        
        return dict
    }

    // Create an empty AircraftDetails with default values
    static func empty() -> AircraftDetails {
        return AircraftDetails(reg: nil, modeS: nil, model: "", image: nil)
    }
}


struct ImageDetails: Codable {
    var url: String
    var webUrl: String
    var author: String
    var title: String
    var description: String
    var license: String
    var htmlAttributions: [String]
    
    // Full initializer for direct use
    init(url: String, webUrl: String, author: String, title: String, description: String, license: String, htmlAttributions: [String]) {
        self.url = url
        self.webUrl = webUrl
        self.author = author
        self.title = title
        self.description = description
        self.license = license
        self.htmlAttributions = htmlAttributions
    }
    
    // Initializer from dictionary for dynamic data handling
    init?(dictionary: [String: Any]) {
        guard let url = dictionary["url"] as? String,
              let webUrl = dictionary["webUrl"] as? String,
              let author = dictionary["author"] as? String,
              let title = dictionary["title"] as? String,
              let description = dictionary["description"] as? String,
              let license = dictionary["license"] as? String,
              let htmlAttributions = dictionary["htmlAttributions"] as? [String]
        else {
            return nil
        }
        
        self.init(url: url, webUrl: webUrl, author: author, title: title, description: description, license: license, htmlAttributions: htmlAttributions)
    }
    
    // Serialize to dictionary for storage or network transfer
    func toDictionary() -> [String: Any] {
        return [
            "url": url,
            "webUrl": webUrl,
            "author": author,
            "title": title,
            "description": description,
            "license": license,
            "htmlAttributions": htmlAttributions
        ]
    }

    // Create an empty ImageDetails with default values
    static func empty() -> ImageDetails {
        return ImageDetails(url: "", webUrl: "", author: "", title: "", description: "", license: "", htmlAttributions: [])
    }
}


struct AirlineDetails: Codable {
    var name: String
    var iata: String
    var icao: String
    
    // Full initializer for direct use
    init(name: String, iata: String, icao: String) {
        self.name = name
        self.iata = iata
        self.icao = icao
    }
    
    // Initializer from dictionary for dynamic data handling
    init?(dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
              let iata = dictionary["iata"] as? String,
              let icao = dictionary["icao"] as? String
        else {
            return nil
        }
        
        self.init(name: name, iata: iata, icao: icao)
    }
    
    // Serialize to dictionary for storage or network transfer
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "iata": iata,
            "icao": icao
        ]
    }

    // Create an empty AirlineDetails with default values
    static func empty() -> AirlineDetails {
        return AirlineDetails(name: "", iata: "", icao: "")
    }
}
