//
//  WebServiceTests.swift
//  THGWebService
//
//  Created by Angelo Di Paolo on 3/11/15.
//  Copyright (c) 2015 TheHolyGrail. All rights reserved.
//

import UIKit
import XCTest
import THGWebService

class WebServiceTests: XCTestCase {
    
    // MARK: Utilities
    
    var baseURL: String {
        get {
            return "http://httpbin.org/"
        }
    }
    
    func responseHandler(expectation: XCTestExpectation) -> (Data?, URLResponse?) -> Void {
        return { data, response in
            
            let httpResponse = response as! HTTPURLResponse
            
            if httpResponse.statusCode == 200 {
                expectation.fulfill()
            }
        }
    }
    
    func jsonResponseHandler(expectation: XCTestExpectation) -> (AnyObject?) -> Void {
        return { json in
            
            if json is NSDictionary {
                expectation.fulfill()
            }
        }
    }

    // MARK: Tests  
    
    func testGetEndpoint() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
                    .GET("/get")
                    .response(handler)
        
        XCTAssertEqual(task.state, URLSessionTask.State.Running, "Task should be running by default")
        waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testAbsoluteURLString() {
        let service = WebService(baseURLString: "http://www.walmart.com/")
        let url = service.absoluteURLString("/foo")
        XCTAssertEqual(url, "http://www.walmart.com/foo")
    }
    
    /// Verify that absolute paths work against a different base URL.
    func testGetAbsolutePath() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: "www.walmart.com")
        let task = service
            .GET("http://httpbin.org/get")
            .response(handler)
        
        XCTAssertEqual(task.state, URLSessionTask.State.Running, "Task should be running by default")
        waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testPostEndpoint() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .POST("/post")
            .response(handler)
        
        XCTAssertEqual(task.state, URLSessionTask.State.Running, "Task should be running by default")
        waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testPutEndpoint() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .PUT("/put")
            .response(handler)
        
        XCTAssertEqual(task.state, URLSessionTask.State.Running, "Task should be running by default")
        waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testDeleteEndpoint() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let handler = responseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .DELETE("/delete")
            .response(handler)
        
        XCTAssertEqual(task.state, URLSessionTask.State.Running, "Task should be running by default")
        waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testDisableStartTasksImmediately() {
        let baseURL = "http://httpbin.org/"
        
        var service = WebService(baseURLString: baseURL)
        service.startTasksImmediately = false
        
        let task = service.GET("/get")

        XCTAssertEqual(task.state, URLSessionTask.State.Suspended, "Task should be suspended when startTasksImmediately is disabled")
    }

    func testErrorHandler() {
        let baseURL = "httpppppp://httpbin.org/"
        let errorExpectation = expectation(withDescription: "Error handler called for bad URL")
        var wasResponseCalled = false
        
        WebService(baseURLString: baseURL)
            .GET("/")
            .response { data, response in
                wasResponseCalled = true
            }
            .responseError { error in
                XCTAssertFalse(wasResponseCalled, "Response should not be called for error cases")
                errorExpectation.fulfill()
            }
        
        waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testSpecifyingResponseHandlerQueue() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let backgroundExpectation = expectation(withDescription: "Background handler ran")
        let service = WebService(baseURLString: baseURL)
        let queue = DispatchQueue.global(Int(UInt64(DispatchQueueAttributes.qosBackground.rawValue)), 0)

        let task = service
            .GET("/get")
            .response(queue) { data, response in
                backgroundExpectation.fulfill()
            }
            .response { data, response in
                successExpectation.fulfill()
        }
        
        XCTAssertEqual(task.state, URLSessionTask.State.Running, "Task should be running by default")
        waitForExpectations(withTimeout: 4, handler: nil)
    }
    
    func testGetJSON() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let handler = jsonResponseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let task = service
            .GET("/get")
            .responseJSON(handler)
        
        XCTAssertEqual(task.state, URLSessionTask.State.Running, "Task should be running by default")
        waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testGetJSONWithSpecificQueue() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let handler = jsonResponseHandler(expectation: successExpectation)
        let service = WebService(baseURLString: baseURL)
        let queue = DispatchQueue.global(Int(UInt64(DispatchQueueAttributes.qosBackground.rawValue)), 0)
        let task = service
            .GET("/get")
            .responseJSON(queue, handler: handler)
        
        XCTAssertEqual(task.state, URLSessionTask.State.Running, "Task should be running by default")
        waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testGetPercentEncodedParameters() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
        service
            .GET("/get", parameters: parameters)
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)

                let deliveredParameters = castedJSON!["args"] as? [String : AnyObject]
                XCTAssert(deliveredParameters != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
            }
        
        waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testPostPercentEncodedParameters() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "percentEncoded" : "this needs percent encoded"]
        
        service
            .POST("/post", parameters: parameters)
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredParameters = castedJSON!["form"] as? [String : AnyObject]
                XCTAssert(deliveredParameters != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
        }
        
        waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testPostJSONEncodedParameters() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let service = WebService(baseURLString: baseURL)
        let parameters = ["foo" : "bar", "number" : 42]
        
        service
            .POST("/post",
                parameters: parameters,
                options: [.ParameterEncoding(.JSON)])
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredParameters = castedJSON!["json"] as? [String : AnyObject]
                XCTAssert(deliveredParameters != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredParameters!, toOriginalParameters: parameters)
        }
        
        waitForExpectations(withTimeout: 2, handler: nil)
    }
    
    func testHeadersDelivered() {
        let successExpectation = expectation(withDescription: "Received status 200")
        let service = WebService(baseURLString: baseURL)
        let headers = ["Some-Test-Header" :"testValue"]
        
        service
            .GET("/get",
                parameters: nil,
                options: [.Header("Some-Test-Header", "testValue")])
            .response { data, response in
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    successExpectation.fulfill()
                }
            }
            .responseJSON { json in
                let castedJSON = json as? [String : AnyObject]
                XCTAssert(castedJSON != nil)
                
                let deliveredHeaders = castedJSON!["headers"] as? [String : AnyObject]
                XCTAssert(deliveredHeaders != nil)
                
                RequestTests.assertRequestParametersNotEqual(deliveredHeaders!, toOriginalParameters: headers)
        }
        
        waitForExpectations(withTimeout: 2, handler: nil)
    }
}

