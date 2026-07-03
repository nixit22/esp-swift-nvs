# SwiftNVS

Swift wrapper for ESP-IDF NVS flash. Swift module name: **`NVS`**.

Depends on: `SwiftPlatform`, `SwiftSupport`, `nvs_flash`

## Files

| File | Role |
|---|---|
| `src/NVS.swift` | `@_exported import ESP_NVS` re-exports the raw C API; also defines `NVS`, a typed-throws wrapper over a single NVS namespace handle |
| `src/nvs.c` / `src/nvs.h` | Thin C wrapper — only `#include <nvs_flash.h>` |
| `module.modulemap` | Clang module `ESP_NVS` — umbrella over `src/nvs.h` |

## Public API

Raw ESP-IDF NVS C API, via the re-exported `ESP_NVS` Clang module:

```swift
import NVS

let err = nvs_flash_init()
// nvs_open, nvs_set_u32, nvs_get_u32, nvs_commit, nvs_close, ... all available
```

`NVS` — a small typed-throws wrapper struct for key/value access (`String`, `UInt32`, `UInt8`), for call sites that want to avoid manual `withCString`/`esp_err_t` plumbing:

```swift
let handle = try NVS(namespace: "my-namespace")
try handle.setString("key", "value")
let value = try handle.getString("key")        // nil only if key absent
let wrote = try handle.setStringIfMissing("key", "default")  // false if already present
try handle.setU32("count", 42)
let count = try handle.getU32("count")         // nil only if key absent
try handle.commit()
// No explicit cleanup — deinit calls nvs_close.
```

## Non-obvious patterns

**`@_exported import ESP_NVS`** — re-exports the C module so callers get `nvs_handle_t`, `nvs_flash_init`, `ESP_ERR_NVS_NO_FREE_PAGES`, etc. with a single `import NVS`.

**`~Copyable` + `deinit`** — `NVS` is noncopyable, matching `SwiftI2C`'s `I2CMasterBus`/`Device` pattern. `deinit` calls `nvs_close`; no explicit close call needed. `getString` treats only `ESP_ERR_NVS_NOT_FOUND` as "key absent" (returns `nil`); any other non-`ESP_OK` code throws.

**Default partition only** — `NVS.init` always opens via `nvs_open` (default `"nvs"` partition). No consumer in this mono-repo uses a second NVS partition, so `nvs_open_from_partition`/`nvs_flash_init_partition` support was dropped rather than kept as unused, untested plumbing. Re-add if/when a caller actually needs a non-default partition.

**No runtime logic in C glue** — `nvs.c` is empty except for `#include "nvs.h"`. It exists solely so the component has a C compilation unit (required by ESP-IDF component registration).
