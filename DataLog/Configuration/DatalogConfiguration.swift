/// A configuration object to be passed to the `Datalog` instance
public struct DatalogConfiguration {
    /// The maximum number of messages that can be batched into a single request
    public static let maximumBatchCountSupported = 50
    
    /// Type for DatalogConfiguration errors
    public enum Error: Swift.Error {
        case apiKeyEmpty
        case batchCountNotSupported
    }
    
    /// The API Key of your Datadog application
    public let apiKey: String
    
    /// The host Datadog service to connect to
    public let hostLocation: HostLocation
    
    /// The maximum number of events to batch before persisting to Datadog. A maximum of 50 messages can be batched
    public let maximumBatchCount: Int
    
    /// The minimum log level threshhold to persist logs to Datadog
    public let minimumLogLevel: LogLevel
    
    /// The network protocol to use for the request
    public let networkProtocol: NetworkProtocol
    
    /// The source application name, eg: YourCoolApp
    public let sourceName: String?
    
    /**
     Initializes a DatalogConfiguration
     
     - Parameter _: The API key for your Datadog application.
     - Parameter hostLocation: Whether or not the client should connect to the EU host or the US host. Default: .us
     - Parameter maximumBatchCount: The maximum number of events to batch before persisting to Datadog. Default: 50. Maximum: 50.
     - Parameter minimumLogLevel: The minimum log level threshhold to persist logs to Datadog. Default: .info
     - Parameter networkProtocol: The network protocol to use for the request. Default: .https
     - Parameter sourceName: The source application name, eg: YourCoolApp. Default: nil
     */
    public init(_ apiKey: String,
                hostLocation: HostLocation = .us,
                maximumBatchCount: Int = DatalogConfiguration.maximumBatchCountSupported,
                minimumLogLevel: LogLevel = .info,
                networkProtocol: NetworkProtocol = .https,
                sourceName: String? = nil) throws {
        
        guard !apiKey.isEmpty else { throw Error.apiKeyEmpty }
        guard maximumBatchCount <= DatalogConfiguration.maximumBatchCountSupported else { throw Error.batchCountNotSupported }
        
        self.apiKey = apiKey
        self.hostLocation = hostLocation
        self.maximumBatchCount = maximumBatchCount
        self.minimumLogLevel = minimumLogLevel
        self.networkProtocol = networkProtocol
        self.sourceName = sourceName
    }
}
