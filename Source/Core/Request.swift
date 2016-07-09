//
//  Request.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/25/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

/// Defines an interface for encoding parameters in a HTTP request.
protocol ParameterEncoder {
    func encodeURL(_ url: URL, parameters: [String : AnyObject]) -> URL?
    func encodeBody(_ parameters: [String : AnyObject]) -> Data?
}

/// Defines an interface for encoding a `NSURLRequest`.
protocol URLRequestEncodable {
    var urlRequestValue: URLRequest {get}
}

protocol RequestEncoder {
    func encodeRequest(_ method: Request.Method, url: String, parameters: [String : AnyObject]?, options: [Request.Option]?) -> Request
}

/**
 Encapsulates the data required to send an HTTP request.
*/
public struct Request {
    
    /// The `Method` enum defines the supported HTTP methods.
    public enum Method: String {
        case GET = "GET"
        case HEAD = "HEAD"
        case POST = "POST"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    // MARK: Parameter Encodings
    
    /// A `ParameterEncoding` value defines how to encode request parameters
    public enum ParameterEncoding: ParameterEncoder {
        /// Encode parameters with percent encoding
        case percent
        /// Encode parameters as JSON
        case json
        
        /**
         Encode query parameters in an existing URL.
        
         - parameter url: Query string will be appended to this NSURL value.
         - parameter parameters: Query parameters to be encoded as a query string.
         - returns: A NSURL value with query string parameters encoded.
        */
        public func encodeURL(_ url: URL, parameters: [String : AnyObject]) -> URL? {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                components.appendPercentEncodedQuery(parameters.percentEncodedQueryString)
                return components.url
            }
            
            return nil
        }
        
        /**
         Encode query parameters into a NSData value for request body.
        
         - parameter parameters: Query parameters to be encoded as HTTP body.
         - returns: NSData value with containing encoded parameters.
        */
        public func encodeBody(_ parameters: [String : AnyObject]) -> Data? {
            switch self {
            case .percent:
                return parameters.percentEncodedQueryString.data(using: String.Encoding.utf8, allowLossyConversion: false)
            case .json:
                do {
                    return try JSONSerialization.data(withJSONObject: parameters, options: JSONSerialization.WritingOptions())
                } catch _ {
                    return nil
                }
            }
        }
    }
    
    /// A group of static constants for referencing HTTP header field names.
    public struct Headers {
        public static let userAgent = "User-Agent"
        public static let contentType = "Content-Type"
        public static let contentLength = "Content-Length"
        public static let accept = "Accept"
        public static let cacheControl = "Cache-Control"
    }
    
    /// A group of static constants for referencing supported HTTP 
    /// `Content-Type` header values.
    public struct ContentType {
        public static let formEncoded = "application/x-www-form-urlencoded"
        public static let json = "application/json"
    }
    
    /// The HTTP method of the request.
    public let method: Method
    
    /// The URL string of the HTTP request.
    public let url: String
    
    /**
     The parameters to encode in the HTTP request. Request parameters are percent
     encoded and are appended as a query string or set as the request body 
     depending on the HTTP request method.
    */
    public var parameters = [String : AnyObject]()
    
    /**
     The HTTP header fields of the request. Each key/value pair represents a 
     HTTP header field value using the key as the field name.
    */
    internal(set) var headers = [String : String]()
    
    /// The cache policy of the request. See NSURLRequestCachePolicy.
    internal(set) var cachePolicy = NSURLRequest.CachePolicy.useProtocolCachePolicy
    
    /// The type of parameter encoding to use when encoding request parameters.
    public var parameterEncoding = ParameterEncoding.percent {
        didSet {
            if parameterEncoding == .json {
                contentType = ContentType.json
            }
        }
    }
    
    /// The HTTP `Content-Type` header field value of the request.
    internal(set) var contentType: String? {
        set { headers[Headers.contentType] = newValue }
        get { return headers[Headers.contentType] }
    }
    
    /// The HTTP `User-Agent` header field value of the request.
    internal(set) var userAgent: String? {
        set { headers[Headers.userAgent] = newValue }
        get { return headers[Headers.userAgent] }
    }
    
    // MARK: Initialization
    
    /**
     Intialize a request value.
     
     - parameter method: The HTTP request method.
     - parameter url: The URL string of the HTTP request.
    */
    init(_ method: Method, url: String) {
        self.method = method
        self.url = url
    }
}

// MARK: - URLRequestEncodable

extension Request: URLRequestEncodable {
    /**
     Encode a NSURLRequest based on the value of Request.
     
     - returns: A NSURLRequest encoded based on the Request data.
    */
    public var urlRequestValue: URLRequest {

        let urlRequest = NSMutableURLRequest(url: URL(string: url)!)
        urlRequest.httpMethod = method.rawValue
        urlRequest.cachePolicy = cachePolicy
        
        for (name, value) in headers {
            urlRequest.addValue(value, forHTTPHeaderField: name)
        }
        
        switch method {
        case .GET, .DELETE:
            if let url = urlRequest.url,
                encodedURL = parameterEncoding.encodeURL(url, parameters: parameters) {
                    urlRequest.url = encodedURL
            }
        default:
            if let data = parameterEncoding.encodeBody(parameters) {
                urlRequest.httpBody = data
                
                if urlRequest.value(forHTTPHeaderField: Headers.contentType) == nil {
                    urlRequest.setValue(ContentType.formEncoded, forHTTPHeaderField: Headers.contentType)
                }
            }
        }

        return urlRequest.copy() as! URLRequest
    }
}

// MARK: - Request Options

extension Request {
    
    /// An `Option` value defines a rule for encoding part of a `Request` value.
    public enum Option {
        /// Defines the parameter encoding for the HTTP request.
        case parameterEncoding(Request.ParameterEncoding)
        /// Defines a HTTP header field name and value to set in the `Request`.
        case header(String, String)
        /// Defines the cache policy to set in the `Request` value.
        case cachePolicy(NSURLRequest.CachePolicy)
    }
    
    /// Uses an array of `Option` values as rules for mutating a `Request` value.
    func encodeOptions(_ options: [Option]) -> Request {
        var request = self
        
        for option in options {
            switch option {
                
            case .parameterEncoding(let encoding):
                request.parameterEncoding = encoding
                
            case .header(let name, let value):
                request.headers[name] = value
                
            case .cachePolicy(let cachePolicy):
                request.cachePolicy = cachePolicy
            }
        }
        
        return request
    }
}

// MARK: - Query String

extension Dictionary {
    
    /// Return an encoded query string using the elements in the dictionary.
    var percentEncodedQueryString: String {
        var components = [String]()
        
        for (name, value) in self {
            if let percentEncodedPair = percentEncode((name, value)) {
                components.append(percentEncodedPair)
            }
        }
        
        return components.joined(separator: "&")
    }
    
    /// Percent encode a Key/Value pair.
    func percentEncode(_ element: Element) -> String? {
        let (name, value) = element
        
        let encodedName  = "\(name)".percentEncodeURLQueryCharacters
        let encodedValue = "\(value)".percentEncodeURLQueryCharacters
        return "\(encodedName)=\(encodedValue)"
    }
}

// MARK: - Percent Encoded String

extension String {
    /**
     Returns a new string by replacing all characters allowed in an URL's query 
     component with percent encoded characters.
    */
    var percentEncodeURLQueryCharacters: String {
        let escapedString = CFURLCreateStringByAddingPercentEscapes(
            nil,
            self,
            nil,
            "!*'();:@&=+$,/?%#[]",
            CFStringBuiltInEncodings.UTF8.rawValue
        )
        return escapedString as! String
    }

}

// MARK: - Percent Encoded Query

extension URLComponents {

    /// Append an encoded query string to the existing percentEncodedQuery value.
    func appendPercentEncodedQuery(_ query: String) {
        if percentEncodedQuery == nil {
            percentEncodedQuery = query
        } else {
            percentEncodedQuery = "\(percentEncodedQuery)&\(query)"
        }
    }
}
