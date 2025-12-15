//
//  ContentView.swift
//  ShaderConverterApp
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var converter = ShaderConverter()
    @State private var selectedFile: URL?
    @State private var selectedShaderType: ShaderType = .fragment
    @State private var oldEntryPoint = "main"
    @State private var newEntryPoint = "main"
    @State private var showFileImporter = false
    
    var body: some View {
        HSplitView {
            // Left Panel - Input
            VStack(spacing: 0) {
                // Header
                headerView
                
                Divider()
                
                // File Drop Zone
                fileDropZone
                
                Divider()
                
                // Configuration
                configurationView
                
                Divider()
                
                // Convert Button
                convertButtonView
            }
            .frame(minWidth: 350, idealWidth: 400)
            
            // Right Panel - Output
            VStack(spacing: 0) {
                // Output Header
                outputHeaderView
                
                Divider()
                
                // Output Display
                outputView
            }
            .frame(minWidth: 400, idealWidth: 600)
        }
        .frame(minWidth: 800, minHeight: 600)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [
                UTType(filenameExtension: "frag")!,
                UTType(filenameExtension: "vert")!,
                UTType(filenameExtension: "glsl")!
            ],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                selectedFile = url
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Shader Converter")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("Convert GLSL to Metal Shading Language")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - File Drop Zone
    private var fileDropZone: some View {
        VStack(spacing: 16) {
            if let file = selectedFile {
                // Selected File
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text(file.lastPathComponent)
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(file.path)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Button("Change File") {
                        showFileImporter = true
                    }
                    .buttonStyle(.link)
                }
                .padding()
            } else {
                // Drop Zone
                VStack(spacing: 16) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("Drop shader file here")
                        .font(.headline)
                    
                    Text("or")
                        .foregroundColor(.secondary)
                    
                    Button("Browse Files") {
                        showFileImporter = true
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("Supported: .frag, .vert, .glsl")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    selectedFile == nil ? Color.accentColor.opacity(0.3) : Color.clear,
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
        )
        .padding()
        .onDrop(of: [.fileURL], delegate: ShaderDropDelegate(droppedURL: $selectedFile))
    }
    
    // MARK: - Configuration
    private var configurationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Configuration")
                .font(.headline)
            
            // Shader Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Shader Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $selectedShaderType) {
                    ForEach(ShaderType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Entry Points
            VStack(alignment: .leading, spacing: 8) {
                Text("Entry Points")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Old")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Old entry point", text: $oldEntryPoint)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("New entry point", text: $newEntryPoint)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Convert Button
    private var convertButtonView: some View {
        VStack(spacing: 12) {
            if converter.isConverting {
                ProgressView("Converting shader...")
                    .padding()
            } else {
                Button(action: convertShader) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Convert to Metal")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedFile == nil || newEntryPoint.isEmpty)
                .padding()
            }
        }
    }
    
    // MARK: - Output Header
    private var outputHeaderView: some View {
        HStack {
            Text("Metal Shader Output")
                .font(.headline)
            
            Spacer()
            
            if let result = converter.conversionResult, result.success {
                Button(action: saveOutput) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Output View
    private var outputView: some View {
        Group {
            if let result = converter.conversionResult {
                if result.success {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Metal Code
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Metal Shader Code")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Text(result.metalCode)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .cornerRadius(8)
                            }
                            
                            // Logs
                            if !result.logs.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Conversion Logs")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    
                                    Text(result.logs)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .textSelection(.enabled)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(NSColor.textBackgroundColor))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                } else {
                    // Error View
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.red)
                        
                        Text("Conversion Failed")
                            .font(.headline)
                        
                        if let error = result.error {
                            Text(error)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        }
                        
                        if !result.logs.isEmpty {
                            ScrollView {
                                Text(result.logs)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                // Empty State
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text("No output yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Select a shader file and click Convert")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Actions
    private func convertShader() {
        guard let file = selectedFile else { return }
        
        Task {
            await converter.convertGLSLToMetal(
                inputURL: file,
                shaderType: selectedShaderType,
                oldEntryPoint: oldEntryPoint,
                newEntryPoint: newEntryPoint
            )
        }
    }
    
    private func saveOutput() {
        guard let result = converter.conversionResult,
              result.success,
              let fileName = selectedFile?.deletingPathExtension().lastPathComponent else {
            return
        }
        
        let suggestedName = "\(fileName).metal"
        _ = converter.saveMetalShader(content: result.metalCode, suggestedName: suggestedName)
    }
}

#Preview {
    ContentView()
        .frame(width: 1000, height: 700)
}
