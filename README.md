# poor_camera

`poor_camera` is a simple Flutter plugin that implements camera functionality for **Web**.  
It injects a small JavaScript helper into your `web/index.html` and exposes an easy Dart API for capturing images in Flutter web apps.
 

## Usage
```dart
import 'package:poor_camera/poor_camera.dart';

Future<Uint8List?> openCamera(BuildContext context) async {
  try {
    final poorCamera = PoorCamera(); 
    final bytes = await poorCamera.showCamera(
      context,
    );
    return bytes;
  } catch (e) {
    print('Error: $e');
    return null;
  }
}
 
}
```

## Web Setup

To enable camera functionality on the web, add the following to your `web/index.html` inside the `<head>` tag:

```html
<head>
  <!-- ... other head tags ... -->
  <script
    type="application/javascript"
    src="/assets/packages/poor_camera/assets/web/camera_settings.js"
    defer>
  </script>
  <!-- ... other head tags ... -->
</head>

```