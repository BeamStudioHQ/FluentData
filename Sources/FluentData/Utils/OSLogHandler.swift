import Logging
import OSLog

struct OSLogHandler: LogHandler {
    private let logger: os.Logger
    public var logLevel: Logging.Logger.Level
    public var metadata: Logging.Logger.Metadata

    public init(
        _ logger: os.Logger,
        logLevel: Logging.Logger.Level = .trace
    ) {
        self.logLevel = logLevel
        self.metadata = [:]
        self.logger = logger
    }

    public func log(
        level: Logging.Logger.Level,
        message: Logging.Logger.Message,
        metadata: Logging.Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        if level < self.logLevel { return }

        self.logger.log(
            level: level.asOSLogLevel,
            """
            \(level.rawValue.uppercased()): \(message.description)
            \(function) at \(file):\(line)
            """
        )
    }

    @inlinable public subscript(metadataKey key: String) -> Logging.Logger.Metadata.Value? {
        get { metadata[key] }
        set { metadata[key] = newValue }
    }
}

extension Logging.Logger.Level {
    var asOSLogLevel: OSLogType {
        switch self {
        case .trace: return .debug
        case .debug: return .debug
        case .info: return .info
        case .notice: return .default
        case .warning: return .error
        case .error: return .error
        case .critical: return .fault
        }
    }
}
