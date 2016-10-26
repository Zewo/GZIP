import Czlib
import Foundation

public enum GzipMode {
    case compress
    case uncompress
    
    public func processor() -> GzipProcessor {
        switch self {
        case .compress: return GzipCompressor()
        case .uncompress: return GzipUncompressor()
        }
    }
}

public protocol Gzippable {
    associatedtype DataType
    /// returns compressed buffer or throws an `Error`.
    ///
    /// - throws: An `Error` if the buffer can not be compressed.
    ///
    /// - returns: A Buffer with compressed data or throws an `Error`.
    func gzipCompressed() throws -> DataType
    
    /// returns uncompressed buffer or throws an `Error`.
    ///
    /// - throws: An `Error` if the buffer can not be decompressed.
    ///
    /// - returns: A Buffer with uncompressed data or throws an `Error`.
    func gzipUncompressed() throws -> DataType
}

public protocol GzipProcessor: class {
    func initialize() throws
    func process(data: Data, isLast: Bool) throws -> Data
    func close()
    var closed: Bool { get set }
    var _stream: UnsafeMutablePointer<z_stream> { get }
}

private let CHUNK_SIZE: Int = 2 ^ 14
private let STREAM_SIZE: Int32 = Int32(MemoryLayout<z_stream>.size)

public enum GzipError: Error {
    //Reference: http://www.zlib.net/manual.html
    
    /// The stream structure was inconsistent.
    case stream(message: String)
    
    ///The input data was corrupted (input stream not conforming to the zlib format or incorrect check value).
    case data(message: String)
    
    /// There was not enough memory.
    case memory(message: String)
    
    /// No progress is possible or there was not enough room in the output buffer.
    case buffer(message: String)
    
    /// The zlib library version is incompatible with the version assumed by the caller.
    case version(message: String)
    
    /// An unknown error occurred.
    case unknown(message: String, code: Int)
    
    internal init(code: Int32, message cmessage: UnsafePointer<CChar>?)
    {
        let message: String
        if let cmessage = cmessage, let msg = String(validatingUTF8: cmessage) {
            message = msg
        } else {
            message = "unknown gzip error"
        }
        switch code {
        case Z_STREAM_ERROR: self = .stream(message: message)
        case Z_DATA_ERROR: self = .data(message: message)
        case Z_MEM_ERROR: self = .memory(message: message)
        case Z_BUF_ERROR: self = .buffer(message: message)
        case Z_VERSION_ERROR: self = .version(message: message)
        default: self = .unknown(message: message, code: Int(code))
        }
    }
}

