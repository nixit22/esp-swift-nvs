// Copyright (c) 2026 Nicolas Christe
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@_exported import ESP_NVS
import Platform

private let log = Logger(tag: "NVS")

/// A handle to an open NVS namespace.
///
/// `~Copyable` — owns the handle; closed automatically in `deinit`.
public struct NVS: ~Copyable {
    private let handle: nvs_handle_t

    /// Opens `namespace` for access on the default partition.
    ///
    /// - Parameters:
    ///   - namespace: NVS namespace to open.
    ///   - readOnly: Opens read-only when `true`, read-write when `false` (default).
    /// - Throws: `Platform.Error` if the namespace can't be opened.
    public init(namespace: String, readOnly: Bool = false) throws(Error) {
        var h: nvs_handle_t = 0
        let mode: nvs_open_mode_t = readOnly ? NVS_READONLY : NVS_READWRITE
        try namespace.withCString { nvs_open($0, mode, &h) }
            .throwEspError { log.w("nvs_open(\(namespace)) failed: \($0.name)") }
        handle = h
    }

    deinit {
        nvs_close(handle)
    }

    /// Returns the stored string for `key`, or `nil` if the key does not exist.
    /// - Throws: `Platform.Error` for errors other than "key not found".
    public func getString(_ key: String) throws(Error) -> String? {
        var len: size_t = 0
        let lenErr = key.withCString { nvs_get_str(handle, $0, nil, &len) }
        if lenErr == ESP_ERR_NVS_NOT_FOUND { return nil }
        try lenErr.throwEspError { log.w("nvs_get_str(\(key)) failed: \($0.name)") }

        var readErr: esp_err_t = ESP_OK
        let buffer = [CChar](unsafeUninitializedCapacity: len) { ptr, initializedCount in
            readErr = key.withCString { k in nvs_get_str(handle, k, ptr.baseAddress, &len) }
            initializedCount = len
        }
        try readErr.throwEspError { log.w("nvs_get_str(\(key)) failed: \($0.name)") }
        // buffer includes the trailing NUL written by nvs_get_str; drop it before decoding.
        return String(decoding: buffer.dropLast().map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    /// Sets `key` to `value` unconditionally.
    public func setString(_ key: String, _ value: String) throws(Error) {
        try key.withCString { k in value.withCString { v in nvs_set_str(handle, k, v) } }
            .throwEspError { log.w("nvs_set_str(\(key)) failed: \($0.name)") }
    }

    /// Sets `key` to `value` only if `key` is not already present.
    /// - Returns: `true` if the value was written, `false` if it already existed.
    public func setStringIfMissing(_ key: String, _ value: String) throws(Error) -> Bool {
        if try getString(key) != nil { return false }
        try setString(key, value)
        return true
    }

    /// Returns the stored value for `key`, or `nil` if the key does not exist.
    /// - Throws: `Platform.Error` for errors other than "key not found".
    public func getU32(_ key: String) throws(Error) -> UInt32? {
        var value: UInt32 = 0
        let err = key.withCString { nvs_get_u32(handle, $0, &value) }
        if err == ESP_ERR_NVS_NOT_FOUND { return nil }
        try err.throwEspError { log.w("nvs_get_u32(\(key)) failed: \($0.name)") }
        return value
    }

    /// Sets `key` to `value` unconditionally.
    public func setU32(_ key: String, _ value: UInt32) throws(Error) {
        try key.withCString { nvs_set_u32(handle, $0, value) }
            .throwEspError { log.w("nvs_set_u32(\(key)) failed: \($0.name)") }
    }

    /// Returns the stored value for `key`, or `nil` if the key does not exist.
    /// - Throws: `Platform.Error` for errors other than "key not found".
    public func getU8(_ key: String) throws(Error) -> UInt8? {
        var value: UInt8 = 0
        let err = key.withCString { nvs_get_u8(handle, $0, &value) }
        if err == ESP_ERR_NVS_NOT_FOUND { return nil }
        try err.throwEspError { log.w("nvs_get_u8(\(key)) failed: \($0.name)") }
        return value
    }

    /// Sets `key` to `value` unconditionally.
    public func setU8(_ key: String, _ value: UInt8) throws(Error) {
        try key.withCString { nvs_set_u8(handle, $0, value) }
            .throwEspError { log.w("nvs_set_u8(\(key)) failed: \($0.name)") }
    }

    /// Commits pending writes to flash.
    public func commit() throws(Error) {
        try nvs_commit(handle).throwEspError { log.w("nvs_commit failed: \($0.name)") }
    }
}
