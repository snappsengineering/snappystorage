import Foundation

enum Payload {

    static func write<E: Encodable, M>(
        _ value: E,
        storage: Storage<M>,
        jsonEncoder: JSONEncoder,
        encryption: Encryption?
    ) throws {
        let data = try jsonEncoder.encodePayload(value)
        try storage.write(try encryption.sealedPayload(from: data))
    }

    static func read<T: Decodable, M>(
        _ type: T.Type,
        storage: Storage<M>,
        jsonDecoder: JSONDecoder,
        encryption: Encryption?
    ) throws -> T {
        let payload = try storage.read()
        let data = try encryption.openedPayload(from: payload)
        return try jsonDecoder.decodePayload(type, from: data)
    }

    static func storeItems<T: Storable, M>(
        _ items: [T],
        storage: Storage<M>,
        jsonEncoder: JSONEncoder,
        encryption: Encryption?
    ) throws {
        try write(items, storage: storage, jsonEncoder: jsonEncoder, encryption: encryption)
    }

    static func fetchItems<T: Storable, M>(
        _ type: T.Type,
        storage: Storage<M>,
        jsonDecoder: JSONDecoder,
        encryption: Encryption?
    ) throws -> [T] {
        try read([T].self, storage: storage, jsonDecoder: jsonDecoder, encryption: encryption)
    }

    static func loadCollection<T: Storable, M>(
        storage: Storage<M>,
        jsonDecoder: JSONDecoder,
        encryption: Encryption?
    ) throws -> Set<T> {
        Set(try fetchItems(T.self, storage: storage, jsonDecoder: jsonDecoder, encryption: encryption))
    }
}
