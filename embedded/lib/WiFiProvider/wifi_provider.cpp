#include "wifi_provider.h"
#include "config_manager.h"
#include "log.h"

namespace Greenhouse {

void WiFiProvider::begin() {
    String ssid = ConfigManager::getInstance().getWiFiSSID();
    String password = ConfigManager::getInstance().getWiFiPassword();

    if (ssid.length() == 0) {
        LOG_WARN("No WiFi credentials found in config.");
        return;
    }

    WiFi.onEvent(wifiEvent);
    WiFi.begin(ssid.c_str(), password.c_str());
    LOG_INFO("Connecting to WiFi: %s", ssid.c_str());
}

bool WiFiProvider::isConnected() {
    return WiFi.status() == WL_CONNECTED;
}

String WiFiProvider::getIPAddress() {
    return WiFi.localIP().toString();
}

String WiFiProvider::getMACAddress() {
    return WiFi.macAddress();
}

void WiFiProvider::wifiEvent(WiFiEvent_t event, WiFiEventInfo_t info) {
    switch (event) {
        case ARDUINO_EVENT_WIFI_STA_CONNECTED:
            LOG_INFO("WiFi Connected to AP");
            break;
        case ARDUINO_EVENT_WIFI_STA_GOT_IP:
            LOG_INFO("WiFi Got IP: %s", WiFi.localIP().toString().c_str());
            SystemContext::getInstance().transition(SystemEvent::EV_WIFI_CONNECTED);
            break;
        case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
            LOG_WARN("WiFi Lost Connection. Reason: %u", info.wifi_sta_disconnected.reason);
            SystemContext::getInstance().transition(SystemEvent::EV_WIFI_DISCONNECTED);
            WiFi.begin(); // Attempt to reconnect
            break;
        default:
            break;
    }
}

} // namespace Greenhouse
