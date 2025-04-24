import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'blur_detector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Separator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ImageSeparatorScreen(),
    );
  }
}

class ImageFile {
  final XFile xFile;
  Uint8List? bytes;
  bool? isBlurry;
  double? blurScore;

  ImageFile(this.xFile);
}

class ImageSeparatorScreen extends StatefulWidget {
  const ImageSeparatorScreen({super.key});

  @override
  State<ImageSeparatorScreen> createState() => _ImageSeparatorScreenState();
}

class _ImageSeparatorScreenState extends State<ImageSeparatorScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final List<ImageFile> _selectedImages = [];
  final List<ImageFile> _goodImages = [];
  final List<ImageFile> _blurryImages = [];
  bool _isProcessing = false;
  late TabController _tabController;
  
  // User-adjustable blur threshold
  double _webBlurThreshold = 8.0; // Edge ratio threshold (%) - more aggressive default
  double _nativeBlurThreshold = 2000.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.isEmpty) return;

      // Clear previous results
      setState(() {
        _selectedImages.clear();
        _goodImages.clear();
        _blurryImages.clear();
      });

      // Load images and their bytes
      for (final image in images) {
        final imageFile = ImageFile(image);
        // Load bytes immediately for web platform
        if (kIsWeb) {
          imageFile.bytes = await image.readAsBytes();
        }
        setState(() {
          _selectedImages.add(imageFile);
        });
      }
      
      // Show tip about manual classification
      _showSnackBar('Tip: Long-press any image to manually classify it as good or blurry');
    } catch (e) {
      _showSnackBar('Error picking images: $e');
    }
  }

  Future<void> _processImages() async {
    if (_selectedImages.isEmpty) {
      _showSnackBar('Please select images first');
      return;
    }

    setState(() {
      _isProcessing = true;
      _goodImages.clear();
      _blurryImages.clear();
    });

    try {
      for (final imageFile in _selectedImages) {
        bool isBlurry;
        
        if (kIsWeb) {
          // On web, we need to process using bytes
          if (imageFile.bytes == null) {
            imageFile.bytes = await imageFile.xFile.readAsBytes();
          }
          
          // Try a completely different approach
          final image = img.decodeImage(imageFile.bytes!);
          if (image == null) {
            isBlurry = true; // Can't decode
            imageFile.blurScore = 0;
          } else {
            // Resize for faster processing
            final smallImage = img.copyResize(image, width: 300);
            
            // 1. Convert to grayscale
            final grayscale = img.grayscale(smallImage);
            
            // 2. Compute simple edge detection
            int width = grayscale.width;
            int height = grayscale.height;
            int edgeCount = 0;
            int pixelCount = 0;
            
            // Skip the outer pixels to avoid border issues
            for (int y = 1; y < height - 1; y++) {
              for (int x = 1; x < width - 1; x++) {
                pixelCount++;
                
                // Get pixel and neighbors
                int center = grayscale.getPixel(x, y).r.toInt();
                int right = grayscale.getPixel(x + 1, y).r.toInt();
                int bottom = grayscale.getPixel(x, y + 1).r.toInt();
                
                // Calculate difference
                int horizDiff = (center - right).abs();
                int vertDiff = (center - bottom).abs();
                
                // If difference is significant, count as edge
                if (horizDiff > 10 || vertDiff > 10) {
                  edgeCount++;
                }
              }
            }
            
            // Edge ratio is our blur score - higher means sharper
            double edgeRatio = (edgeCount / pixelCount) * 100;
            
            imageFile.blurScore = edgeRatio;
            
            // INVERTED LOGIC: Lower edge ratio = blurrier image
            // Typically 5-15% for sharp images, 1-5% for blurry ones
            print('Web edge ratio: $edgeRatio%');
            
            isBlurry = edgeRatio < _webBlurThreshold; // Use the adjustable threshold
          }
        } else {
          // On mobile/desktop, we can use the file path
          final file = File(imageFile.xFile.path);
          imageFile.blurScore = await BlurDetector.getBlurScore(file);
          isBlurry = imageFile.blurScore! < _nativeBlurThreshold;
        }
        
        imageFile.isBlurry = isBlurry;
        
        setState(() {
          if (isBlurry) {
            _blurryImages.add(imageFile);
          } else {
            _goodImages.add(imageFile);
          }
        });
      }
      
      // Switch to the appropriate tab based on results
      if (_goodImages.isNotEmpty) {
        _tabController.animateTo(1); // Good images tab
      } else if (_blurryImages.isNotEmpty) {
        _tabController.animateTo(2); // Blurry images tab
      }
      
      // Show summary
      _showSnackBar('Found ${_goodImages.length} good images and ${_blurryImages.length} blurry images');
    } catch (e) {
      _showSnackBar('Error processing images: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Blur Detection Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Web Edge Ratio Threshold: ${_webBlurThreshold.toStringAsFixed(1)}%'),
                  Slider(
                    min: 1.0,
                    max: 20.0,
                    divisions: 190,
                    value: _webBlurThreshold,
                    onChanged: (value) {
                      setState(() {
                        _webBlurThreshold = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Native Blur Threshold: ${_nativeBlurThreshold.toInt()}'),
                  Slider(
                    min: 500,
                    max: 5000,
                    divisions: 45,
                    value: _nativeBlurThreshold,
                    onChanged: (value) {
                      setState(() {
                        _nativeBlurThreshold = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'For web: Images with edge ratio below threshold are marked as blurry\n\n'
                    'For non-web: Images with blur score below threshold are marked as blurry\n\n'
                    'Increase thresholds to catch more blurry images\n\n'
                    'TIP: You can also long-press any image to classify it manually',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Reprocess images with new thresholds if there are any
                    if (_selectedImages.isNotEmpty) {
                      _processImages();
                    }
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Separator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Selected Images'),
            Tab(text: 'Good Images'),
            Tab(text: 'Blurry Images'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildImageGrid(_selectedImages, 'No images selected'),
          _buildImageGrid(_goodImages, 'No good images found'),
          _buildImageGrid(_blurryImages, 'No blurry images found'),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: const Text('Select Images'),
            ),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _processImages,
              icon: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.filter),
              label: const Text('Process Images'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(List<ImageFile> images, String emptyMessage) {
    if (images.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(fontSize: 18),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final imageFile = images[index];
        final isBlurry = imageFile.isBlurry ?? false;
        
        return GestureDetector(
          onLongPress: () => _showManualClassificationDialog(imageFile),
          child: Card(
            elevation: 3.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: _buildImageWidget(imageFile),
                ),
                if (isBlurry)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white, width: 1)
                      ),
                      child: const Text(
                        'BLURRY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                // Show border color based on blur status
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isBlurry ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
                // Display blur score for debugging
                Positioned(
                  bottom: 5,
                  left: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Score: ${imageFile.blurScore?.toStringAsFixed(1) ?? "N/A"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildImageWidget(ImageFile imageFile) {
    if (kIsWeb) {
      // For web, use Image.memory
      if (imageFile.bytes != null) {
        return Image.memory(
          imageFile.bytes!,
          fit: BoxFit.cover,
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    } else {
      // For mobile/desktop, use Image.file
      return Image.file(
        File(imageFile.xFile.path),
        fit: BoxFit.cover,
      );
    }
  }

  void _showManualClassificationDialog(ImageFile imageFile) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Manual Classification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Mark this image as:'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _manuallyClassifyImage(imageFile, false);
                      Navigator.pop(context);
                    },
                    child: const Text('GOOD'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _manuallyClassifyImage(imageFile, true);
                      Navigator.pop(context);
                    },
                    child: const Text('BLURRY'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _manuallyClassifyImage(ImageFile imageFile, bool isBlurry) {
    setState(() {
      // Remove from current lists
      _goodImages.remove(imageFile);
      _blurryImages.remove(imageFile);
      
      // Update classification
      imageFile.isBlurry = isBlurry;
      
      // Add to appropriate list
      if (isBlurry) {
        _blurryImages.add(imageFile);
      } else {
        _goodImages.add(imageFile);
      }
    });
    
    // Show feedback
    _showSnackBar('Image manually classified as ${isBlurry ? 'blurry' : 'good'}');
  }
}
