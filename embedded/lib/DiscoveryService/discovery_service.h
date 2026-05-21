#ifndef DISCOVERY_SERVICE_H
#define DISCOVERY_SERVICE_H

#include <Arduino.h>

namespace Greenhouse {

class DiscoveryService {
public:
    static DiscoveryService& getInstance() {
        static DiscoveryService instance;
        return instance;
    }

    void start();
    void handleDiscoveryMessage(const char* topic, uint8_t* payload, unsigned int length);

private:
    DiscoveryService() {}
};

} // namespace Greenhouse

#endif // DISCOVERY_SERVICE_H
