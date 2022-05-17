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
    
    private var user: User!
    private var isLoggedIn: Bool = false
    private let guestUser: User = User(id: "",email: "", profile: Profile(username: "", first_name: "", last_name: "", picture: nil, user: 0), authoredPosts: [])
    private var localFileLocation: URL!
    
    //private initializer because there will only ever be one instance of UserService, the singleton
    private override init(){
        super.init()
        user = guestUser

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
    
    func createAccount(userId: String, username: String, password: String, email: String, firstName: String, lastName: String) async -> String? {
        do {
            // DB update
            //TODO: AuthAPI should either take the userId generated already, or we should not be creating it locally and it should be returned by AuthAPI.createuser
            try await AuthAPI.createUser(email: email, username: username, password: password, first_name: firstName, last_name: lastName)
            // Local update
            user = User(id: userId,  email: email, profile: Profile(username: "", first_name: "", last_name: "", picture: nil, user: 0), authoredPosts: [])
            saveUserToFilesystem()
            isLoggedIn = true
            return nil
        }
        catch {
            return "\(error)"
        }
    }
    
    func logIn() {
        
    }
    
    func logOut() {
        isLoggedIn = false;
        user = guestUser;
        eraseUserFromFilesystem();
    }
    
    func deleteMyAccount() {
        logOut()
        //TODO: delete user from database
    }
    
    //MARK: - Getters
    
    func getId() -> String { return user.id; }
    func getUsername() -> String { return user.profile.username; }
    func getFirstName() -> String { return user.profile.first_name; }
    func getLastName() -> String { return user.profile.last_name; }
    func getEmail() -> String { return user.email; }
    func getAuthoredPosts() -> [Post] { return user.authoredPosts; }
    func getUser() -> User { return user }
    
    //MARK: - Setters
    
    func updateUsername(to newUsername: String) {
        //TODO: db calls (first ensure email is not used)
        user.profile.username = newUsername;
        saveUserToFilesystem();
    }
    
    func updateFirstName(to newFirstName: String) {
        //TODO: db calls
        user.profile.first_name = newFirstName;
        saveUserToFilesystem();
    }
    
    func updateLastName(to newLastName: String) {
        //TODO: db calls
        user.profile.last_name = newLastName;
        saveUserToFilesystem();
    }
    
    func updateProfilePic(to newProfilePic: UIImage) async -> String? {
        do {
            // DB update
            let newProfile = try await ProfileAPI.putProfilePic(image: newProfilePic, profile: user.profile)
            // Local update
            user.profile = newProfile
            return nil
        }
        catch {
            return "\(error)"
        }
    }
    
    //MARK: - User Interaction
    
    // Returns the error message to be displayed to the user
    func uploadPost(title: String, locationDescription: String?, latitude: Double?, longitude: Double?, message: String) async -> String? {
        let uuid = NSUUID().uuidString;
        let newPost = Post(id: String(uuid.prefix(10)), title: title, text: message, location_description: locationDescription, latitude: latitude, longitude: longitude, timestamp: currentTimeMillis(), author: UserService.singleton.getId(), averagerating: 0, commentcount: 0)
        do {
            // DB update
            try await PostAPI.createPost(post: newPost)
            // Local update
            PostService.homePosts.insert(post: newPost, at: 0)
            if !user.authoredPosts.isEmpty {
                user.authoredPosts.append(newPost);
            }
            else { //else if adding the first post
                user.authoredPosts = [newPost]
            }
            saveUserToFilesystem();
            return nil
        }
        catch {
            return "\(error)" //TODO: create custom error messages
        }
    }
    
    func deletePost(at index: Int) async -> String? {
        do {
            if !user.authoredPosts.isEmpty && index >= 0 && index < user.authoredPosts.count {
                // DB Update
                try await PostAPI.deletePost(id: user.authoredPosts[index].id)
                //Local Update
                user.authoredPosts.remove(at: index)
                saveUserToFilesystem()
                //TODO: force reload all posts everywhere? otherwise your post might still exist on some other view controller's postservice
            }
            return nil
        }
        catch {
            return "\(error)"
        }
    }
    
    func uploadComment(id: String, text: String, timestamp: Double, postId: String, author: String) async -> String? {
        do {
            let newComment = Comment(id: id, text: text, timestamp: timestamp, post: postId, author: author)
            try await CommentAPI.postComment(comment: newComment)
            comments?.append(newComment)
            post.commentcount += 1
            //now we need to make a call to postService.uploadComment
            //it might make most sense to return the new comment back to PostViewController, and then PostViewController calls its postService.uploadComment with the offical new comment
            return nil
        } catch {
            return "\(error)"
        }
    }
    
    func deleteComment() async -> String? {
        return nil
    }
    
    //MARK: - Filesystem
    
    func saveUserToFilesystem() {
        do {
            print("SAVING USER DATA")
            let encoder = JSONEncoder()
            let data: Data = try encoder.encode(user)
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
            let decoder = JSONDecoder()
            user = try decoder.decode(User.self, from: data);
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

