import Foundation

/// Logging client used to persist logs
public class DataLogClient {
    
    // MARK: - Private Properties
    
    /// The queue that handles property access
    private let accessQueue = DispatchQueue(label: "DataLogAccessQueue", qos: .background, attributes: .concurrent, target: .global())
    
    /// The current batch of DataLogMessages
    private var batch: [DataLogMessage] = []
    
    /// The configuration used for the client
    private let configuration: DataLogConfiguration
    
    /// The FileManager used to store the failed requests
    private let fileManager: FileManager
    
    /// The sotrage path for failed log requests
    private var storagePath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectoryPath = paths[0]
        let documentsDirectoryUrl = URL(string: documentsDirectoryPath)!
        return documentsDirectoryUrl.appendingPathComponent("DataLog", isDirectory: true).absoluteString
    }
    
    /// The URL Session to use for the request
    private let urlSession: URLSession
    
    // MARK: - Private Methods
    
    /// Check for failed logs
    private func persistFailedLogReports() {
        let filePaths = try? fileManager.contentsOfDirectory(atPath: storagePath)
        
        guard let files = filePaths else { return }
        
        files.forEach { file in
            print("DataLog: Found file for failed log submissions. File: \(file)")
            
            let url = URL(fileURLWithPath: storagePath + file)
            let logs = try! JSONDecoder().decode([DataLogMessage].self, from: Data(contentsOf: url))
            try! fileManager.removeItem(atPath: "\(storagePath)\(file)")
            send(logs)
        }
    }
    
    /// Persist the logs in DataLog
    private func send(_ logs: [DataLogMessage]) {
        guard !logs.isEmpty else { return }
        
        let data = try! JSONEncoder().encode(logs)
        
        let networkProtocol = self.configuration.networkProtocol.rawValue
        
        var urlComponents = self.configuration.hostLocation == .us ?
            URLComponents(string: "\(networkProtocol)://http-intake.logs.DataLoghq.com")! :
            URLComponents(string: "\(networkProtocol)://http-intake.logs.DataLoghq.eu")!
        
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
                print("Error while persisting logs to DataLog. Logs will be stored and attempted to be persisted again at a later time. Message: \(error.localizedDescription)")
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
     Initializes the DataLogClient with a DataLogConfiguration.
     
     - Parameter _: The DataLogConfiguration.
     - Parameter urlSession: The URL Session to use for the request. Default: URLSession with .default Configuration
     */
    public init(_ configuration: DataLogConfiguration,
                fileManager: FileManager = .default,
                urlSession: URLSession = .init(configuration: .default)) {
        
        self.configuration = configuration
        self.fileManager = fileManager
        self.urlSession = urlSession
        
        persistFailedLogReports()
    }
    
    // MARK: - Public Methods
    
    /**
     Adds a DataLogMessage to the batch for submission.
     
     - Parameter _: The DataLogMessage to add to persistence.
     - Parameter forceUpdate: Whether persisting this message should be immediate and persist the entire active batch. Default: false
     */
    public func log(_ message: DataLogMessage, forceUpdate: Bool = false) {
        // The logic of this quard is a bit on the odd-side, however due to how DataLog handles integer-based log levels,
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
     Flush the current batch and persisting the messages to DataLog. Useful for manually pushing message before a crash or when certain
     criteria is met, such as backgrounding the application.
     */
    @objc public func flush() {
        var logs = [DataLogMessage]()
        
        accessQueue.sync { [unowned self] in
            logs = self.batch
            self.batch = []
        }
        
        send(logs)
    }
}
