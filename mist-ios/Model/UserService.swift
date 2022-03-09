//
//  UserService.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

//QUESTION FOR LATER: do we need a UserService for when looking at another user's profile? or can we just load their info into a struct and thats it
//we def dont want to let them use this UserService because it includes functions like createAccount

class UserService: NSObject {

    private let loggedOutUser: User = User(id: "", username: "", email: "", firstName: "", lastName: "", authoredPosts: [])
    private var user: User!
    private var myAccountFileLocation: URL!
    
    static var myAccount = UserService()
    static var isLoggedIn: Bool = false
    
    //private initializer because there will only be one singleton of UserService
    private override init(){
        super.init()
        user = User(id: "userid", username: "username", email: "eemeyeel", firstName: "fname", lastName: "lname", authoredPosts: [])
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.myAccountFileLocation = documentsDirectory.appendingPathComponent("myaccount.json")
        
        if FileManager.default.fileExists(atPath: self.myAccountFileLocation.path) {
            loadUserFromFilesystem();
        }
    }
    
//    //this function is required at startup so that the singleton is created and isLoggedIn is properly initialized
//    static func isLoggedInOnStartup() -> Bool {
//        print(UserService.isLoggedIn)
//        return UserService.isLoggedIn
//    }
    
    //MARK: -Auth
    
    //might need to change these parameters
    func createAccount(userId: String, username: String, email: String, firstName: String, lastName: String) {
        let newUser = User(id: userId, username: username, email: email, firstName: firstName, lastName: lastName, authoredPosts: []);
        UserService.isLoggedIn = true;
        self.user = newUser;
        saveUserToFilesystem();
        //TODO: db call
    }
    
    func logOut(user: User) {
        UserService.isLoggedIn = false;
        self.user = loggedOutUser;
        eraseUserFromFilesystem();
    }
    
    func deleteMyAccount(user: User) {
        logOut(user: user);
        //TODO: delete user from database
    }
    
    //MARK: -Getters
    
    func getId() -> String { return user.id; }
    func getUsername() -> String { return user.username; }
    func getFirstName() -> String { return user.firstName; }
    func getLastName() -> String { return user.lastName; }
    func getEmail() -> String { return user.email; }
    func getAuthoredPosts() -> [Post] { return user.authoredPosts; }
    
    //MARK: -Setters
    
    func updateUsername(to newUsername: String) {
        //TODO: db calls (first ensure email is not used)
        user.username = newUsername;
        saveUserToFilesystem();
    }
    
    func updateFirstName(to newFirstName: String) {
        //TODO: db calls
        user.firstName = newFirstName;
        saveUserToFilesystem();
    }
    
    func updateLastName(to newLastName: String) {
        //TODO: db calls
        user.lastName = newLastName;
        saveUserToFilesystem();
    }
    
    func updateEmail(to newEmail: String) {
        //TODO: db calls (first check they own the email)
        user.email = newEmail;
        saveUserToFilesystem();
    }
    
    //MARK: -Actions
    
    func addPost(post: Post) {
        if !user.authoredPosts.isEmpty {
            user.authoredPosts.append(post);
        }
        else { //else if adding the first post
            user.authoredPosts = [post]
        }
        saveUserToFilesystem();
        //the firestore update is handled on PostService side
    }
    
    func deletePost(at index: Int) {
        if !user.authoredPosts.isEmpty {
            user.authoredPosts.remove(at: index);
        }
        saveUserToFilesystem();
        //the firestore update is hanlded on PostService side. TODO: change how these calls are made. should a new post update just be handled by userservice or postservice from the controller side?
    }
    
    
    
    //MARK: -Filesystem
    
    func saveUserToFilesystem() {
        do {
            print("SAVING USER DATA")
            let encoder = JSONEncoder()
            let data: Data = try encoder.encode(user)
            let jsonString = String(data: data, encoding: .utf8)!
            try jsonString.write(to: self.myAccountFileLocation, atomically: true, encoding: .utf8)
        } catch {
            print("error writing to file system: \(error)")
        }
    }
    
    func loadUserFromFilesystem() {
        do {
            print("LOADING USER DATA")
            let data = try Data(contentsOf: self.myAccountFileLocation)
            let decoder = JSONDecoder()
            user = try decoder.decode(User.self, from: data);
            UserService.isLoggedIn = true;
        } catch {
            print("error reading data from filesystem: \(error)")
        }
    }
    
    func eraseUserFromFilesystem() {
        do {
            print("ERASING USER DATA")
            try FileManager.default.removeItem(at: self.myAccountFileLocation)
        } catch {
            print("error erasing user from filesystem")
        }
    }
    
}

