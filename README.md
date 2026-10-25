# SwiftNVS

Swift wrapper for ESP-IDF's NVS (non-volatile storage) flash API. Re-exports the raw C API through a single `import NVS`, plus `NVS`, a small typed-throws wrapper for string/`u32`/`u8` key-value access. Swift module name: **`NVS`**.

Depends on: `SwiftPlatform`, `SwiftSupport`, `nvs_flash` (pulled in transitively).

## Adding it to a project

This is a [SwiftPM](https://www.swift.org/package-manager/) package, built for ESP-IDF by
`swift_package()` from [esp-swift-support](https://github.com/nixit22/esp-swift-support). In your
app's `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/nixit22/esp-swift-nvs.git", branch: "SPM"),
],
targets: [
    .target(name: "App", dependencies: [.product(name: "NVS", package: "esp-swift-nvs")]),
]
```

See esp-swift-support's README for the project setup (top-level `CMakeLists.txt`, `main`
component, Swift toolchain).

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

See [`CLAUDE.md`](CLAUDE.md) for full API details and non-obvious patterns.

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
