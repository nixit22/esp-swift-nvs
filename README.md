# SwiftNVS

SwiftNVS exposes the ESP-IDF NVS (non-volatile storage) flash API to Embedded
Swift. It re-exports the raw NVS C API through a single `import NVS`, and
provides `NVS`, a small typed-throws wrapper struct for string key/value access.

## Features

- Single `import NVS` exposes `nvs_flash_init`, `nvs_open`, `nvs_get_*`, `nvs_set_*`, `nvs_commit`, `nvs_erase_*`, and all related types / error codes.
- Pulls in the `nvs_flash` ESP-IDF component transitively, so consumers don't need to declare it themselves.
- `NVS` wraps a namespace handle with `throws(Error)` get/set/commit methods for strings and `u32`/`u8` values, instead of manual `withCString` + `esp_err_t` checks.

## Usage

```swift
import NVS

let err = nvs_flash_init()
if err == ESP_ERR_NVS_NO_FREE_PAGES || err == ESP_ERR_NVS_NEW_VERSION_FOUND {
    _ = nvs_flash_erase()
    _ = nvs_flash_init()
}

let handle = try NVS(namespace: "my-namespace")
try handle.setString("key", "value")
let value = try handle.getString("key")  // nil if absent
try handle.commit()
// No explicit cleanup — deinit calls nvs_close.
```

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
