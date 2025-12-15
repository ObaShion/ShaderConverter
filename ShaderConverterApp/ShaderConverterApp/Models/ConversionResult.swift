//
//  ConversionResult.swift
//  ShaderConverterApp
//

import Foundation

struct ConversionResult {
    let metalCode: String
    let logs: String
    let success: Bool
    let error: String?
    
    static func success(metalCode: String, logs: String = "") -> ConversionResult {
        ConversionResult(metalCode: metalCode, logs: logs, success: true, error: nil)
    }
    
    static func failure(error: String, logs: String = "") -> ConversionResult {
        ConversionResult(metalCode: "", logs: logs, success: false, error: error)
    }
}
