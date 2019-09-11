import Foundation

/// Logging client used to persist logs
public class DatalogClient {
    
    // MARK: - Private Properties
    
    /// The queue that handles property access
    private let accessQueue = DispatchQueue(label: "DatalogAccessQueue", qos: .background, attributes: .concurrent, target: .global())
    
    /// The current batch of DatalogMessages
    private var batch: [DatalogMessage] = []
    
    /// The configuration used for the client
    private let configuration: DatalogConfiguration
    
    /// The FileManager used to store the failed requests
    private let fileManager: FileManager
    
    /// The sotrage path for failed log requests
    private var storagePath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectoryPath = paths[0]
        let documentsDirectoryUrl = URL(string: documentsDirectoryPath)!
        return documentsDirectoryUrl.appendingPathComponent("datalog", isDirectory: true).absoluteString
    }
    
    /// The URL Session to use for the request
    private let urlSession: URLSession
    
    // MARK: - Private Methods
    
    /// Check for failed logs and attempt to send them to datadog
    private func attemptToRecoverFailedLogReports() {
        let filePaths = try? fileManager.contentsOfDirectory(atPath: storagePath)
        
        guard let files = filePaths else { return }
        
        files.forEach { file in
            print("Datalog: Found file for failed log submissions. File: \(file)")
            
            let url = URL(fileURLWithPath: storagePath + file)
            let logs = try! JSONDecoder().decode([DatalogMessage].self, from: Data(contentsOf: url))
            try! fileManager.removeItem(atPath: "\(storagePath)\(file)")
            send(logs)
        }
    }
    
    /// Persist the logs in Datadog
    private func send(_ logs: [DatalogMessage]) {
        guard !logs.isEmpty else { return }
        
        let data = try! JSONEncoder().encode(logs)
        
        let networkProtocol = self.configuration.networkProtocol.rawValue
        
        var urlComponents = self.configuration.hostLocation == .us ?
            URLComponents(string: "\(networkProtocol)://http-intake.logs.datadoghq.com")! :
            URLComponents(string: "\(networkProtocol)://http-intake.logs.datadoghq.eu")!
        
        urlComponents.path = "/v1/input/\(configuration.apiKey)"
        
        if let source = configuration.sourceName {
            urlComponents.queryItems = [
                .init(name: "ddsource", value: source)
            ]
        }
        
        let url = urlComponents.url!
        
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = data
        
        let dataTask = self.urlSession.dataTask(with: urlRequest) { [weak self] (_, _, error) in
            if let error = error {
                self?.store(data)
                print("Error while persisting logs to Datadog. Logs will be stored and attempted to be persisted again at a later time. Message: \(error.localizedDescription)")
            }
        }
        dataTask.resume()
    }
    
    private func store(_ messagesData: Data) {
        let fileId = UUID().uuidString
        let fileExtension = "log"
        
        if !fileManager.fileExists(atPath: storagePath) {
            try! fileManager.createDirectory(atPath: storagePath, withIntermediateDirectories: true, attributes: nil)
        }
        
        let filePath = storagePath + "/" + fileId + "." + fileExtension
        fileManager.createFile(atPath: filePath, contents: messagesData, attributes: nil)
    }
    
    // MARK: - Public Initializer
    
    /**
     Initializes the DatalogClient with a DatalogConfiguration.
     
     - Parameter _: The DatalogConfiguration.
     - Parameter urlSession: The URL Session to use for the request. Default: URLSession with .default Configuration
     */
    public init(_ configuration: DatalogConfiguration,
                fileManager: FileManager = .default,
                urlSession: URLSession = .init(configuration: .default)) {
        
        self.configuration = configuration
        self.fileManager = fileManager
        self.urlSession = urlSession
        
        attemptToRecoverFailedLogReports()
    }
    
    // MARK: - Public Methods
    
    /**
     Adds a DatalogMessage to the batch for submission.
     
     - Parameter _: The DatalogMessage to add to persistence.
     - Parameter forceUpdate: Whether persisting this message should be immediate and persist the entire active batch. Default: false
     */
    public func log(_ message: DatalogMessage, forceUpdate: Bool = false) {
        // The logic of this quard is a bit on the odd-side, however due to how Datadog handles integer-based log levels,
        // 0 is a higher priority log than 7.
        guard message.level.rawValue <= configuration.minimumLogLevel.rawValue else { return }
        
        var shouldFlush = false
        
        accessQueue.sync { [unowned self] in
            self.batch.append(message)
            shouldFlush = self.batch.count >= self.configuration.maximumBatchCount || forceUpdate
        }
        
        if shouldFlush { flush() }
    }
    
    /**
     Flush the current batch and persisting the messages to Datalog. Useful for manually pushing message before a crash or when certain
     criteria is met, such as backgrounding the application.
     */
    public func flush() {
        var logs = [DatalogMessage]()
        
        accessQueue.sync { [unowned self] in
            logs = self.batch
            self.batch = []
        }
        
        send(logs)
    }
}
