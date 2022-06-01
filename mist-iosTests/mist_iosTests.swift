//
//  mist_iosTests.swift
//  mist-iosTests
//
//  Created by Adam Novak on 2022/02/25.
//

import XCTest
@testable import mist_ios

class mist_iosTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        setGlobalAuthToken(token: TestConstants.Auth.TOKEN)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        setGlobalAuthToken(token: "")
    }

    // BasicAPITest
    
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
        } catch APIError.InvalidParameters {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.POST.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch APIError.InvalidParameters {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.PUT.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch APIError.InvalidParameters {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.PATCH.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch APIError.InvalidParameters {}
        
        do {
            let _ = try await BasicAPI.basicHTTPCallWithoutToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch APIError.InvalidParameters {}
        
        // With Token
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.GET.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch APIError.InvalidParameters {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.POST.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch APIError.InvalidParameters {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.PUT.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch APIError.InvalidParameters {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.PATCH.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch APIError.InvalidParameters {}
        
        do {
            let _ = try await BasicAPI.baiscHTTPCallWithToken(url: VALID_URL, jsonData: Data(), method: HTTPMethods.DELETE.rawValue)
        } catch APIError.CouldNotConnect {
            XCTFail(ERROR_THROWN_MESSAGE)
        } catch APIError.InvalidParameters {}
    }
    
    // AUTH CONSTANTS
    struct TestConstants {
        struct Auth {
            static let TOKEN = "13929afc3930c2a332ee7e53af3d2dc62f904fc7"
            static let ID = 1
            static let EMAIL = "testingadmin@invaliddomain.com"
            static let USERNAME = "testingadmin"
            static let PASSWORD = "randomstringofcharacters1234"
            static let FIRST_NAME = "testing"
            static let LAST_NAME = "admin"
            static let authedUser = AuthedUser(id: ID,
                                               username: USERNAME,
                                               first_name: FIRST_NAME,
                                               last_name: LAST_NAME,
                                               picture: nil,
                                               email: EMAIL,
                                               password: PASSWORD)
        }
    }
    
    // AuthAPITest
    func testFetchAuthToken() async throws {
        let token = try await AuthAPI.fetchAuthToken(username: TestConstants.Auth.USERNAME, password: TestConstants.Auth.PASSWORD)
        XCTAssert(token == TestConstants.Auth.TOKEN)
    }
    
    func testRegisterEmail() async throws {
        do {
            try await AuthAPI.registerEmail(email: "kevinsun@usc.edu")
        } catch {
            XCTFail("Could not register email.")
        }
    }
    
    func testValidateEmail() async throws {
        do {
            try await AuthAPI.validateEmail(email: "kevinsun@usc.edu", code: "123456")
            XCTFail("Invalid validation was successful")
        } catch {}
    }
    
    func testCreateUser() async throws {
        do {
            let _ = try await AuthAPI.createUser(username: "kevinsun", first_name: "Kevin", last_name: "Sun", picture: UIImage(), email: "kevinsun@usc.edu", password: "fakePass1234")
            XCTFail("Invalid create user request was successful")
        } catch {}
    }
    
    // UserAPITest

    // GET by id
    func testGetUserById() async throws  {
        let user = try await UserAPI.fetchUsersByUserId(userId: TestConstants.Auth.ID)
        XCTAssertTrue(user.id == TestConstants.Auth.ID)
    }
    // GET by first name
    func testGetUsersByFirstName() async throws {
        let users = try await UserAPI.fetchUsersByFirstName(firstName: TestConstants.Auth.FIRST_NAME)
        XCTAssertTrue(users[0].first_name == TestConstants.Auth.FIRST_NAME)
    }
    // GET by last name
    func testGetUsersByLastName() async throws {
        let users = try await UserAPI.fetchUsersByLastName(lastName: TestConstants.Auth.LAST_NAME)
        XCTAssertTrue(users[0].last_name == TestConstants.Auth.LAST_NAME)
    }
    // GET by username
    func testGetUsersByUsername() async throws {
        let users = try await UserAPI.fetchUsersByUsername(username: TestConstants.Auth.USERNAME)
        XCTAssertTrue(users[0].username == TestConstants.Auth.USERNAME)
    }
    // GET by text
    func testGetUsersByText() async throws {
        let users = try await UserAPI.fetchUsersByText(containing: TestConstants.Auth.USERNAME)
        XCTAssertTrue(users[0].username == TestConstants.Auth.USERNAME)
    }
    // GET by token
    func testGeAuthedUserByToken() async throws {
        let user =  try await UserAPI.fetchAuthedUserByToken(token: TestConstants.Auth.TOKEN)
        XCTAssertTrue(user.id == TestConstants.Auth.ID)
    }
    // PATCH username
    func testPatchUserUsername() async throws {
        let user = try await UserAPI.patchUsername(username: TestConstants.Auth.USERNAME, user: TestConstants.Auth.authedUser)
        XCTAssertTrue(user.username == TestConstants.Auth.USERNAME)
    }
    // PATCH password
    func testPatchUserPassword() async throws {
        let user = try await UserAPI.patchPassword(password: TestConstants.Auth.PASSWORD, user: TestConstants.Auth.authedUser)
        XCTAssertTrue(user.username == TestConstants.Auth.USERNAME)
    }
    // PATCH picture
    func testPatchUserPicture() async throws {
        let picture = try await UserAPI.UIImageFromURLString(url: "https://cdn.cocoacasts.com/cc00ceb0c6bff0d536f25454d50223875d5c79f1/above-the-clouds.jpg")
        let user = try await UserAPI.patchProfilePic(image: picture, user: TestConstants.Auth.authedUser)
        XCTAssertTrue(user.id == TestConstants.Auth.ID)
    }
    
    // PostAPITest
    
    // POST
    func testPostPost() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        XCTAssertTrue(post.title == "hey")
    }
    
    // GET by latitude and longitude
    func testGetPostByLatitudeLongitude() async throws {
        let posts = try await PostAPI.fetchPostsByLatitudeLongitude(latitude: 1.0, longitude: 2.0)
        XCTAssertTrue(posts[0].title == "hey")
    }
    // GET by text
    func testGetPostByText() async throws {
        let posts = try await PostAPI.fetchPostsByText(text: "hey")
        XCTAssertTrue(posts[0].title == "hey")
    }
    // GET by author
    func testGetPostByAuthor() async throws {
        let posts = try await PostAPI.fetchPostsByAuthor(userId: TestConstants.Auth.ID)
        XCTAssertTrue(posts[0].title == "hey")
    }
    
    // DELETE
    func testDeletePost() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        try await PostAPI.deletePost(id: post.id)
    }
        
    // WordAPITest
    // GET words
    func testGetWordByText() async throws {
        let _ = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let word = try await WordAPI.fetchWords(text: "hey")
        XCTAssertTrue(word[0].text == "hey")
    }
    
    // CommentAPITest
    // POST
    func testPostComment() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        do {
            let comment = try await CommentAPI.postComment(text: "hey", post: post.id, author: TestConstants.Auth.ID)
            XCTAssertTrue(comment.text == "hey")
        } catch {
            print(error)
        }
    }
    // GET by postId
    func testGetCommentByPostId() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let comment = try await CommentAPI.postComment(text: "hey", post: post.id, author: TestConstants.Auth.ID)
        let comments = try await CommentAPI.fetchCommentsByPostID(post: post.id)
        XCTAssertTrue(comments[0].text == "hey")
    }
    // DELETE
    func testDeleteComment() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let comment = try await CommentAPI.postComment(text: "hey", post: post.id, author: TestConstants.Auth.ID)
        try await CommentAPI.deleteComment(commentId: comment.id)
    }
    
    // VoteAPITest
    // POST
    func testPostVote() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let vote = try await VoteAPI.postVote(voter: TestConstants.Auth.ID, post: post.id, rating: 5)
        XCTAssertTrue(vote.voter == TestConstants.Auth.ID)
    }
    // DELETE
    func testDeleteVote() async throws {
        let post = try await PostAPI.createPost(title: "hey", text: "bro", locationDescription: "bruh", latitude: 0, longitude: 1.0, timestamp: 2.0, author: TestConstants.Auth.ID)
        let vote = try await VoteAPI.postVote(voter: TestConstants.Auth.ID, post: post.id, rating: 5)
        try await VoteAPI.deleteVote(voter: vote.voter, post: vote.post)
    }
    
    // FlagAPITest
    // TagAPITest
    // BlockAPITest
    // MessageAPITest
    // FriendRequestAPITest

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
