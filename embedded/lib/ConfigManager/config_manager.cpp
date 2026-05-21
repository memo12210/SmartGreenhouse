#include "config_manager.h"

namespace Greenhouse {

bool ConfigManager::begin() {
    return _prefs.begin(PREFS_NAMESPACE, false);
}

void ConfigManager::setWiFiCredentials(const char* ssid, const char* password) {
    _prefs.putString("wifi_ssid", ssid);
    _prefs.putString("wifi_pass", password);
}

String ConfigManager::getWiFiSSID() {
    return _prefs.getString("wifi_ssid", "");
}

String ConfigManager::getWiFiPassword() {
    return _prefs.getString("wifi_pass", "");
}

void ConfigManager::setMQTTConfig(const char* server, uint16_t port) {
    _prefs.putString("mqtt_server", server);
    _prefs.putUInt("mqtt_port", port);
}

String Greenhouse::ConfigManager::getMQTTServer() {
    return _prefs.getString("mqtt_server", "");
}

uint16_t ConfigManager::getMQTTPort() {
    return _prefs.getUInt("mqtt_port", 1883);
}

void ConfigManager::setDeviceIdentity(const char* deviceId, const char* greenhouseId) {
    _prefs.putString("dev_id", deviceId);
    _prefs.putString("gh_id", greenhouseId);
}

String ConfigManager::getDeviceId() {
    return _prefs.getString("dev_id", "");
}

String ConfigManager::getGreenhouseId() {
    return _prefs.getString("gh_id", "");
}

void ConfigManager::clear() {
    _prefs.clear();
}

} // namespace Greenhouse
