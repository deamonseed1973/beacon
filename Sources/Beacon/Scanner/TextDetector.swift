import Accelerate
import CoreGraphics

/// Fast text presence detection using Sobel edge convolution.
/// Inspired by Peekaboo's AcceleratedTextDetector — uses vImage Sobel kernels
/// to measure edge density, which correlates strongly with text regions.
struct TextDetectionResult: Sendable {
    let density: Float
    let hasText: Bool
}

final class TextDetector: Sendable {
    /// Empirical threshold: regions with edge density above this likely contain text.
    private let densityThreshold: Float = 0.08
    /// Pixel intensity threshold for counting an edge pixel.
    private let edgeThreshold: UInt8 = 40

    func analyze(_ image: CGImage) -> TextDetectionResult {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0 else {
            return TextDetectionResult(density: 0, hasText: false)
        }

        // Create grayscale buffer from CGImage
        guard var sourceBuffer = grayscaleBuffer(from: image) else {
            return TextDetectionResult(density: 0, hasText: false)
        }
        defer { free(sourceBuffer.data) }

        let pixelCount = width * height
        let rowBytes = width

        // Allocate destination buffers for Sobel X and Y
        guard let sobelXData = malloc(pixelCount),
              let sobelYData = malloc(pixelCount) else {
            return TextDetectionResult(density: 0, hasText: false)
        }
        defer { free(sobelXData); free(sobelYData) }

        var sobelXBuffer = vImage_Buffer(
            data: sobelXData, height: vImagePixelCount(height),
            width: vImagePixelCount(width), rowBytes: rowBytes
        )
        var sobelYBuffer = vImage_Buffer(
            data: sobelYData, height: vImagePixelCount(height),
            width: vImagePixelCount(width), rowBytes: rowBytes
        )

        // 3x3 Sobel kernels
        let sobelXKernel: [Int16] = [
            -1, 0, 1,
            -2, 0, 2,
            -1, 0, 1
        ]
        let sobelYKernel: [Int16] = [
            -1, -2, -1,
             0,  0,  0,
             1,  2,  1
        ]

        // Convolve
        sobelXKernel.withUnsafeBufferPointer { xPtr in
            _ = vImageConvolve_Planar8(
                &sourceBuffer, &sobelXBuffer, nil, 0, 0,
                xPtr.baseAddress!, 3, 3, 0, vImage_Flags(kvImageEdgeExtend)
            )
        }
        sobelYKernel.withUnsafeBufferPointer { yPtr in
            _ = vImageConvolve_Planar8(
                &sourceBuffer, &sobelYBuffer, nil, 0, 0,
                yPtr.baseAddress!, 3, 3, 0, vImage_Flags(kvImageEdgeExtend)
            )
        }

        // Calculate edge density: count pixels where |sobelX| + |sobelY| > threshold
        let xPixels = sobelXData.assumingMemoryBound(to: UInt8.self)
        let yPixels = sobelYData.assumingMemoryBound(to: UInt8.self)
        var edgeCount = 0

        for i in 0..<pixelCount {
            let combined = UInt16(xPixels[i]) + UInt16(yPixels[i])
            if combined > UInt16(edgeThreshold) {
                edgeCount += 1
            }
        }

        let density = Float(edgeCount) / Float(pixelCount)
        return TextDetectionResult(density: density, hasText: density > densityThreshold)
    }

    private func grayscaleBuffer(from image: CGImage) -> vImage_Buffer? {
        let width = image.width
        let height = image.height
        let pixelCount = width * height

        guard let data = malloc(pixelCount) else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(
            data: data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            free(data)
            return nil
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        return vImage_Buffer(
            data: data,
            height: vImagePixelCount(height),
            width: vImagePixelCount(width),
            rowBytes: width
        )
    }
}
