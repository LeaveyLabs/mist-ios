//
//  FlagService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

class FlagService: NSObject {
    
    static var singleton = FlagService()
    
    private var postFlagsFromYou: [PostFlag] = []
    private var commentFlagsFromYou: [CommentFlag] = []

    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    //MARK: - Load
    
    func loadFlags() async throws {
        async let loadedPostFlags = PostFlagAPI.fetchFlagsByFlagger(flaggerId: UserService.singleton.getId())
        async let loadedCommentFlags = CommentFlagAPI.fetchFlagsByFlagger(flaggerId: UserService.singleton.getId())
        (postFlagsFromYou, commentFlagsFromYou) = try await (loadedPostFlags, loadedCommentFlags)
    }
    
    //MARK: - Getters
    
    func hasFlaggedPost(_ postId: Int) -> Bool {
        return postFlagsFromYou.contains { $0.post == postId }
    }
    
    func hasFlaggedComment(_ commentId: Int) -> Bool {
        return commentFlagsFromYou.contains { $0.comment == commentId }
    }
    
    //MARK: - Post Updates
    
    // Intermediate layer
    func handlePostFlagUpdate(postId: Int, _ isAdding: Bool) throws {
        if isAdding {
            try flagPost(postId)
        } else {
            try unFlagPost(postId)
        }
    }
    
    private func flagPost(_ postToBeFlagged: Int) throws {
        let newFlag = PostFlag(id: Int.random(in: 0..<Int.max), flagger: UserService.singleton.getId(), post: postToBeFlagged, timestamp: Date().timeIntervalSince1970, rating: 0)
        postFlagsFromYou.append(newFlag)
        Task {
            do {
                let _ = try await PostFlagAPI.postFlag(flaggerId: UserService.singleton.getId(), postId: postToBeFlagged)
            } catch {
                postFlagsFromYou.removeAll { $0.id == newFlag.id }
                throw(error)
            }
        }
    }
    
    private func unFlagPost(_ postToBeUnFlagged: Int) throws {
        guard let flagToDelete = postFlagsFromYou.first(where: { $0.post == postToBeUnFlagged }) else { return }
        postFlagsFromYou.removeAll { $0.id == flagToDelete.id }
        
        Task {
            do {
                let _ = try await PostFlagAPI.deleteFlag(flaggerId: UserService.singleton.getId(), postId: postToBeUnFlagged)
            } catch {
                postFlagsFromYou.append(flagToDelete)
                throw(error)
            }
        }
    }
    
    //MARK: - Comment Updates
    
    // Intermediate layer
    func handleCommentFlagUpdate(commentId: Int, _ isAdding: Bool) throws {
        if isAdding {
            try flagComment(commentId)
        } else {
            try unFlagComment(commentId)
        }
    }
    
    private func flagComment(_ commentToBeFlagged: Int) throws {
        let newFlag = CommentFlag(id: Int.random(in: 0..<Int.max), flagger: UserService.singleton.getId(), comment: commentToBeFlagged, timestamp: Date().timeIntervalSince1970, rating: 0)
        commentFlagsFromYou.append(newFlag)
        Task {
            do {
                let _ = try await CommentFlagAPI.postFlag(flaggerId: UserService.singleton.getId(), commentId: commentToBeFlagged)
            } catch {
                commentFlagsFromYou.removeAll { $0.id == newFlag.id }
                throw(error)
            }
        }
    }
    
    private func unFlagComment(_ commentToBeUnFlagged: Int) throws {
        guard let flagToDelete = commentFlagsFromYou.first(where: { $0.comment == commentToBeUnFlagged }) else { return }
        commentFlagsFromYou.removeAll { $0.id == flagToDelete.id }
        Task {
            do {
                let _ = try await CommentFlagAPI.deleteFlag(flaggerId: UserService.singleton.getId(), commentId: commentToBeUnFlagged)
            } catch {
                commentFlagsFromYou.append(flagToDelete)
                throw(error)
            }
        }
    }
    
}
