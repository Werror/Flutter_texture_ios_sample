import Flutter
import UIKit

class TextrueWithCVPixelBuffer: NSObject, FlutterTexture {
    private var pixelBuffer: CVPixelBuffer?
    private var color: UIColor = .red
    
    init(color: UIColor = .red) {
        self.color = color
        super.init()
    }
    
    func createPixelBuffer(width: Int, height: Int) -> Bool {
        // Create a CVPixelBuffer
        let attributes = [
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
        ] as CFDictionary
        
        var newPixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes,
            &newPixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = newPixelBuffer else {
            print("Failed to create pixel buffer")
            return false
        }
        
        self.pixelBuffer = buffer
        updateWithColor(color: self.color)
        return true
    }
    
    func updateWithColor(color: UIColor) {
        self.color = color
        
        guard let pixelBuffer = pixelBuffer else { return }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .init(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .init(rawValue: 0)) }
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            print("Failed to get pixel buffer base address")
            return
        }
        
        // Get color components in BGRA format (Core Graphics uses RGBA)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Convert to UInt8 values (0-255)
        let redByte = UInt8(red * 255.0)
        let greenByte = UInt8(green * 255.0)
        let blueByte = UInt8(blue * 255.0)
        let alphaByte = UInt8(alpha * 255.0)
        
        // Create a single 32-bit BGRA pixel value
        let pixelValue: UInt32 = UInt32(blueByte) | (UInt32(greenByte) << 8) | (UInt32(redByte) << 16) | (UInt32(alphaByte) << 24)
        
        // Get buffer dimensions
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        // Use memset_pattern4 to efficiently fill the buffer with the color pattern
        // This is much faster than a nested loop for large buffers
        var pattern = pixelValue
        for row in 0..<height {
            let rowAddress = baseAddress.advanced(by: row * bytesPerRow)
            memset_pattern4(rowAddress, &pattern, width * 4)
        }
    }
    
    func dispose() {
        pixelBuffer = nil
    }
    
    // MARK: - FlutterTexture protocol
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        guard let pixelBuffer = pixelBuffer else {
            return nil
        }
        return Unmanaged.passRetained(pixelBuffer)
    }
}
