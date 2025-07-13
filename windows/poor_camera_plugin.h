#ifndef FLUTTER_PLUGIN_POOR_CAMERA_PLUGIN_H_
#define FLUTTER_PLUGIN_POOR_CAMERA_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace poor_camera {

class PoorCameraPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  PoorCameraPlugin();

  virtual ~PoorCameraPlugin();

  // Disallow copy and assign.
  PoorCameraPlugin(const PoorCameraPlugin&) = delete;
  PoorCameraPlugin& operator=(const PoorCameraPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace poor_camera

#endif  // FLUTTER_PLUGIN_POOR_CAMERA_PLUGIN_H_
