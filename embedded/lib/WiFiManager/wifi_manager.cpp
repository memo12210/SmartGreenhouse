#include "wifi_manager.h"
#include <log.h>

WiFiManager::WiFiManager() {}

void WiFiManager::begin(const char *ssid, const char *password) {
    WiFi.disconnect(true);
    WiFi.mode(WIFI_OFF);
    delay(100);
    setMode(WIFI_STA);

    // Optimize WiFi connection parameters
    WiFi.setTxPower(WIFI_POWER_19_5dBm);
    WiFi.setAutoConnect(true);
    WiFi.setAutoReconnect(true);

    _ssid = ssid;
    _password = password;
    WiFi.begin(ssid, password);

    unsigned long startTime = millis();

    while (WiFi.status() != WL_CONNECTED) {
        if (millis() - startTime > _timeout) {
            LOG_WARN("Could not connect to a WiFi");
            break;
        }

        LOG_INFO("Trying to connect to a WiFi...");
        delay(_connectionDelay);
    }
}

void WiFiManager::begin(const char *ssid, const char *eapIdentity, const char *eapUsername, const char *eapPassword) {
    WiFi.disconnect(true);
    WiFi.mode(WIFI_OFF);
    delay(100);
    setMode(WIFI_STA);

    // Optimize WiFi connection parameters
    WiFi.setTxPower(WIFI_POWER_19_5dBm);
    WiFi.setAutoConnect(true);
    WiFi.setAutoReconnect(true);

    _ssid = ssid;

    LOG_INFO("Connecting to eduroam network: %s", ssid);
    WiFi.begin(ssid, WPA2_AUTH_PEAP, eapIdentity, eapUsername, eapPassword);

    unsigned long startTime = millis();

    while (WiFi.status() != WL_CONNECTED) {
        if (millis() - startTime > _timeout) {
            LOG_WARN("Could not connect to eduroam WiFi");
            break;
        }

        LOG_INFO("Trying to connect to eduroam...");
        delay(_connectionDelay);
    }
}

bool WiFiManager::isConnected() { return WiFi.status() == WL_CONNECTED; }

String WiFiManager::getIPAddress() {
    if (isConnected()) {
        return WiFi.localIP().toString();
    } else {
        return "Not Connected";
    }
}

String WiFiManager::getMACAddress() { return WiFi.macAddress(); }

void WiFiManager::setMode(wifi_mode_t mode) { WiFi.mode(mode); }
