//
//  UserService.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

// Q: Should UserService have a PostService within it?

class UserService: NSObject {
    
    static var singleton = UserService()
    
    private var authedUser: AuthedUser! // consider making authedUser an AuthedUser? so that isLoggedIn = authedUser != nil
    private var isLoggedIn: Bool = false
    private let guestUser = AuthedUser(id: -1, username: "guest", first_name: "First", last_name: "Last", picture: nil, email: "guest@usc.edu", password: "password", authoredPosts: [])
    private let kevinsun = AuthedUser(id: 1, username: "kevinsun", first_name: "Kevin", last_name: "Sun", picture: nil, email: "kevinsun@usc.edu", password: "password", authoredPosts: [])
    private var localFileLocation: URL!
    
    //private initializer because there will only ever be one instance of UserService, the singleton
    private override init(){
        super.init()
        authedUser = kevinsun

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.localFileLocation = documentsDirectory.appendingPathComponent("myaccount.json")
        if FileManager.default.fileExists(atPath: self.localFileLocation.path) {
            loadUserFromFilesystem();
        }
    }
    
    // Called on startup so that the singleton is created and isLoggedIn is properly initialized
    static func isLoggedIn() -> Bool {
        return singleton.isLoggedIn
    }
    
    //MARK: - Auth
    
    // No need to return new user from createAccount() bc new user is globally updated within this function
    func createUser(username: String,
                    firstName: String,
                    lastName: String,
                    picture: String?,
                    email: String,
                    password: String) async throws {
        // DB update
        authedUser = try await AuthAPI.createUser(username: username,
                                            first_name: firstName,
                                            last_name: lastName,
                                            picture: picture,
                                            email: email,
                                            password: password)
        let token:String = try await AuthAPI.fetchAuthToken(username: username,
                                                           password: password)
        // Local update
        setGlobalAuthToken(token: token)
        saveUserToFilesystem()
        isLoggedIn = true
    }
    
    func logIn(username: String,
               password: String) async throws {
        let token:String = try await AuthAPI.fetchAuthToken(username: username,
                                                           password: password)
        // DB update
        authedUser = try await UserAPI.fetchUserByToken(token: token)
        // Local update
        setGlobalAuthToken(token: token)
        saveUserToFilesystem()
        isLoggedIn = true
    }
    
    func logOut() {
        authedUser = guestUser;
        
        setGlobalAuthToken(token: nil)
        eraseUserFromFilesystem();
        isLoggedIn = false;
    }
    
    func deleteMyAccount() {
        logOut()
        //TODO: delete user from database
        UserAPI.deleteUser(id: getId())
    }
    
    //MARK: - Getters
    
    func getId() -> Int { return authedUser.id; }
    func getUsername() -> String { return authedUser.username; }
    func getFirstName() -> String { return authedUser.first_name; }
    func getLastName() -> String { return authedUser.last_name; }
    func getEmail() -> String { return authedUser.email; }
    func getAuthoredPosts() -> [Post] { return authedUser.authoredPosts; }
    func getUser() -> AuthedUser { return authedUser }
    
    //MARK: - Setters
    
    func updateUsername(to newUsername: String) {
        //TODO: db calls (first ensure email is not used)
        //set authedUser to the return value from db call
        saveUserToFilesystem();
    }
    
    func updateFirstName(to newFirstName: String) {
        //TODO: db calls
        //set authedUser to the return value from db call
        saveUserToFilesystem();
    }
    
    func updateLastName(to newLastName: String) {
        //TODO: db calls
        //set authedUser to the return value from db call
        saveUserToFilesystem();
    }
    
    // No need to return new profile because it is globally updated within this function
    func updateProfilePic(to newProfilePic: UIImage) async throws {
        // DB update
        let userWithUpdatedProfilePic = try await UserAPI.patchProfilePic(image: newProfilePic, user: authedUser)
        // Local update
        authedUser = userWithUpdatedProfilePic
    }
    
    //MARK: - User Interaction
    
    //TODO: rewrite 
    // Returns the error message to be displayed to the user
    func uploadPost(title: String,
                    text: String,
                    locationDescription: String?,
                    latitude: Double?,
                    longitude: Double?) async throws -> Post {
        // DB update
        let newPost = try await PostAPI.createPost(title: title,
                                                   text: text,
                                                   locationDescription: locationDescription,
                                                   latitude: latitude,
                                                   longitude: longitude)
        // Local update
        authedUser = try await UserAPI.fetchUsersByUsername(username: authedUser.username)[0] as! AuthedUser // Updates the local user's authoredPosts
        saveUserToFilesystem()
        return newPost
    }
    
    //
    func deletePost(at index: Int) async throws {
        if !authedUser.authoredPosts.isEmpty && index >= 0 && index < authedUser.authoredPosts.count {
            // DB Update
            try await PostAPI.deletePost(id: authedUser.authoredPosts[index].id)
            //Local Update
            //TODO: set local authedUser to return from DB call
            saveUserToFilesystem()
            //TODO: force reload all posts everywhere? otherwise your post might still exist on some other view controller's postservice
        }
    }
    
    func uploadComment(text: String, postId: Int, author: Int) async throws -> (Comment, Post) {
        let newComment = try await CommentAPI.postComment(text: text, post: postId, author: author)
        let newPost = try await PostAPI.fetchPosts(post: postId)[0]
        return (newComment, newPost)
    }
    
    func deleteComment(commentId: Int, postId: Int) async throws -> Post {
        try await CommentAPI.deleteComment(comment: commentId)
        let newPost = try await PostAPI.fetchPosts(post: postId)[0]
        return newPost
    }
    
    //MARK: - Filesystem
    
    func saveUserToFilesystem() {
        do {
            print("SAVING USER DATA")
            let encoder = JSONEncoder()
            let data: Data = try encoder.encode(authedUser)
            let jsonString = String(data: data, encoding: .utf8)!
            try jsonString.write(to: self.localFileLocation, atomically: true, encoding: .utf8)
        } catch {
            print("\(error)")
        }
    }
    
    func loadUserFromFilesystem() {
        do {
            print("LOADING USER DATA")
            let data = try Data(contentsOf: self.localFileLocation)
            authedUser = try JSONDecoder().decode(AuthedUser.self, from: data);
            UserService.singleton.isLoggedIn = true;
        } catch {
            print("\(error)")
        }
    }
    
    func eraseUserFromFilesystem() {
        do {
            print("ERASING USER DATA")
            try FileManager.default.removeItem(at: self.localFileLocation)
        } catch {
            print("\(error)")
        }
    }
    
}

