//
//  ShaderType.swift
//  ShaderConverterApp
//

import Foundation

enum ShaderType: String, CaseIterable, Identifiable {
    case vertex = "vert"
    case fragment = "frag"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .vertex:
            return "Vertex Shader"
        case .fragment:
            return "Fragment Shader"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .vertex:
            return ".vert"
        case .fragment:
            return ".frag"
        }
    }
}
