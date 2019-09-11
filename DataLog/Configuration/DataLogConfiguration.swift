/// A configuration object to be passed to the `DataLog` instance
public struct DataLogConfiguration {
    /// The maximum number of messages that can be batched into a single request
    public static let maximumBatchCountSupported = 50
    
    /// Type for DataLogConfiguration errors
    public enum Error: Swift.Error {
        case apiKeyEmpty
        case batchCountNotSupported
    }
    
    /// The API Key of your DataLog application
    public let apiKey: String
    
    /// The host DataLog service to connect to
    public let hostLocation: DataLogHostLocation
    
    /// The maximum number of events to batch before persisting to DataLog. A maximum of 50 messages can be batched
    public let maximumBatchCount: Int
    
    /// The minimum log level threshhold to persist logs to DataLog
    public let minimumLogLevel: DataLogLogLevel
    
    /// The network protocol to use for the request
    public let networkProtocol: DataLogNetworkProtocol
    
    /// The source application name, eg: YourCoolApp
    public let sourceName: String?
    
    /**
     Initializes a DataLogConfiguration
     
     - Parameter _: The API key for your DataLog application.
     - Parameter hostLocation: Whether or not the client should connect to the EU host or the US host. Default: .us
     - Parameter maximumBatchCount: The maximum number of events to batch before persisting to DataLog. Default: 50. Maximum: 50.
     - Parameter minimumLogLevel: The minimum log level threshhold to persist logs to DataLog. Default: .info
     - Parameter networkProtocol: The network protocol to use for the request. Default: .https
     - Parameter sourceName: The source application name, eg: YourCoolApp. Default: nil
     */
    public init(_ apiKey: String,
                hostLocation: DataLogHostLocation = .us,
                maximumBatchCount: Int = DataLogConfiguration.maximumBatchCountSupported,
                minimumLogLevel: DataLogLogLevel = .info,
                networkProtocol: DataLogNetworkProtocol = .https,
                sourceName: String? = nil) throws {
        
        guard !apiKey.isEmpty else { throw Error.apiKeyEmpty }
        guard maximumBatchCount <= DataLogConfiguration.maximumBatchCountSupported else { throw Error.batchCountNotSupported }
        
        self.apiKey = apiKey
        self.hostLocation = hostLocation
        self.maximumBatchCount = maximumBatchCount
        self.minimumLogLevel = minimumLogLevel
        self.networkProtocol = networkProtocol
        self.sourceName = sourceName
    }
}
