#include <unity.h>
#include <string>
#include <map>

namespace Greenhouse {
    class ConfigManager {
    public:
        static ConfigManager& getInstance() {
            static ConfigManager instance;
            return instance;
        }
        void setWiFiCredentials(const char* ssid, const char* password) {
            _storage["wifi_ssid"] = ssid;
            _storage["wifi_pass"] = password;
        }
        std::string getWiFiSSID() { return _storage["wifi_ssid"]; }
        void clear() { _storage.clear(); }
    private:
        ConfigManager() {}
        std::map<std::string, std::string> _storage;
    };
}

void test_config_storage(void) {
    Greenhouse::ConfigManager::getInstance().clear();
    Greenhouse::ConfigManager::getInstance().setWiFiCredentials("MySSID", "MyPass");
    TEST_ASSERT_EQUAL_STRING("MySSID", Greenhouse::ConfigManager::getInstance().getWiFiSSID().c_str());
}

int main(int argc, char **argv) {
    UNITY_BEGIN();
    RUN_TEST(test_config_storage);
    return UNITY_END();
}
