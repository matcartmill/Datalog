/// Datadog HTTP Protocol
public enum NetworkProtocol: String {
    case http
    case https
}

/// Datadog Host Location
public enum HostLocation {
    case eu, us // swiftlint:disable:this identifier_name
}

/// Log Level
public enum LogLevel: Int, Codable {
    case emergency = 0
    case alert = 1
    case critical = 2
    case error = 3
    case warning = 4
    case notice = 5
    case info = 6
    case debug = 7
}
