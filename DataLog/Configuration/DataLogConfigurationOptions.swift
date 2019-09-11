/// DataLog HTTP Protocol
public enum DataLogNetworkProtocol: String {
    case http
    case https
}

/// DataLog Host Location
public enum DataLogHostLocation {
    case eu, us // swiftlint:disable:this identifier_name
}

/// Log Level
public enum DataLogLogLevel: Int, Codable {
    case emergency = 0
    case alert = 1
    case critical = 2
    case error = 3
    case warning = 4
    case notice = 5
    case info = 6
    case debug = 7
}
