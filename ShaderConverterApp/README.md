# Shader Converter Mac App

A native macOS application for converting GLSL shaders to Metal Shading Language.

## Features

- 🎨 Modern SwiftUI interface
- 📁 Drag-and-drop shader file support
- 🔄 Automatic GLSL → SPIR-V → Metal conversion
- ⚙️ Configurable entry points
- 💾 Export Metal shaders to file
- 📝 Detailed conversion logs

## Requirements

- macOS 13.0 or later
- Docker or OrbStack installed
- `shader_converter_toolkit` Docker image built

## Building the Docker Image

Before using the app, you need to build the Docker image:

```bash
cd /Users/oobashion/Downloads/ShaderConverter-main
docker build --platform linux/amd64 --tag shader_converter_toolkit .
```

## Building the App

1. Open `ShaderConverterApp.xcodeproj` in Xcode
2. Select your development team in the project settings (if needed)
3. Build and run (⌘R)

## Usage

1. Launch the Shader Converter app
2. Drag and drop a GLSL shader file (.frag, .vert, or .glsl) or click "Browse Files"
3. Select the shader type (Vertex or Fragment)
4. Configure entry points if needed (default is "main")
5. Click "Convert to Metal"
6. View the converted Metal shader code
7. Click "Save" to export the Metal shader file

## Supported File Types

- `.frag` - Fragment shaders
- `.vert` - Vertex shaders
- `.glsl` - Generic GLSL shaders

## Architecture

The app consists of:

- **ContentView**: Main SwiftUI interface with split-panel layout
- **ShaderConverter**: Core conversion logic orchestrator
- **DockerCommandExecutor**: Docker command execution utility
- **ShaderDropDelegate**: Drag-and-drop file handler
- **Models**: `ShaderType` and `ConversionResult` data models

## Conversion Pipeline

1. GLSL shader → SPIR-V (using `glslc`)
2. SPIR-V → Metal Shading Language (using `spirv-cross`)

All conversions run through Docker containers to ensure consistent results across different systems.
