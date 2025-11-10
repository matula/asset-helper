import Foundation

/// Service for executing external command-line tools in a sandbox-safe manner
class ProcessRunner {

    enum ProcessError: LocalizedError {
        case binaryNotFound(String)
        case executionFailed(String)
        case timeout
        case invalidOutput

        var errorDescription: String? {
            switch self {
            case .binaryNotFound(let name):
                return "Could not find binary: \(name)"
            case .executionFailed(let message):
                return "Execution failed: \(message)"
            case .timeout:
                return "Process timed out"
            case .invalidOutput:
                return "Process produced invalid output"
            }
        }
    }

    struct ProcessResult {
        let exitCode: Int32
        let stdout: String
        let stderr: String

        var succeeded: Bool {
            exitCode == 0
        }
    }

    /// Execute a bundled tool from Resources directory
    /// - Parameters:
    ///   - toolName: Name of the tool binary (e.g., "oxipng")
    ///   - arguments: Command-line arguments
    ///   - timeout: Maximum execution time in seconds (default: 60)
    /// - Returns: Process result containing exit code and output
    func runBundledTool(
        _ toolName: String,
        arguments: [String],
        timeout: TimeInterval = 60
    ) throws -> ProcessResult {
        // Locate the bundled tool in Resources/
        // Try with subdirectory first, then fall back to direct Resources location
        var toolURL = Bundle.main.url(
            forResource: toolName,
            withExtension: nil,
            subdirectory: "Tools"
        )

        if toolURL == nil {
            // Fallback: look directly in Resources (Xcode may flatten the structure)
            toolURL = Bundle.main.url(
                forResource: toolName,
                withExtension: nil
            )
        }

        guard let toolURL = toolURL else {
            throw ProcessError.binaryNotFound(toolName)
        }

        return try runExecutable(at: toolURL, arguments: arguments, timeout: timeout)
    }

    /// Execute an executable at a specific path
    /// - Parameters:
    ///   - executableURL: URL to the executable
    ///   - arguments: Command-line arguments
    ///   - timeout: Maximum execution time in seconds
    /// - Returns: Process result containing exit code and output
    func runExecutable(
        at executableURL: URL,
        arguments: [String],
        timeout: TimeInterval = 60
    ) throws -> ProcessResult {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments

        // Create pipes for stdout and stderr
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        // Capture output
        var stdoutData = Data()
        var stderrData = Data()

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            stdoutData.append(handle.availableData)
        }

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            stderrData.append(handle.availableData)
        }

        // Execute the process
        do {
            try process.run()
        } catch {
            throw ProcessError.executionFailed(error.localizedDescription)
        }

        // Wait for completion with timeout
        let startTime = Date()
        while process.isRunning {
            if Date().timeIntervalSince(startTime) > timeout {
                process.terminate()
                throw ProcessError.timeout
            }
            usleep(100_000) // Sleep for 100ms
        }

        // Clean up pipe handlers
        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        // Read any remaining data
        stdoutData.append(stdoutPipe.fileHandleForReading.readDataToEndOfFile())
        stderrData.append(stderrPipe.fileHandleForReading.readDataToEndOfFile())

        // Convert data to strings
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        return ProcessResult(
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr
        )
    }
}
