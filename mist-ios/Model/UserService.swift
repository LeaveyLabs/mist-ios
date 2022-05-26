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
    
    private var authedUser: AuthedUser?
    private var localFileLocation: URL!
    
    //private initializer because there will only ever be one instance of UserService, the singleton
    private override init(){
        super.init()

        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        localFileLocation = documentsDirectory.appendingPathComponent("myaccount.json")
        if FileManager.default.fileExists(atPath: localFileLocation.path) {
            loadUserFromFilesystem();
        }
    }
    
    // Called on startup so that the singleton is created and isLoggedIn is properly initialized
    func isLoggedIn() -> Bool {
        return authedUser != nil
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
    }
    
    func logIn(username: String,
               password: String) async throws {
        let token:String = try await AuthAPI.fetchAuthToken(username: username,
                                                           password: password)
        // DB update
        setGlobalAuthToken(token: token)
        authedUser = try await UserAPI.fetchUserByToken(token: token)
        // Local update
        saveUserToFilesystem()
    }
    
    func logOut() {
        eraseUserFromFilesystem()
        authedUser = nil
        setGlobalAuthToken(token: "")
    }
    
    func deleteMyAccount() async throws {
        try await UserAPI.deleteUser(id: authedUser!.id)
        logOut()
    }
    
    //MARK: - Getters
    
    func getId() -> Int? { return authedUser?.id; }
    func getUsername() -> String? { return authedUser?.username; }
    func getFirstName() -> String? { return authedUser?.first_name; }
    func getLastName() -> String? { return authedUser?.last_name; }
    func getEmail() -> String? { return authedUser?.email; }
//    func getAuthoredPosts() -> [Post] { return authedUser.authoredPosts; }
    func getUser() -> AuthedUser? { return authedUser}
    
    //MARK: - Update account
    
    // No need to return new profilePic bc it is updated globally
    func updateUsername(to newUsername: String) async throws {
        //DB and local update
        authedUser = try await UserAPI.patchUsername(username: newUsername, user: authedUser!)
        saveUserToFilesystem()
    }
    
    // No need to return new profilePic bc it is updated globally
    func updateProfilePic(to newProfilePic: UIImage) async throws {
        // DB and local update
        authedUser = try await UserAPI.patchProfilePic(image: newProfilePic, user: authedUser!)
        saveUserToFilesystem();
    }
    
    //MARK: - Create content
    
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
        // Local update (of the user's authoredPosts)
        authedUser = try await UserAPI.fetchAuthedUsersByUsername(username: authedUser!.username)[0]
        saveUserToFilesystem()
        return newPost
    }
    
//    func deletePost(at index: Int) async throws {
//        if !authedUser.authoredPosts.isEmpty && index >= 0 && index < authedUser.authoredPosts.count {
//            // DB update
//            try await PostAPI.deletePost(id: authedUser.authoredPosts[index].id)
//            // Local update (of the user's authoredPosts)
//            authedUser = try await UserAPI.fetchUsersByUsername(username: authedUser.username)[0] as! AuthedUser
//            saveUserToFilesystem()
//            //TODO: force reload all posts everywhere? otherwise your post might still exist on some other view controller's postservice
//        }
//    }
    
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

