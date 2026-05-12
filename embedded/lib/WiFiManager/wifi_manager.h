#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <WiFi.h>

class WiFiManager {
public:
    WiFiManager();
    void begin(const char *ssid, const char *password);
    void begin(const char *ssid, const char *eapIdentity, const char *eapUsername,
               const char *eapPassword); // for eduroam
    bool isConnected();
    String getIPAddress();
    String getMACAddress();
    void setMode(wifi_mode_t mode);

private:
    String _ssid;
    String _password;
    const uint16_t _timeout = 30000;        // try to connect for 30 seconds
    const uint16_t _connectionDelay = 2000; // 2 second delay between attempts
};

#endif // WIFI_MANAGER_H
