//
//  SessionDataTaskDataSource.swift
//  ELWebService
//
//  Created by Angelo Di Paolo on 11/3/15.
//  Copyright © 2015 WalmartLabs. All rights reserved.
//

import Foundation

/**
 Types conforming to the `SessionDataTaskDataSource` protocol are responsible
 for creating `URLSessionDataTask` objects based on a `URLRequest` value
 and invoking a completion handler after the response of a data task has been
 received. Adopt this protocol in order to specify the `URLSession` instance
 used to send requests.
 */
public protocol SessionDataTaskDataSource: class, Session {
    func dataTask(with request: URLRequest, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTask
}

extension SessionDataTaskDataSource {
    public func dataTask(with request: URLRequest, completionHandler: (Data?, URLResponse?, NSError?) -> Void) -> URLSessionDataTask {
        return dataTask(with:request.urlRequestValue, completionHandler: completionHandler)
    }
}

extension URLSession: SessionDataTaskDataSource {}
