import Foundation

extension JSONEncoder {

    func encodePayload<T: Encodable>(_ value: T) throws -> Data {
        do {
            return try encode(value)
        } catch {
            throw EncoderError.encodingFailed(error)
        }
    }
}

extension JSONDecoder {

    func decodePayload<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decode(type, from: data)
        } catch {
            throw EncoderError.decodingFailed(error)
        }
    }
}
