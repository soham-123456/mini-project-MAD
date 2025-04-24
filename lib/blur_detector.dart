import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

class BlurDetector {
  // Significantly increased threshold to catch more blurry images
  static const double _blurThreshold = 2000.0;

  /// Determine if an image is blurry
  /// Returns true if the image is blurry, false otherwise
  static Future<bool> isBlurry(File imageFile) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        print('Failed to decode image: ${imageFile.path}');
        return true; // If we can't decode, assume it's not usable
      }
      
      // Resize large images to improve performance
      final processImage = _resizeIfNeeded(image);
      
      // Calculate blur score
      final blurScore = _calculateBlurScore(processImage);
      
      print('Blur score for ${imageFile.path.split('/').last}: $blurScore');
      
      // Higher score means sharper image, lower score means blurrier image
      return blurScore < _blurThreshold;
    } catch (e) {
      print('Error processing image: $e');
      return true; // Assume blurry on error
    }
  }
  
  /// Resize image if it's too large
  static img.Image _resizeIfNeeded(img.Image image) {
    const int maxSize = 500; // Maximum dimension for processing
    
    if (image.width > maxSize || image.height > maxSize) {
      return img.copyResize(
        image,
        width: image.width > image.height ? maxSize : null,
        height: image.height >= image.width ? maxSize : null,
      );
    }
    
    return image;
  }
  
  /// Calculate a blur score using Laplacian method
  static double _calculateBlurScore(img.Image image) {
    // Convert to grayscale
    final grayscale = img.grayscale(image);
    
    // Create simple Laplacian kernel for edge detection
    final laplacian = [
      0.0, 1.0, 0.0,
      1.0, -4.0, 1.0,
      0.0, 1.0, 0.0
    ];
    
    int width = grayscale.width;
    int height = grayscale.height;
    
    // Skip border pixels
    int startX = 1, startY = 1;
    int endX = width - 1, endY = height - 1;
    
    // Apply convolution and collect squared responses
    List<double> responses = [];
    
    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        double sum = 0.0;
        int kernelIndex = 0;
        
        // Apply 3x3 kernel
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = grayscale.getPixel(x + kx, y + ky);
            // In grayscale, all RGB channels have same value, so just get one
            final int grayValue = pixel.r.toInt();
            sum += grayValue * laplacian[kernelIndex++];
          }
        }
        
        // Square the response
        responses.add(sum * sum);
      }
    }
    
    // If no responses were calculated, return 0
    if (responses.isEmpty) return 0.0;
    
    // Return variance of responses
    return responses.reduce((a, b) => a + b) / responses.length;
  }

  /// Get the blur score without classification
  /// Returns the raw blur score value
  static Future<double> getBlurScore(File imageFile) async {
    try {
      // Read the image file
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        print('Failed to decode image: ${imageFile.path}');
        return 0.0; // If we can't decode, return 0
      }
      
      // Resize large images to improve performance
      final processImage = _resizeIfNeeded(image);
      
      // Calculate blur score
      return _calculateBlurScore(processImage);
    } catch (e) {
      print('Error processing image: $e');
      return 0.0; // Return 0 on error
    }
  }
} 