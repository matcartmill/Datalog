/// A message to send to DataLog.
public struct DataLogMessage: Codable {
    /// The timestamp of when the log was created
    public let timestamp: TimeInterval
    
    /// The level of severity of the message
    public let level: DataLogLogLevel
    
    /// The content of the log message
    public let message: String
    
    /// A dictionary representation of metadata for the message
    public let metadata: [String: String]?
    
    public enum CodingKeys: String, CodingKey {
        case timestamp, message, metadata
        case level = "status"
    }
}
