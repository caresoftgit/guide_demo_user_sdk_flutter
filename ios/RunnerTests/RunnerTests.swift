import XCTest
import Security

final class RunnerTests: XCTestCase {
  func testHostCanStoreSessionMaterialInKeychain() throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: "customer-voice-test-" + UUID().uuidString,
      kSecAttrAccount as String: "probe",
    ]
    let value = Data("session-storage-probe".utf8)
    var item = query
    item[kSecValueData as String] = value
    item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    let status = SecItemAdd(item as CFDictionary, nil)
    defer { SecItemDelete(query as CFDictionary) }
    XCTAssertEqual(status, errSecSuccess, "Host signing must allow Keychain access")
    guard status == errSecSuccess else { return }
    var read = query
    read[kSecReturnData as String] = true
    read[kSecMatchLimit as String] = kSecMatchLimitOne
    var result: CFTypeRef?
    XCTAssertEqual(SecItemCopyMatching(read as CFDictionary, &result), errSecSuccess)
    XCTAssertEqual(result as? Data, value)
  }
}
