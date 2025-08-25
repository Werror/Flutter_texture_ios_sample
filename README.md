# Flutter Texture Sample

A sample Flutter application demonstrating how to use iOS's `FlutterTexture` to render native content in Flutter.

## Overview

This project demonstrates how to:

1. Create a native iOS texture using `FlutterTexture` protocol
2. Register the texture with Flutter's texture registry
3. Display the texture in a Flutter app using the `Texture` widget
4. Communicate between Flutter and native code using method channels
5. Update the texture dynamically (changing colors) by access CVPixelBuffer directly

<img src="https://raw.githubusercontent.com/Werror/Flutter_texture_ios_sample/refs/heads/main/screenshot.jpg" width="400">

## Architecture

The project follows a clean architecture with separation of concerns:

### Flutter Side (Dart)
- `TextureSampleApp`: Main application entry point
- `TextureDisplayPage`: UI for displaying the texture and color controls
- Method channel communication with native code

### iOS Side (Swift)
- `TextureController`: Manages texture registration and lifecycle
- `Texture_iOS`: Implements the `FlutterTexture` protocol
- Method channel handlers for creating and updating textures

## Implementation Details

### Method Channel

The app uses a method channel named `texture_channel` with the following methods:

- `createTexture`: Creates a texture with specified dimensions and color
- `updateTextureColor`: Updates the texture with a new color
- `disposeTexture`: Cleans up texture resources

### Texture Implementation

The iOS texture implementation:
- Uses `CVPixelBuffer` to store pixel data
- Efficiently fills the buffer with a solid color using `memset_pattern4`
- Implements the `FlutterTexture` protocol's `copyPixelBuffer()` method

## Key Files

- `lib/main.dart`: Flutter UI and method channel implementation
- `ios/Runner/TextureController.swift`: Texture management and method channel handling
- `ios/Runner/TextrueWithCVPixelBuffer.swift`: FlutterTexture implementation
- `ios/Runner/AppDelegate.swift`: App initialization and setup
