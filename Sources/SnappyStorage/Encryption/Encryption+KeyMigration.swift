import Foundation

#if canImport(Security)
extension Encryption {

    /// Stores the key derived from `keyString` (`Encryption(keyString:)`) into the keychain and
    /// returns an `Encryption` backed by that keychain item. Opt-in; the default key path is unchanged.
    public static func migrateKeyStringToKeychain(
        _ keyString: String,
        store: KeychainKeyStore
    ) throws -> Encryption {
        let derived = Encryption(keyString: keyString)
        try store.save(derived.symmetricKey)
        return try Encryption(keychain: store)
    }
}
#endif
