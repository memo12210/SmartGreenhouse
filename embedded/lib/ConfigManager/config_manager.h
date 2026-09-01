#ifndef CONFIG_MANAGER_H
#define CONFIG_MANAGER_H

#include <Preferences.h>
#include <Arduino.h>

namespace Greenhouse {

class ConfigManager {
public:
    static ConfigManager& getInstance() {
        static ConfigManager instance;
        return instance;
    }

    bool begin();

    // WiFi Config
    void setWiFiCredentials(const char* ssid, const char* password);
    String getWiFiSSID();
    String getWiFiPassword();

    // MQTT Config
    void setMQTTConfig(const char* server, uint16_t port);
    String getMQTTServer();
    uint16_t getMQTTPort();

    // Device Identity
    void setDeviceIdentity(const char* deviceId, const char* greenhouseId);
    String getDeviceId();
    String getGreenhouseId();

    void clear();

private:
    ConfigManager() {}
    Preferences _prefs;
    const char* PREFS_NAMESPACE = "gh_config";
};

} // namespace Greenhouse

#endif // CONFIG_MANAGER_H
