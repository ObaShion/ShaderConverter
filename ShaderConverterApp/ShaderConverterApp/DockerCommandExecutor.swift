//
//  DockerCommandExecutor.swift
//  ShaderConverterApp
//

import Foundation

class DockerCommandExecutor {
    static let shared = DockerCommandExecutor()
    
    private init() {}
    
    enum DockerError: LocalizedError {
        case dockerNotAvailable
        case imageNotFound
        case commandFailed(String)
        case invalidOutput
        
        var errorDescription: String? {
            switch self {
            case .dockerNotAvailable:
                return "Docker is not available. Please install Docker or OrbStack."
            case .imageNotFound:
                return "shader_converter_toolkit Docker image not found. Please build it first."
            case .commandFailed(let message):
                return "Docker command failed: \(message)"
            case .invalidOutput:
                return "Invalid output from Docker command"
            }
        }
    }
    
    func checkDockerAvailability() throws {
        let result = try executeShellCommand("which docker")
        if result.output.isEmpty {
            throw DockerError.dockerNotAvailable
        }
    }
    
    func checkImageExists() throws {
        let result = try executeShellCommand("docker images -q shader_converter_toolkit")
        if result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw DockerError.imageNotFound
        }
    }
    
    func executeDockerCommand(
        sourceDir: String,
        command: String,
        captureOutput: Bool = false
    ) throws -> (output: String, error: String) {
        let dockerCommand = """
        docker run -it --rm \
        --mount type=bind,src=\(sourceDir),target=/src \
        --workdir /src \
        shader_converter_toolkit \
        \(command)
        """
        
        let result = try executeShellCommand(dockerCommand)
        return (result.output, result.error)
    }
    
    private func findDockerPath() -> String? {
        let commonPaths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/usr/bin/docker",
            "~/.orbstack/bin/docker"
        ]
        
        for path in commonPaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if FileManager.default.isExecutableFile(atPath: expandedPath) {
                return expandedPath
            }
        }
        
        return nil
    }
    
    private func executeShellCommand(_ command: String) throws -> (output: String, error: String) {
        let process = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-l", "-c", command]
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Set up environment with common paths
        var environment = ProcessInfo.processInfo.environment
        let additionalPaths = [
            "/usr/local/bin",
            "/opt/homebrew/bin",
            "/usr/bin",
            NSString(string: "~/.orbstack/bin").expandingTildeInPath
        ]
        
        let currentPath = environment["PATH"] ?? ""
        let newPath = (additionalPaths + [currentPath]).joined(separator: ":")
        environment["PATH"] = newPath
        process.environment = environment
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            
            if process.terminationStatus != 0 && !error.isEmpty {
                throw DockerError.commandFailed(error)
            }
            
            return (output, error)
        } catch let error as DockerError {
            throw error
        } catch {
            throw DockerError.commandFailed(error.localizedDescription)
        }
    }
}
