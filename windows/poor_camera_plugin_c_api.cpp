#include "include/poor_camera/poor_camera_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "poor_camera_plugin.h"

void PoorCameraPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  poor_camera::PoorCameraPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
