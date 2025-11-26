/// Circular Image Cropper Widget
///
/// Provides interactive circular image cropping with:
/// - Pan/drag to reposition crop circle
/// - Pinch/zoom (mobile) or scroll (desktop) to resize crop circle
/// - Live circular preview with semi-transparent overlay
/// - Platform-specific instructions and affordances
/// - Normalized output for consistent sizing
library;

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageCropperWidget extends StatefulWidget {
  final Uint8List imageBytes;
  final String imageName;
  final VoidCallback? onClose;

  const ImageCropperWidget({
    super.key,
    required this.imageBytes,
    required this.imageName,
    this.onClose,
  });

  @override
  State<ImageCropperWidget> createState() => _ImageCropperWidgetState();
}

class _ImageCropperWidgetState extends State<ImageCropperWidget> {
  late img.Image _decodedImage;
  late Size _displaySize;
  Offset _circleCenter = Offset.zero;
  double _circleRadius = 100;
  bool _imageLoaded = false;
  double _baseScaleFactor = 1.0;

  // Platform detection
  bool get _isMobile =>
      !kIsWeb &&
      (Theme.of(context).platform == TargetPlatform.iOS ||
          Theme.of(context).platform == TargetPlatform.android);

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      _decodedImage = img.decodeImage(widget.imageBytes)!;
      _initializeCropCircle();
      if (mounted) {
        setState(() => _imageLoaded = true);
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
  }

  void _initializeCropCircle() {
    // Calculate how the image will actually be displayed with BoxFit.contain
    final imageAspectRatio = _decodedImage.width / _decodedImage.height;
    final containerAspectRatio = 400 / 400; // Square container

    double actualImageWidth;
    double actualImageHeight;

    if (imageAspectRatio > containerAspectRatio) {
      // Image is wider - will fill width, have padding on top/bottom
      actualImageWidth = 400;
      actualImageHeight = 400 / imageAspectRatio;
    } else {
      // Image is taller - will fill height, have padding on left/right
      actualImageWidth = 400 * imageAspectRatio;
      actualImageHeight = 400;
    }

    // Store the actual display size for coordinate calculations
    _displaySize = Size(actualImageWidth, actualImageHeight);

    _circleCenter = Offset(_displaySize.width / 2, _displaySize.height / 2);
    _circleRadius = (_displaySize.width * 0.3).clamp(
      50,
      _displaySize.width / 2,
    );
  }

  void _updateCircleCenter(Offset newCenter) {
    final constraints = _getCircleConstraints();

    setState(() {
      _circleCenter = Offset(
        newCenter.dx.clamp(constraints.minX, constraints.maxX),
        newCenter.dy.clamp(constraints.minY, constraints.maxY),
      );
    });
  }

  void _updateCircleRadius(double delta) {
    final maxRadius = _displaySize.width / 2;
    final newRadius = _circleRadius + delta;

    setState(() {
      _circleRadius = newRadius.clamp(50.0, maxRadius);
    });
  }

  ({double minX, double maxX, double minY, double maxY})
  _getCircleConstraints() {
    return (
      minX: _circleRadius,
      maxX: _displaySize.width - _circleRadius,
      minY: _circleRadius,
      maxY: _displaySize.height - _circleRadius,
    );
  }

  Future<Uint8List> _cropImageCircular() async {
    if (!_imageLoaded) return widget.imageBytes;

    // Calculate uniform scale factor (how much the image was scaled to fit display)
    final scaleX = _decodedImage.width / _displaySize.width;
    final scaleY = _decodedImage.height / _displaySize.height;

    // Use the uniform scale factor (they should be the same due to aspect ratio preservation)
    // But we'll use the average to handle any minor discrepancies
    final scale = (scaleX + scaleY) / 2;

    // Convert display coordinates to image coordinates using uniform scale
    final imageCenterX = (_circleCenter.dx * scale).toInt();
    final imageCenterY = (_circleCenter.dy * scale).toInt();
    final imageRadius = (_circleRadius * scale).toInt();

    // Create a new square image for the circular crop
    final outputSize = (imageRadius * 2);
    final croppedImage = img.Image(width: outputSize, height: outputSize);

    // Copy pixels in circular pattern
    for (int y = 0; y < outputSize; y++) {
      for (int x = 0; x < outputSize; x++) {
        // Check if pixel is within circle
        final dx = x - imageRadius;
        final dy = y - imageRadius;
        if (dx * dx + dy * dy <= imageRadius * imageRadius) {
          // Sample from original image
          final sourceX = (imageCenterX + dx).clamp(0, _decodedImage.width - 1);
          final sourceY = (imageCenterY + dy).clamp(
            0,
            _decodedImage.height - 1,
          );

          // Get pixel from source image
          final pixel = _decodedImage.getPixel(sourceX, sourceY);
          croppedImage.setPixel(x, y, pixel);
        }
      }
    }

    // Normalize to standard size
    final normalized = img.copyResize(
      croppedImage,
      width: StudentImage.normalizedSize.toInt(),
      height: StudentImage.normalizedSize.toInt(),
    );

    return Uint8List.fromList(img.encodePng(normalized));
  }

  @override
  Widget build(BuildContext context) {
    // Platform-specific instructions
    final instructionText =
        _isMobile
            ? 'Drag to move • Pinch to resize'
            : 'Drag to move • Scroll to resize';

    return Dialog(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Crop Student Photo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),

          // Image preview area
          Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.all(16),
            child:
                _imageLoaded
                    ? _buildCropArea()
                    : SizedBox(
                      width: _displaySize.width,
                      height: _displaySize.height,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
          ),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isMobile ? Icons.touch_app : Icons.mouse,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      instructionText,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final croppedBytes = await _cropImageCircular();
                        if (context.mounted) {
                          Navigator.pop(context, croppedBytes);
                        }
                      },
                      child: const Text('Crop & Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropArea() {
    if (_isMobile) {
      // Mobile: Use GestureDetector with scale for pinch-to-zoom
      return GestureDetector(
        onScaleStart: (details) {
          _baseScaleFactor = _circleRadius;
        },
        onScaleUpdate: (details) {
          // Handle both pan and scale
          if (details.scale != 1.0) {
            // Pinch to zoom
            final newRadius = _baseScaleFactor * details.scale;
            _updateCircleRadius(newRadius - _circleRadius);
          }

          // Pan to move
          if (details.focalPointDelta.dx != 0 ||
              details.focalPointDelta.dy != 0) {
            _updateCircleCenter(_circleCenter + details.focalPointDelta);
          }
        },
        child: _buildImageStack(),
      );
    } else {
      // Desktop: Use Listener for scroll wheel + GestureDetector for drag
      return Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            // Scroll to resize
            final delta = -event.scrollDelta.dy * 0.5;
            _updateCircleRadius(delta);
          }
        },
        child: GestureDetector(
          onPanUpdate: (details) {
            _updateCircleCenter(_circleCenter + details.delta);
          },
          child: _buildImageStack(),
        ),
      );
    }
  }

  Widget _buildImageStack() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Original image
        SizedBox(
          width: _displaySize.width,
          height: _displaySize.height,
          child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
        ),

        // Circular crop overlay
        CustomPaint(
          size: _displaySize,
          painter: CircularCropPainter(
            center: _circleCenter,
            radius: _circleRadius,
          ),
        ),

        // Resize handle indicator (more prominent on mobile)
        Positioned(
          left: _circleCenter.dx + _circleRadius - 20,
          top: _circleCenter.dy - _circleRadius,
          child: Container(
            width: _isMobile ? 48 : 40,
            height: _isMobile ? 48 : 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 8),
              ],
            ),
            child: Icon(
              _isMobile ? Icons.zoom_out_map : Icons.edit,
              color: Colors.white,
              size: _isMobile ? 24 : 20,
            ),
          ),
        ),
      ],
    );
  }
}

class CircularCropPainter extends CustomPainter {
  final Offset center;
  final double radius;

  CircularCropPainter({required this.center, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent overlay outside circle
    final path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addOval(Rect.fromCircle(center: center, radius: radius))
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill,
    );

    // Circle border
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );

    // Corner guides
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.blue.withValues(alpha: 0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CircularCropPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.radius != radius;
  }
}

class StudentImage {
  final Uint8List imageBytes;
  final String fileName;
  final Offset cropCenter;
  final double cropRadius;
  final Size imageSize;

  StudentImage({
    required this.imageBytes,
    required this.fileName,
    required this.cropCenter,
    required this.cropRadius,
    required this.imageSize,
  });

  // Normalize to consistent size (e.g., 200x200 normalized)
  static const double normalizedSize = 200.0;

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'cropCenter': {'dx': cropCenter.dx, 'dy': cropCenter.dy},
    'cropRadius': cropRadius,
    'imageSize': {'width': imageSize.width, 'height': imageSize.height},
  };
}
