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
    private var votes: [Vote] = []
    private var favorites: [Favorite] = []
    private var localFileLocation: URL!
    
    //private initializer because there will only ever be one instance of UserService, the singleton
    private override init(){
        super.init()
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        localFileLocation = documentsDirectory.appendingPathComponent("myaccount.json")
        if FileManager.default.fileExists(atPath: localFileLocation.path) {
            Task { await self.loadUserFromFilesystem() }
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
        Task { await self.saveUserToFilesystem() }
    }
    
    func logIn(json: Data) async throws {
        let token = try await AuthAPI.fetchAuthToken(json: json)
        setGlobalAuthToken(token: token)
        let completeUser = try await UserAPI.fetchAuthedUserByToken(token: token)
        let profilePicUIImage = try await UserAPI.UIImageFromURLString(url: completeUser.picture)
        votes = try await VoteAPI.fetchVotesByUser(voter: completeUser.id)
        favorites = try await FavoriteAPI.fetchFavoritesByUser(userId: completeUser.id)
        frontendCompleteUser = FrontendCompleteUser(completeUser: completeUser,
                                                    profilePic: ProfilePicWrapper(image: profilePicUIImage,
                                                                                  withCompresssion: false),
                                                    token: token)
        // Local update
        Task { await self.saveUserToFilesystem() }
    }
    
    func logOut() async {
        await self.eraseUserFromFilesystem()
        frontendCompleteUser = nil
        setGlobalAuthToken(token: "")
    }
    
    func deleteMyAccount() async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        try await UserAPI.deleteUser(user_id: frontendCompleteUser.id)
        await logOut()
    }
    
    //MARK: - Getters
    
    func getUser() -> FrontendCompleteUser { return frontendCompleteUser! }
    func getUserAsReadOnlyUser() -> ReadOnlyUser {
        return ReadOnlyUser(id: frontendCompleteUser!.id,
                            username: frontendCompleteUser!.username,
                            first_name: frontendCompleteUser!.first_name,
                            last_name: frontendCompleteUser!.last_name,
                            picture: frontendCompleteUser!.picture)
    }
    func getUserAsFrontendReadOnlyUser() -> FrontendReadOnlyUser {
        return FrontendReadOnlyUser(readOnlyUser: getUserAsReadOnlyUser(),
                                    profilePic: frontendCompleteUser!.profilePicWrapper.image)
    }
    func getId() -> Int { return frontendCompleteUser!.id }
    func getUsername() -> String { return frontendCompleteUser!.username }
    func getFirstName() -> String { return frontendCompleteUser!.first_name }
    func getLastName() -> String { return frontendCompleteUser!.last_name }
    func getFirstLastName() -> String { return frontendCompleteUser!.first_name + " " + frontendCompleteUser!.last_name }
    func getEmail() -> String { return frontendCompleteUser!.email }
    func getProfilePic() -> UIImage { return frontendCompleteUser!.profilePicWrapper.image }
    func getFavorites() -> [Favorite] { return favorites }
    func getVotesForPost(postId: Int) -> [Vote] {
        return votes.filter { $0.post == postId }
    }
    func getIsFavoritedForPost(postId: Int) -> Bool {
        return favorites.contains(where: { $0.post == postId })
    }
    
    //MARK: - Update account
    
    // No need to return new profilePic bc it is updated globally
    func updateUsername(to newUsername: String) async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        
        let updatedCompleteUser = try await UserAPI.patchUsername(username: newUsername, id: frontendCompleteUser.id)
        self.frontendCompleteUser!.username = updatedCompleteUser.username
        Task { await self.saveUserToFilesystem() }
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
        Task { await self.saveUserToFilesystem() }
    }
    
    func updatePassword(to newPassword: String) async throws {
        guard let frontendCompleteUser = frontendCompleteUser else { return }
        
        let _ = try await UserAPI.patchPassword(password: newPassword, id: frontendCompleteUser.id)
        //no need for a local update, since we don't actually save the password locally
    }
    
    func updateUserInteractionsAfterLoadingPosts(_ newVotes: [Vote], _ newFavorites: [Favorite]) {
        votes = newVotes
        favorites = newFavorites
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
        Task { await self.saveUserToFilesystem() }
        return newPost
    }
    
    func deletePost(postId: Int) async throws {
        try await PostAPI.deletePost(post_id: postId)
    }
    
    func uploadComment(text: String, postId: Int) async throws -> Comment {
        let newComment = try await CommentAPI.postComment(body: text, post: postId, author: frontendCompleteUser!.id)
        return newComment
        //No need for local update, since comments aren't stored locally
    }
    
    func deleteComment(commentId: Int, postId: Int) async throws {
        try await CommentAPI.deleteComment(comment_id: commentId)
    }
    
    func removeTemporaryLocalVote(_ vote: Vote) {
        votes.removeAll { $0.id == vote.id }
    }
    
//    func handleVoteUpdate(postId: Int, _ isAdding: Bool) throws {
//        var changedVote: Vote
//        if isAdding {
//            changedVote = Vote(id: Int.random(in: 0..<Int.max),
//                                          voter: UserService.singleton.getId(),
//                                          post: postId,
//                                          timestamp: Date().timeIntervalSince1970)
//            votes.append(changedVote)
//        } else {
//            changedVote = votes.first { $0.post == postId }!
//            votes.removeAll { $0.id == changedVote.id }
//        }
//
//        Task {
//            do {
//                if isAdding {
//                    let _ = try await VoteAPI.postVote(voter: UserService.singleton.getId(), post: postId)
//                } else {
//                    try await VoteAPI.deleteVote(voter: UserService.singleton.getId(), post: postId)
//                }
//            } catch {
//                handleFailedVoteUpdate(with: changedVote, isAdding)
//                throw(error)
//            }
//        }
//    }
//
//    func handleFailedVoteUpdate(with vote: Vote, _ wasFailedAdd: Bool) {
//        if wasFailedAdd {
//            votes.removeAll { $0.id == vote.id }
//        } else {
//            votes.append(vote)
//        }
//    }
    
    //EXPERIMENTAL
    func handleVoteUpdate(postId: Int, _ isAdding: Bool) throws {
        if isAdding {
            try handleVoteAdd(postId: postId)
        } else {
            try handleVoteDelete(postId: postId)
        }
    }

    
    func handleVoteDelete(postId: Int) throws {
        let deletedVote = votes.first { $0.post == postId }!
        votes.removeAll { $0.id == deletedVote.id }
        
        Task {
            do {
                try await VoteAPI.deleteVote(voter: UserService.singleton.getId(), post: postId)
            } catch {
                votes.append(deletedVote)
                throw(error)
            }
        }
    }
    
    
    func handleVoteAdd(postId: Int) throws {
        let addedVote = Vote(id: Int.random(in: 0..<Int.max),
                                      voter: UserService.singleton.getId(),
                                      post: postId,
                                      timestamp: Date().timeIntervalSince1970)
        votes.append(addedVote)
        
        Task {
            do {
                let _ = try await VoteAPI.postVote(voter: UserService.singleton.getId(), post: postId)
            } catch {
                votes.removeAll { $0.id == addedVote.id }
                throw(error)
            }
        }
    }
    
    func handleFavoriteUpdate(postId: Int, _ isAdding: Bool) -> Favorite {
        if isAdding {
            let newFavorite = Favorite(id: Int.random(in: 0..<Int.max),
                                                  timestamp: Date().timeIntervalSince1970,
                                                  post: postId,
                                                  favoriting_user: UserService.singleton.getId())
            favorites.append(newFavorite)
            return newFavorite
        } else {
            let favoriteToDelete = favorites.first { $0.post == postId }!
            favorites.removeAll { $0.id == favoriteToDelete.id }
            return favoriteToDelete
        }
    }
    
    func handleFailedFavoriteUpdate(with favorite: Favorite, _ wasFailedAdd: Bool) {
        if wasFailedAdd {
            favorites.removeAll { $0.id == favorite.id }
        } else {
            favorites.append(favorite)
        }
    }
    
    //MARK: - Filesystem
    
    func saveUserToFilesystem() async {
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
    
    func loadUserFromFilesystem() async {
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
    
    func eraseUserFromFilesystem() async {
        do {
            print("ERASING USER DATA")
            setGlobalAuthToken(token: "")
            try FileManager.default.removeItem(at: self.localFileLocation)
        } catch {
            print("\(error)")
        }
    }
    
}



//func uploadVote(postId: Int) async throws {
//        let placeholderVote = Vote(id: -1,
//                                   voter: frontendCompleteUser!.id,
//                                   post: postId,
//                                   timestamp: Date().timeIntervalSince1970)
//        frontendCompleteUser!.votes.append(placeholderVote)
//
//
//        do {
//            let _ = try await VoteAPI.postVote(voter: frontendCompleteUser!.id, post: postId)
//        } catch {
//            frontendCompleteUser!.votes.removeAll { vote in vote.id == placeholderVote.id }
//            throw error
//        }
//    }
//
//    func deleteVote(postId: Int) async throws {
//        let voteToDelete = frontendCompleteUser!.votes.first { vote in vote.post == postId }!
//        frontendCompleteUser!.votes.removeAll { vote in vote.id == voteToDelete.id }
//        do {
//            try await VoteAPI.deleteVote(id: voteToDelete.id)
//        } catch {
//            frontendCompleteUser!.votes.append(voteToDelete) //delete failed, so add the vote back
//            throw error
//        }
//    }
//
//    func uploadFavorite(postId: Int) async throws {
//        let placeholderFavorite = Favorite(id: -1,
//                                           timestamp: Date().timeIntervalSince1970,
//                                           post: postId,
//                                           favoriting_user: frontendCompleteUser!.id)
//        frontendCompleteUser!.favorites.append(placeholderFavorite)
//        do {
//            let _ = try await FavoriteAPI.postFavorite(userId: frontendCompleteUser!.id, postId: postId)
//        } catch {
//            frontendCompleteUser!.favorites.removeAll { favorite in favorite.id == placeholderFavorite.id }
//            throw error
//        }
//    }
//
//    func deleteFavorite(postId: Int) async throws {
//        let favoriteToDelete = frontendCompleteUser!.favorites.first { favorite in favorite.post == postId }!
//        frontendCompleteUser!.favorites.removeAll { favorite in favorite.id == favoriteToDelete.id }
//        do {
//            try await FavoriteAPI.deleteFavorite(id: favoriteToDelete.id)
//        } catch {
//            frontendCompleteUser!.favorites.append(favoriteToDelete) //delete failed, so add the favorite back
//            throw error
//        }
//    }
