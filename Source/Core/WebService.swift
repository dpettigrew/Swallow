//
//  WebService.swift
//  Swallow
//
//  Created by Angelo Di Paolo on 2/16/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import Foundation

/**
  Types conforming to the `SessionDataTaskDataSource` protocol are responsible 
  for creating `NSURLSessionDataTask` objects based on a `NSURLRequest` value 
  and invoking a completion handler after the response of a data task has been 
  received. Adopt this protocol in order to specify the `NSURLSession` instance 
  used to send requests.
*/
public protocol SessionDataTaskDataSource {
    func dataTaskWithRequest(request: NSURLRequest, session: NSURLSession, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask?
}

/**
 A `WebService` value provides a concise API for encoding a NSURLRequest object
 and processing the resulting `NSURLResponse` object.
*/
public struct WebService {
    /// Base URL of the web service.
    public let baseURLString: String
    
    /**
     Set to `false` to prevent `ServiceTask` instances from resuming 
     immediately.
    */
    public var startTasksImmediately = true
    
    /**
     Type responsible for creating a `NSURLSessionDataTask` based on a
     `NSURLRequest`.
    */
    public var dataTaskSource: SessionDataTaskDataSource = DataTaskDataSource()

    public var session: NSURLSession = NSURLSession.sharedSession()

    // MARK: Initialization
    
    /**
     Initialize a web service value.
     - parameter baseURLString: URL string to use as the base URL of the web service.
    */
    public init(baseURLString: String) {
        self.baseURLString = baseURLString
    }
}

// MARK: - Web Service API

extension WebService {
    /**
    Create a service task for a `GET` HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded as
    a query string for `GET` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request. The newly created task is resumed immediately if the
    `startTasksImmediately` poperty is set to `true`.
    */
    public func GET(path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        return request(.GET, path: path, parameters: parameters, options: options)
    }
    
    /**
    Create a service task for a `POST` HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded and
    is set as the HTTP body for `POST` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request. The newly created task is resumed immediately if the
    `startTasksImmediately` poperty is set to `true`.
    */
    public func POST(path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        return request(.POST, path: path, parameters: parameters, options: options)
    }
    
    /**
    Create a service task for a PUT HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded and
    is set as the HTTP body for `PUT` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request. The newly created task is resumed immediately if the
    `startTasksImmediately` poperty is set to `true`.
    */
    public func PUT(path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        return request(.PUT, path: path, parameters: parameters, options: options)
    }
    
    /**
    Create a service task for a DELETE HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded and
    is set as the HTTP body for `DELETE` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request. The newly created task is resumed immediately if the
    `startTasksImmediately` poperty is set to `true`.
    */
    public func DELETE(path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        return request(.DELETE, path: path, parameters: parameters, options: options)
    }
    
    /**
    Create a service task for a HEAD HTTP request.
    
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters. The data is URL encoded as
    a query string for `HEAD` requests.
    - parameter options: Endpoint options used to configure the HTTP request.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request. The newly created task is resumed immediately if the
    `startTasksImmediately` poperty is set to `true`.
    */
    public func HEAD(path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        return request(.HEAD, path: path, parameters: parameters, options: options)
    }
}

// MARK: - RequestEncoder

extension WebService: RequestEncoder {
    /// Encode a Request value
    func encodeRequest(method: Request.Method, url: String, parameters: [String : AnyObject]?, options: [Request.Option]?) -> Request {
        var request = Request(method, url: url)
        
        if let parameters = parameters {
            request.parameters = parameters
        }
        
        if let options = options {
            request = request.encodeOptions(options)
        }
        
        return request
    }
    
    /**
    Create a `ServiceTask`
    
    - parameter urlRequestEncoder: Type that provides the encoded NSURLRequest value.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request. The newly created task is resumed immediately if the
    `startTasksImmediately` poperty is set to `true`.
    */
    func serviceTask(urlRequestEncodable urlRequestEncodable: URLRequestEncodable, session: NSURLSession) -> ServiceTask {
        let task = ServiceTask(urlRequestEncodable: urlRequestEncodable, dataTaskSource: dataTaskSource, session: session)
        
        if startTasksImmediately {
            task.resume()
        }
        
        return task
    }
    
    /**
    Create a service task to fulfill a service request. By default the service
    task is started by calling resume(). To prevent service tasks from
    automatically resuming set the `startTasksImmediately` of the WebService
    value to `false`.
    
    - parameter method: HTTP request method.
    - parameter path: Request path. The value can be relative to the base URL string
    or absolute.
    - parameter parameters: Optional request parameters.
    - parameter options: Optional endpoint options used to configure the HTTP request.
    - returns: A ServiceTask instance that refers to the lifetime of processing
    a given request. The newly created task is resumed immediately if the
    `startTasksImmediately` poperty is set to `true`.
    */
    func request(method: Request.Method, path: String, parameters: [String : AnyObject]? = nil, options: [Request.Option]? = nil) -> ServiceTask {
        let request = encodeRequest(method, url: absoluteURLString(path), parameters: parameters, options: options)
        return serviceTask(urlRequestEncodable: request, session: session)
    }
}

// MARK: - URL String Construction

extension WebService {
    /**
     Return an absolute URL string relative to the baseURLString value.
    
     - parameter string: URL string.
     - returns: An absoulte URL string relative to the value of `baseURLString`.
    */
    public func absoluteURLString(string: String) -> String {
        return constructURLString(string, relativeToURLString: baseURLString)
    }
    
    /**
     Return an absolute URL string relative to the baseURLString value.
    
     - parameter string: URL string value.
     - parameter relativeURLString: Value of relative URL string.
     - returns: An absolute URL string.
    */
    func constructURLString(string: String, relativeToURLString relativeURLString: String) -> String {
        let relativeURL = NSURL(string: relativeURLString)
        return NSURL(string: string, relativeToURL: relativeURL)!.absoluteString
    }
}

// MARK: - SessionDataTaskDataSource

struct DataTaskDataSource: SessionDataTaskDataSource {
    func dataTaskWithRequest(request: NSURLRequest, session: NSURLSession, completion: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask? {
        return session.dataTaskWithRequest(request, completionHandler: completion);
    }
}
