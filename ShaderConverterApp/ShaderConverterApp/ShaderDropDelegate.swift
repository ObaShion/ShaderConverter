//
//  ShaderDropDelegate.swift
//  ShaderConverterApp
//

import SwiftUI
import UniformTypeIdentifiers

struct ShaderDropDelegate: DropDelegate {
    @Binding var droppedURL: URL?
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.fileURL])
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.fileURL]).first else {
            return false
        }
        
        itemProvider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            let ext = url.pathExtension.lowercased()
            if ext == "frag" || ext == "vert" || ext == "glsl" {
                DispatchQueue.main.async {
                    self.droppedURL = url
                }
            }
        }
        
        return true
    }
}
