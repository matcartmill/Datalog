# DataLog

![Cocoapods](https://img.shields.io/cocoapods/v/Datalog) [![Build Status](https://app.bitrise.io/app/e9bbc870a31e5de5/status.svg?token=55YSJs3op5eBscvGq2Avrg&branch=master)](https://app.bitrise.io/app/e9bbc870a31e5de5) [![codecov](https://codecov.io/gh/matcartmill/Datalog/branch/master/graph/badge.svg)](https://codecov.io/gh/matcartmill/Datalog)

A modern, light-weight, and Swift 5.0 framework for logging with Datadog.

## Installation

#### CococaPods

The best way to use Datalog in your project is with Cocoapods. To do this, simply add `pod 'Datalog'` to your project's `Podfile`, 
then run `pod install`.

#### Manual

Though this method is not recommended, you can just many copy the source files from the project into your own project. 
Everything should work just as it would if you had installed via CocoaPods. I don not recommend this method of installation, 
as any new bug fixes / improvements will need to be added to your project manually. Not fun.

## Usage

### `DatalogConfiguration`

In order to initialize a `DatalogClient` you must first create a `DatalogConfiguration` instance. This configuration type contains
specific details on your project should interact with the `DatalogClient`, which in turn configures how your logs are sent to Datadog's
servers.

The initialization of the `DatalogConfiguration` is failable, in that it will `throw` under two specific conditions:

- The `apiKey` property you're attempting to set is an empty string
- The `maximumBatchCount` specified is greater than the current maximum allowed.

Both of these scenarios will result in either a `DatalogConfiguration.Error.apiKeyEmpty` error or a `DatalogConfiguration.Error.batchCountNotSupported` error.

Given that this initializer `throws`, you will either need to wrap it `do-try-catch`, or be explicit about your intent to instantiate the object with something like `let configuration = try! DatalogConfiguration(...)`.

The initializer takes a total of six (6) properties, however only the first property, the `apiKey`, is required. All of the remaining properties have default values and do not
need to be included unless you are overriding the default values.

The properties, in order, are:

- `apiKey`: **required** The API key for your Datadog application
- `hostLocation`: Whether or not the client should connect to the EU host or the US host. Default: `.us`
- `maximumBatchCount`: The maximum number of events to batch before persisting to Datadog. Default: `50`.
- `minimumLogLevel`: The minimum log level threshhold to persist logs to Datadog. Default: `.info`
- `networkProtocol`: The network protocol to use for the request. Default: `.https`
- `sourceName`: The source application name, eg: YourCoolApp. Default: `nil`

#### Example

```swift
let config = try! DatalogConfiguration("my-api-key")
let config = try! DatalogConfiguration("my-api-key", maximumBatchCount: 25)
let config = try! DatalogConfiguration("my-api-key", maximumBatchCount: 25, sourceName: "My Cool App")
```

### `DatalogClient`

The `DatalogClient` takes three (3) properties, with only one (1) property being required.

The properties, in order, are:

- `configuration`: **required** The `DatalogConfiguration` for your Datadog environment
- `fileManager`: A `FileManger` instance that will allow you to store failed logs on the device for future retrieval. Default: `.default`
- `urlSession`: A `URLSession` instance. Useful if you would like to pass a pre-configured `URLSession` for use with the Datalog client. Default: `.init(configuration: .default)`.

Additionally, the client only has two public methods: `log` and `flush`.

#### `log`

The `log` method is used for adding `DatalogMessage` types to the current batch of messages to be logged in Datadog. This method will automatically verify if the current batch has reached the configured maximum and, if it has, will trigger the submission to Datadog.

**Method signature**  
```swift
public func log(_ message: DatalogMessage, forceUpdate: Bool = false)
```
The first property of the signature is the `DatalogMessage` type, which is a representation of the log data you want to send. The second property is `forceUpdate` which, if set to `true` will **add** the `message` to the **existing** batch and submit that batch to Datadog.

#### `flush`

The `flush` method is used for manually triggering submission of the current batch of messages. Regardless of the count of items in the current batch, the batch will be submitted to Datadog and cleared. This is useful for allowing things like flushing the current batch when the app enters the background in order to send logs before the app is terminated, etc.

**Method Signature**
```swift
public func flush()
```

## Offline Support

Logs are valuable and losing that data due to a network issue isn't fun. That's why Datalog supports offline logging.

In the event that batch fails to send to Datadog, that batch will be saved to disk and will retried the next time that the `DatalogClient` is instantiated.