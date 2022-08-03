//
//  BasicAPITest.swift
//  mist-iosTests
//
//  Created by Kevin Sun on 6/9/22.
//

import XCTest
@testable import mist_ios

class BasicAPITest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // Throw error with invalid URL
    func testInvalidURLThrowsError() async throws {
        let NO_ERROR_THROWN_MESSAGE = "No error thrown."
        let INVALID_URL = "invalidURL"
        
        // Without Token
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: INVALID_URL, jsonData: Data(), method: HTTPMethods.GET.rawValue)
            XCTFail(NO_ERROR_THROWN_MESSAGE)
        } catch APIError.CouldNotConnect {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: INVALID_URL, jsonData: Data(), method: HTTPMethods.POST.rawValue)
            XCTFail(NO_ERROR_THROWN_MESSAGE)
        } catch APIError.CouldNotConnect {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: INVALID_URL, jsonData: Data(), method: HTTPMethods.PUT.rawValue)
            XCTFail(NO_ERROR_THROWN_MESSAGE)
        } catch APIError.CouldNotConnect {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: INVALID_URL, jsonData: Data(), method: HTTPMethods.PATCH.rawValue)
            XCTFail(NO_ERROR_THROWN_MESSAGE)
        } catch APIError.CouldNotConnect {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: INVALID_URL, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
            XCTFail(NO_ERROR_THROWN_MESSAGE)
        } catch APIError.CouldNotConnect {}
        
        // With Token
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: INVALID_URL, jsonData: Data(), method: HTTPMethods.GET.rawValue)
            XCTFail(NO_ERROR_THROWN_MESSAGE)
        } catch APIError.CouldNotConnect {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: INVALID_URL, jsonData: Data(), method: HTTPMethods.POST.rawValue)
            XCTFail(NO_ERROR_THROWN_MESSAGE)
        } catch APIError.CouldNotConnect {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: INVALID_URL, jsonData: Data(), method: HTTPMethods.PUT.rawValue)
            XCTFail(NO_ERROR_THROWN_MESSAGE)
        } catch APIError.CouldNotConnect {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: INVALID_URL, jsonData: Data(), method: HTTPMethods.PATCH.rawValue)
            XCTFail(NO_ERROR_THROWN_MESSAGE)
        } catch APIError.CouldNotConnect {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: INVALID_URL, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
            XCTFail(NO_ERROR_THROWN_MESSAGE)
        } catch APIError.CouldNotConnect {}
    }
    
    // Return data and response with valid URL
    func testValidURLReturnDataAndResponse() async throws {
        let ERROR_THROWN_MESSAGE = "Error thrown."
        let VALID_URL = "https://mist-backend-test.herokuapp.com/api/"
        
        // Without Token
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.POST.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.PUT.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.PATCH.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch {}
        
        // With Token
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.POST.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.PUT.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.PATCH.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch {}
    }
}
