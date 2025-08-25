import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const TextureSampleApp());
}

class TextureSampleApp extends StatelessWidget {
  const TextureSampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Texture Sample',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const TextureDisplayPage(title: 'Flutter Texture Sample'),
    );
  }
}

class TextureDisplayPage extends StatefulWidget {
  const TextureDisplayPage({super.key, required this.title});

  final String title;

  @override
  State<TextureDisplayPage> createState() => _TextureDisplayPageState();
}

class _TextureDisplayPageState extends State<TextureDisplayPage> {
  static const MethodChannel _textureChannel = MethodChannel('texture_channel');
  int? _textureId;
  Color _currentColor = Colors.red;
  final List<Color> _availableColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
  ];

  @override
  void initState() {
    super.initState();
    _initializeTexture();
  }

  // Initialize texture with native code
  Future<void> _initializeTexture() async {
    try {
      // Call platform-specific code to get a texture ID
      // Pass width, height, and color parameters
      final textureId = await _textureChannel.invokeMethod<int>('createTexture', {
        'width': 300,
        'height': 500,
        'color': _colorToHex(_currentColor),
      });

      setState(() {
        _textureId = textureId;
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to create texture: ${e.message}');
    }
  }

  // Update texture color
  Future<void> _updateTextureColor(Color color) async {
    if (_textureId == null) return;

    try {
      await _textureChannel.invokeMethod<void>('updateTextureColor', {
        'color': _colorToHex(color),
      });

      setState(() {
        _currentColor = color;
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to update texture color: ${e.message}');
    }
  }

  // Convert Color to hex string
  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _textureId != null
                  ? AspectRatio(
                      aspectRatio: 9 / 16, // 9:16 aspect ratio
                      child: Texture(
                        textureId: _textureId!,
                        filterQuality: FilterQuality.none,
                      ),
                    )
                  : Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height:
                          MediaQuery.of(context).size.width * 0.9 * (16 / 9),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: const Center(
                        child: Text(
                          'Texture not initialized',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
            ),
          ),
          // Color selection buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Select Texture Color:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  children: _availableColors.map((color) {
                    return GestureDetector(
                      onTap: () => _updateTextureColor(color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.rectangle,
                          border: Border.all(
                            color: _currentColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Clean up texture resources when widget is disposed
    if (_textureId != null) {
      _textureChannel.invokeMethod<void>('disposeTexture');
    }
    super.dispose();
  }
}