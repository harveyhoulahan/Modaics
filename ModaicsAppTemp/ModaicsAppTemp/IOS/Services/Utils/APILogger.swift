//
//  APILogger.swift
//  Modaics
//
//  Debug logging utility for API requests and responses
//

import Foundation
import os.log

// MARK: - Log Level

enum LogLevel: Int, Comparable {
    case verbose = 0
    case debug = 1
    case info = 2
    case warning = 3
    case error = 4
    case none = 5
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var osLogType: OSLogType {
        switch self {
        case .verbose, .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .none: return .fault
        }
    }
    
    var emoji: String {
        switch self {
        case .verbose: return "📝"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .none: return "🚫"
        }
    }
}

// MARK: - API Logger

final class APILogger {
    
    // MARK: - Shared Instance
    
    static let shared = APILogger()
    
    // MARK: - Properties
    
    var minimumLogLevel: LogLevel = {
        #if DEBUG
        return .verbose
        #else
        return .error
        #endif
    }()
    
    var logToConsole: Bool = true
    var logToFile: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    private let logger = Logger(subsystem: "com.modaics.api", category: "networking")
    private let dateFormatter: DateFormatter
    private var logFileURL: URL?
    
    // MARK: - Initialization
    
    private init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        if logToFile {
            setupLogFile()
        }
    }
    
    // MARK: - Setup
    
    private func setupLogFile() {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let logsDirectory = documentsPath.appendingPathComponent("APILogs", isDirectory: true)
        
        do {
            try fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true)
            let dateString = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            logFileURL = logsDirectory.appendingPathComponent("api_\(dateString).log")
        } catch {
            print("Failed to create logs directory: \(error)")
        }
    }
    
    // MARK: - Logging Methods
    
    func log(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard level >= minimumLogLevel else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "[\(timestamp)] \(level.emoji) [\(fileName):\(line)] \(function): \(message)"
        
        // Log to OSLog
        logger.log(level: level.osLogType, "\(logMessage, privacy: .public)")
        
        // Log to console
        if logToConsole {
            print(logMessage)
        }
        
        // Log to file
        if logToFile, let logFileURL = logFileURL {
            writeToFile(logMessage, fileURL: logFileURL)
        }
    }
    
    func verbose(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .verbose, file: file, function: function, line: line)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    // MARK: - Request/Response Logging
    
    func logRequest(
        _ request: URLRequest,
        endpoint: String,
        body: Data? = nil
    ) {
        guard minimumLogLevel <= .debug else { return }
        
        var message = "\n📤 REQUEST: \(request.httpMethod ?? "GET") \(endpoint)"
        message += "\n   URL: \(request.url?.absoluteString ?? "unknown")"
        
        if let headers = request.allHTTPHeaderFields {
            let sanitizedHeaders = headers.filter { !$0.key.lowercased().contains("authorization") }
            message += "\n   Headers: \(sanitizedHeaders)"
        }
        
        if let body = body,
           let json = try? JSONSerialization.jsonObject(with: body),
           let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
           let string = String(data: data, encoding: .utf8) {
            message += "\n   Body: \(string)"
        }
        
        debug(message)
    }
    
    func logResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?,
        endpoint: String
    ) {
        guard minimumLogLevel <= .debug else { return }
        
        var message = "\n📥 RESPONSE: \(endpoint)"
        
        if let httpResponse = response as? HTTPURLResponse {
            let statusEmoji = (200...299).contains(httpResponse.statusCode) ? "✅" : "❌"
            message += "\n   Status: \(statusEmoji) \(httpResponse.statusCode)"
        }
        
        if let error = error {
            message += "\n   Error: \(error.localizedDescription)"
        }
        
        if let data = data {
            if let json = try? JSONSerialization.jsonObject(with: data),
               let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let string = String(data: prettyData, encoding: .utf8) {
                let preview = String(string.prefix(1000))
                message += "\n   Body: \(preview)\(string.count > 1000 ? "..." : "")"
            } else {
                message += "\n   Body: \(data.count) bytes"
            }
        }
        
        debug(message)
    }
    
    func logError(_ error: Error, endpoint: String) {
        var message = "\n❌ ERROR: \(endpoint)"
        message += "\n   Description: \(error.localizedDescription)"
        
        if let apiError = error as? APIError {
            message += "\n   API Error: \(apiError)"
        }
        
        error(message)
    }
    
    // MARK: - File Operations
    
    private func writeToFile(_ message: String, fileURL: URL) {
        let logEntry = message + "\n"
        
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
                    _ = fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    try? fileHandle.close()
                }
            } else {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }
    
    // MARK: - Log Management
    
    func clearLogs() {
        guard let logFileURL = logFileURL else { return }
        
        do {
            try FileManager.default.removeItem(at: logFileURL)
            info("Cleared log file")
        } catch {
            warning("Failed to clear log file: \(error)")
        }
    }
    
    func exportLogs() -> URL? {
        guard let logFileURL = logFileURL,
              FileManager.default.fileExists(atPath: logFileURL.path) else {
            return nil
        }
        
        return logFileURL
    }
    
    func getLogFileSize() -> Int64? {
        guard let logFileURL = logFileURL else { return nil }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: logFileURL.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
}

// MARK: - Convenience Extensions

extension APILogger {
    
    /// Log a successful operation
    func success(_ message: String) {
        info("✅ \(message)")
    }
    
    /// Log a network operation
    func network(_ message: String) {
        debug("🌐 \(message)")
    }
    
    /// Log cache operations
    func cache(_ message: String) {
        verbose("💾 \(message)")
    }
    
    /// Log authentication operations
    func auth(_ message: String) {
        debug("🔐 \(message)")
    }
}
