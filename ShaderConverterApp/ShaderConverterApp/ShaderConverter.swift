//
//  ShaderConverter.swift
//  ShaderConverterApp
//

import Foundation
import AppKit

class ShaderConverter: ObservableObject {
    @Published var isConverting = false
    @Published var conversionResult: ConversionResult?
    
    private let executor = DockerCommandExecutor.shared
    private let fileManager = FileManager.default
    
    func convertGLSLToMetal(
        inputURL: URL,
        shaderType: ShaderType,
        oldEntryPoint: String = "main",
        newEntryPoint: String
    ) async {
        await MainActor.run {
            isConverting = true
            conversionResult = nil
        }
        
        do {
            // Check Docker availability
            try executor.checkDockerAvailability()
            try executor.checkImageExists()
            
            // Create temporary directory for intermediate files
            let tempDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            defer {
                try? fileManager.removeItem(at: tempDir)
            }
            
            // Copy input file to temp directory
            let tempInputURL = tempDir.appendingPathComponent(inputURL.lastPathComponent)
            try fileManager.copyItem(at: inputURL, to: tempInputURL)
            
            let spirvFileName = inputURL.deletingPathExtension().lastPathComponent + ".spv"
            let spirvPath = tempInputURL.deletingPathExtension().lastPathComponent + ".spv"
            
            // Step 1: Convert GLSL to SPIR-V
            let glslcCommand = "glslc \(tempInputURL.lastPathComponent) -o \(spirvPath)"
            let (glslcOutput, glslcError) = try executor.executeDockerCommand(
                sourceDir: tempDir.path,
                command: glslcCommand
            )
            
            var logs = "=== GLSL to SPIR-V Conversion ===\n"
            if !glslcError.isEmpty {
                logs += "Warnings/Errors:\n\(glslcError)\n"
            }
            logs += "Output: \(glslcOutput)\n\n"
            
            // Step 2: Convert SPIR-V to Metal
            let spirvCrossCommand = """
            spirv-cross --msl \(spirvPath) \
            --rename-entry-point \(oldEntryPoint) \(newEntryPoint) \(shaderType.rawValue)
            """
            
            let (metalCode, spirvError) = try executor.executeDockerCommand(
                sourceDir: tempDir.path,
                command: spirvCrossCommand,
                captureOutput: true
            )
            
            logs += "=== SPIR-V to Metal Conversion ===\n"
            if !spirvError.isEmpty {
                logs += "Warnings/Errors:\n\(spirvError)\n"
            }
            
            // Filter out Docker platform warning
            let filteredMetalCode = metalCode
                .components(separatedBy: "\n")
                .filter { !$0.contains("WARNING: The requested image's platform") }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            if filteredMetalCode.isEmpty {
                throw DockerCommandExecutor.DockerError.invalidOutput
            }
            
            let result = ConversionResult.success(metalCode: filteredMetalCode, logs: logs)
            
            await MainActor.run {
                self.conversionResult = result
                self.isConverting = false
            }
            
        } catch {
            let result = ConversionResult.failure(error: error.localizedDescription)
            await MainActor.run {
                self.conversionResult = result
                self.isConverting = false
            }
        }
    }
    
    func saveMetalShader(content: String, suggestedName: String) -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.init(filenameExtension: "metal")!]
        savePanel.nameFieldStringValue = suggestedName
        savePanel.canCreateDirectories = true
        
        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            return nil
        }
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Failed to save file: \(error)")
            return nil
        }
    }
}
