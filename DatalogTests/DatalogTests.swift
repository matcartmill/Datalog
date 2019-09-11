import XCTest
@testable import Datalog

class DatalogConfigurationTests: XCTestCase {
    func test_failsToCreateIfAPIKeyIsEmpty() {
        let configuration = try? DatalogConfiguration("")
        XCTAssertNil(configuration)
    }
    
    func test_failsToCreateIfRequestedBatchSizeIsHigherThanTheMaximumAllowed() {
        let configuration = try? DatalogConfiguration("foo", maximumBatchCount: DatalogConfiguration.maximumBatchCountSupported + 1)
        XCTAssertNil(configuration)
    }
}

class DatalogClientTests: XCTestCase {
    func test_batchesMessagesUntilConfiguredThresholdIsMet() {
        let urlSession = FakeURLSession()
        
        let configuration = try! DatalogConfiguration("foo", maximumBatchCount: 3)
        let client = DatalogClient(configuration, urlSession: urlSession)
        
        client.log(.init(timestamp: Date().timeIntervalSinceNow, level: .notice, message: "Test 1", metadata: nil))
        XCTAssertFalse(urlSession.taskCreated)
        
        client.log(.init(timestamp: Date().timeIntervalSinceNow, level: .notice, message: "Test 2", metadata: nil))
        XCTAssertFalse(urlSession.taskCreated)
        
        client.log(.init(timestamp: Date().timeIntervalSinceNow, level: .notice, message: "Test 3", metadata: nil))
        XCTAssertTrue(urlSession.taskCreated)
    }
    
    func test_flushSendsLogsBeforeThresholdIsMet() {
        let urlSession = FakeURLSession()
        
        let configuration = try! DatalogConfiguration("foo", maximumBatchCount: 5)
        let client = DatalogClient(configuration, urlSession: urlSession)
        
        client.log(.init(timestamp: Date().timeIntervalSinceNow, level: .notice, message: "Test 1", metadata: nil))
        XCTAssertFalse(urlSession.taskCreated)
        
        client.flush()
        XCTAssertTrue(urlSession.taskCreated)
    }
    
    func test_storesFailedSubmissions() {
        let fileManager = FakeFileManager()
        let urlSession = FakeURLSession(shouldSucceed: false)
        
        let configuration = try! DatalogConfiguration("foo", maximumBatchCount: 1)
        let client = DatalogClient(configuration, fileManager: fileManager, urlSession: urlSession)
        
        XCTAssertFalse(fileManager.createDirectoryCalled)
        XCTAssertFalse(fileManager.createFileCalled)
        
        client.log(.init(timestamp: Date().timeIntervalSinceNow, level: .notice, message: "Test 1", metadata: nil))
        
        XCTAssertTrue(fileManager.createDirectoryCalled)
        XCTAssertTrue(fileManager.createFileCalled)
    }
}

class FakeFileManager: FileManager {
    var createDirectoryCalled = false
    var createFileCalled = false
    
    override func fileExists(atPath path: String) -> Bool {
        return false
    }
    
    override func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        createDirectoryCalled = true
    }
    
    override func createFile(atPath path: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]? = nil) -> Bool {
        createFileCalled = true
        return true
    }
}

class FakeURLSession: URLSession {
    
    // MARK: - Properties
    private var shouldSucceed = true
    var taskCreated = false
    
    // MARK: - Lifecycle
    
    init(shouldSucceed succeed: Bool = true) {
        self.shouldSucceed = succeed
    }
    
    // MARK: - Overrides
    
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Swift.Error?) -> Void) -> URLSessionDataTask {
        let task = MockURLSessionDataTask()
        taskCreated = true
        
        if shouldSucceed {
            completionHandler(nil, nil, nil)
        } else {
            completionHandler(nil, nil, URLError(.unknown))
        }
        
        return task
    }
}

class MockURLSessionDataTask: URLSessionDataTask {
    override func resume() {
        //
    }
}
