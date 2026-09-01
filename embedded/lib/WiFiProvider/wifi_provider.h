#ifndef WIFI_PROVIDER_H
#define WIFI_PROVIDER_H

#include <WiFi.h>
#include "system_context.h"

namespace Greenhouse {

class WiFiProvider {
public:
    static WiFiProvider& getInstance() {
        static WiFiProvider instance;
        return instance;
    }

    void begin();
    bool isConnected();
    String getIPAddress();
    String getMACAddress();

private:
    WiFiProvider() {}
    static void wifiEvent(WiFiEvent_t event, WiFiEventInfo_t info);

    unsigned long _lastReconnectAttempt = 0;
    const unsigned long RECONNECT_INTERVAL = 5000;
};

} // namespace Greenhouse

#endif // WIFI_PROVIDER_H
