//
//  UserService.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

class UserService: NSObject {
    
    static var singleton = UserService()
    
    private var frontendCompleteUser: FrontendCompleteUser?
    private var localFileLocation: URL!
    
    //private initializer because there will only ever be one instance of UserService, the singleton
    private override init(){
        super.init()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        localFileLocation = documentsDirectory.appendingPathComponent("myaccount.json")
        if FileManager.default.fileExists(atPath: localFileLocation.path) {
            loadUserFromFilesystem()
        }
    }
    
    // Called on startup so that the singleton is created and isLoggedIn is properly initialized
    func isLoggedIn() -> Bool {
        return frontendCompleteUser != nil
    }
    
    //MARK: - Auth
    
    // No need to return new user from createAccount() bc new user is globally updated within this function
    func createUser(username: String,
                    firstName: String,
                    lastName: String,
                    profilePic: UIImage,
                    email: String,
                    password: String) async throws {
        // DB update
        let token = try await AuthAPI.fetchAuthToken(username: username,
                                                     password: password)
        setGlobalAuthToken(token: token)
        let newProfilePicWrapper = ProfilePicWrapper(image: profilePic, withCompresssion: true)
        let compressedProfilePic = newProfilePicWrapper.image
        let completeUser = try await AuthAPI.createUser(username: username,
                                            first_name: firstName,
                                            last_name: lastName,
                                            picture: compressedProfilePic,
                                            email: email,
                                            password: password)
        // Local update
        frontendCompleteUser = FrontendCompleteUser(completeUser: completeUser,
                                                    profilePic: newProfilePicWrapper,
                                                    token: token)
        saveUserToFilesystem()
    }
    
    func logIn(json: Data) async throws {
        let token = try await AuthAPI.fetchAuthToken(json: json)
        setGlobalAuthToken(token: token)
        let completeUser = try await UserAPI.fetchAuthedUserByToken(token: token)
        let profilePicUIImage = try await UserAPI.UIImageFromURLString(url: completeUser.picture)
        let votes = try await VoteAPI.fetchVotesByUser(voter: completeUser.id)
        let favorites = try await FavoriteAPI.fetchFavoritesByUser(userId: completeUser.id)
        frontendCompleteUser = FrontendCompleteUser(completeUser: completeUser,
                                                    profilePic: ProfilePicWrapper(image: profilePicUIImage,
                                                                                  withCompresssion: false),
                                                    token: token,
                                                    votes: votes,
                                                    favorites: favorites)
        // Local update
        saveUserToFilesystem()
    }
    
    func logOut() {
        eraseUserFromFilesystem()
        frontendCompleteUser = nil
        setGlobalAuthToken(token: "")
    }
    
    func deleteMyAccount() async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        try await UserAPI.deleteUser(id: frontendCompleteUser.id)
        logOut()
    }
    
    //MARK: - Getters
    
    func getUser() -> FrontendCompleteUser? { return frontendCompleteUser }
    func getUserAsReadOnlyUser() -> ReadOnlyUser {
        return ReadOnlyUser(id: frontendCompleteUser!.id,
                            username: frontendCompleteUser!.username,
                            first_name: frontendCompleteUser!.first_name,
                            last_name: frontendCompleteUser!.last_name,
                            picture: frontendCompleteUser!.picture)
    }
    func getId() -> Int { return frontendCompleteUser!.id }
    func getUsername() -> String { return frontendCompleteUser!.username }
    func getFirstName() -> String { return frontendCompleteUser!.first_name }
    func getLastName() -> String { return frontendCompleteUser!.last_name }
    func getFirstLastName() -> String { return frontendCompleteUser!.first_name + " " + frontendCompleteUser!.last_name }
    func getEmail() -> String { return frontendCompleteUser!.email }
    func getProfilePic() -> UIImage { return frontendCompleteUser!.profilePicWrapper.image }
    func getVotes() -> [Vote] { return frontendCompleteUser!.votes }
    func getFavorites() -> [Favorite] { return frontendCompleteUser!.favorites }
    func getVotesForPost(postId: Int) -> [Vote] {
        return frontendCompleteUser!.votes.filter { vote in vote.post == postId }
    }
    func getIsFavoritedForPost(postId: Int) -> Bool {
        return frontendCompleteUser!.favorites.contains(where: { favorite in favorite.post == postId })
    }
    
    //MARK: - Update account
    
    // No need to return new profilePic bc it is updated globally
    func updateUsername(to newUsername: String) async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        
        let updatedCompleteUser = try await UserAPI.patchUsername(username: newUsername, id: frontendCompleteUser.id)
        self.frontendCompleteUser!.username = updatedCompleteUser.username
        saveUserToFilesystem()
    }
    
    // No need to return new profilePic bc it is updated globally
    func updateProfilePic(to newProfilePic: UIImage) async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        
        let newProfilePicWrapper = ProfilePicWrapper(image: newProfilePic, withCompresssion: true)
        let compressedNewProfilePic = newProfilePicWrapper.image
        let updatedCompleteUser = try await UserAPI.patchProfilePic(image: compressedNewProfilePic,
                                                                    id: frontendCompleteUser.id,
                                                                    username: frontendCompleteUser.username)
        self.frontendCompleteUser!.profilePicWrapper = newProfilePicWrapper
        self.frontendCompleteUser!.picture = updatedCompleteUser.picture
        saveUserToFilesystem()
    }
    
    func updatePassword(to newPassword: String) async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        
        let _ = try await UserAPI.patchPassword(password: newPassword, id: frontendCompleteUser.id)
        //no need for a local update, since we don't actually save the password locally
    }
    
    //MARK: - Create content
    
    func uploadPost(title: String,
                    text: String,
                    locationDescription: String?,
                    latitude: Double?,
                    longitude: Double?,
                    timestamp: Double) async throws -> Post {
        // DB update
        let newPost = try await PostAPI.createPost(title: title,
                                                   text: text,
                                                   locationDescription: locationDescription,
                                                   latitude: latitude,
                                                   longitude: longitude,
                                                   timestamp: timestamp,
                                                   author: UserService.singleton.getId())
        saveUserToFilesystem()
        return newPost
    }
    
    func deletePost(postId: Int) async throws {
        try await PostAPI.deletePost(id: postId)
    }
    
    func uploadComment(text: String, postId: Int, author: Int) async throws -> Comment {
        let newComment = try await CommentAPI.postComment(body: text, post: postId, author: author)
        return newComment
        //No need for local update, since comments aren't stored within the user
    }
    
    func deleteComment(commentId: Int, postId: Int) async throws {
        try await CommentAPI.deleteComment(commentId: commentId)
    }
    
    func uploadVote(postId: Int) async throws {
        //Local updates occur immediately so that post rendering based on user's favorites works properly
        let placeholderVote = Vote(id: -1,
                                   voter: frontendCompleteUser!.id,
                                   post: postId,
                                   timestamp: Date().timeIntervalSince1970)
        frontendCompleteUser!.votes.append(placeholderVote)
        do {
            let syncedVote = try await VoteAPI.postVote(voter: frontendCompleteUser!.id, post: postId)
            frontendCompleteUser!.votes.removeAll { vote in vote.id == placeholderVote.id }
            frontendCompleteUser!.votes.append(syncedVote)
        } catch {
            frontendCompleteUser!.votes.removeAll { vote in vote.id == placeholderVote.id }
            throw error
        }
        saveUserToFilesystem()
    }
    
    func deleteVote(postId: Int) async throws {
        //Local updates occur immediately so that post rendering based on user's favorites works properly
        let voteToDelete = frontendCompleteUser!.votes.first { vote in vote.post == postId }!
        frontendCompleteUser!.votes.removeAll { vote in vote.id == voteToDelete.id }
        do {
            try await VoteAPI.deleteVote(id: voteToDelete.id)
        } catch {
            frontendCompleteUser!.votes.append(voteToDelete) //delete failed, so add the vote back
            throw error
        }
        saveUserToFilesystem()
    }
    
    func uploadFavorite(postId: Int) async throws {
        //Local updates occur immediately so that post rendering based on user's favorites works properly
        let placeholderFavorite = Favorite(id: -1,
                                           timestamp: Date().timeIntervalSince1970,
                                           post: postId,
                                           favoriting_user: frontendCompleteUser!.id)
        frontendCompleteUser!.favorites.append(placeholderFavorite)
        do {
            let syncedFavorite = try await FavoriteAPI.postFavorite(userId: frontendCompleteUser!.id, postId: postId)
            frontendCompleteUser!.favorites.removeAll { favorite in favorite.id == placeholderFavorite.id }
            frontendCompleteUser!.favorites.append(syncedFavorite)
        } catch {
            frontendCompleteUser!.favorites.removeAll { favorite in favorite.id == placeholderFavorite.id }
            throw error
        }
        saveUserToFilesystem()
    }
    
    func deleteFavorite(postId: Int) async throws {
        //Local updates occur immediately so that post rendering based on user's favorites works properly
        let favoriteToDelete = frontendCompleteUser!.favorites.first { favorite in favorite.post == postId }!
        frontendCompleteUser!.favorites.removeAll { favorite in favorite.id == favoriteToDelete.id }
        do {
            try await FavoriteAPI.deleteFavorite(id: favoriteToDelete.id)
        } catch {
            frontendCompleteUser!.favorites.append(favoriteToDelete) //delete failed, so add the favorite back
            throw error
        }
        saveUserToFilesystem()
    }
    
    //MARK: - Filesystem
    
    func saveUserToFilesystem() {
        do {
            print("SAVING USER DATA")
            guard var frontendCompleteUser = frontendCompleteUser else { return }
            frontendCompleteUser.token = getGlobalAuthToken() //this shouldn't be necessary, but to be safe
            let encoder = JSONEncoder()
            let data: Data = try encoder.encode(frontendCompleteUser)
            let jsonString = String(data: data, encoding: .utf8)!
            try jsonString.write(to: self.localFileLocation, atomically: true, encoding: .utf8)
        } catch {
            print("COULD NOT SAVE: \(error)")
        }
    }
    
    func loadUserFromFilesystem() {
        do {
            print("LOADING USER DATA")
            let data = try Data(contentsOf: self.localFileLocation)
            frontendCompleteUser = try JSONDecoder().decode(FrontendCompleteUser.self, from: data)
            guard let frontendCompleteUser = frontendCompleteUser else { return }
            setGlobalAuthToken(token: frontendCompleteUser.token) //this shouldn't be necessary, but to be safe
        } catch {
            print("COULD NOT LOAD: \(error)")
        }
    }
    
    func eraseUserFromFilesystem() {
        do {
            print("ERASING USER DATA")
            setGlobalAuthToken(token: "")
            try FileManager.default.removeItem(at: self.localFileLocation)
        } catch {
            print("\(error)")
        }
    }
    
}

