import Flutter
import UIKit

class TextureController: NSObject {
    private var texture: TextrueWithCVPixelBuffer?
    private var textureId: Int64 = -1
    private var registry: FlutterTextureRegistry?
    private var methodChannel: FlutterMethodChannel?
    
    // Singleton instance
    static let shared = TextureController()
    
    private override init() {
        super.init()
    }
    
    // Setup method channel and registry
    func setup(with controller: FlutterViewController) {
        self.registry = controller.engine.textureRegistry
        
        // Setup method channel
        methodChannel = FlutterMethodChannel(
            name: "texture_channel",
            binaryMessenger: controller.binaryMessenger)
        
        // Register method handlers
        methodChannel?.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            
            switch call.method {
            case "createTexture":
                // Get parameters if provided, otherwise use defaults
                let args = call.arguments as? [String: Any]
                let width = args?["width"] as? Int ?? 300
                let height = args?["height"] as? Int ?? 500
                
                // Parse color if provided, otherwise use red
                var color = UIColor.red
                if let colorHex = args?["color"] as? String {
                    color = self.hexStringToUIColor(hex: colorHex) ?? UIColor.red
                }
                
                // Create texture and return ID
                let textureId = self.createTexture(width: width, height: height, color: color)
                result(textureId)
                
            case "updateTextureColor":
                guard let args = call.arguments as? [String: Any],
                      let colorHex = args["color"] as? String,
                      let color = self.hexStringToUIColor(hex: colorHex) else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", 
                                      message: "Color parameter is required", 
                                      details: nil))
                    return
                }
                
                self.updateTextureColor(color: color)
                result(nil)
                
            case "disposeTexture":
                self.dispose()
                result(nil)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func createTexture(width: Int, height: Int, color: UIColor) -> Int64 {
        // Create the texture object
        texture = TextrueWithCVPixelBuffer(color: color)
        
        // Initialize the pixel buffer
        guard let texture = texture, texture.createPixelBuffer(width: width, height: height) else {
            print("Failed to create pixel buffer")
            return -1
        }
        
        // Register the texture with Flutter
        guard let registry = registry else {
            print("Texture registry not available")
            return -1
        }
        
        textureId = registry.register(texture)
        
        return textureId
    }
    
    func updateTextureColor(color: UIColor) {
        guard let texture = texture else { return }
        
        // Update the texture with the new color
        texture.updateWithColor(color: color)
        
        // Notify Flutter that the texture has been updated
        if textureId >= 0 {
            registry?.textureFrameAvailable(textureId)
        }
    }
    
    func dispose() {
        if textureId >= 0 {
            registry?.unregisterTexture(textureId)
            textureId = -1
        }
        texture?.dispose()
        texture = nil
    }
    
    // MARK: - Helper methods
    
    private func hexStringToUIColor(hex: String) -> UIColor? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
