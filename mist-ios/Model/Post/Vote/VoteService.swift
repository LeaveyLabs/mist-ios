//
//  VoteService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

enum VoteAction {
    case cast, patch, delete
}

class VoteService: NSObject {
    
    static var singleton = VoteService()
    
    private var postVotes: [PostVote] = []
    private var commentVotes: [CommentVote] = []

    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    //MARK: - Load
    
    func loadVotes() async throws {
        async let loadedPostVotes = PostVoteAPI.fetchVotesByUser(voter: UserService.singleton.getId())
        async let loadedCommentVotes = CommentVoteAPI.fetchVotesByUser(voter: UserService.singleton.getId())
        (postVotes, commentVotes) = try await (loadedPostVotes, loadedCommentVotes)
        commentVotes.forEach { vote in
            if (vote.comment == 249) {
                print("loaded vote exists")
            }
        }
    }
    
    //MARK: - Getters
    
    func votesForPost(postId: Int) -> [PostVote] {
        return postVotes.filter { $0.post == postId }
    }
    
    func voteForComment(commentId: Int) -> CommentVote? {
        return commentVotes.filter { $0.comment == commentId }.first
    }
    
    //MARK: - Post Vote Updaters
    
    // Intermediate layer
    func handlePostVoteUpdate(postId: Int, emoji: String, _ action: VoteAction) throws {
        switch action {
        case .cast:
            try castPostVote(postId: postId, emoji: emoji)
        case .patch:
            try patchPostVote(postId: postId, emoji: emoji)
        case .delete:
            try deletePostVote(postId: postId)
        }
    }
    
    private func castPostVote(postId: Int, emoji: String) throws {
        let addedVote = PostVote(id: Int.random(in: 0..<Int.max),
                                 voter: UserService.singleton.getId(),
                                 post: postId,
                                 timestamp: Date().timeIntervalSince1970,
                                 emoji: emoji,
                                 rating: nil)
        postVotes.append(addedVote)
        
        Task {
            do {
                let _ = try await PostVoteAPI.postVote(voter: UserService.singleton.getId(), post: postId, emoji: emoji)
            } catch {
                postVotes.removeAll { $0.id == addedVote.id }
                throw(error)
            }
        }
    }
    
    private func patchPostVote(postId: Int, emoji: String) throws {
        let originalVote = postVotes.first { $0.post == postId }!
        postVotes.removeAll { $0.id == originalVote.id }
        let patchedVote = PostVote(id: Int.random(in: 0..<Int.max),
                                 voter: UserService.singleton.getId(),
                                 post: postId,
                                 timestamp: Date().timeIntervalSince1970,
                                 emoji: emoji,
                                 rating: nil)
        postVotes.append(patchedVote)
        
        Task {
            do {
                let _ = try await PostVoteAPI.patchVote(voter: UserService.singleton.getId(), post: postId, emoji: emoji)
            } catch {
                print(error.localizedDescription)
                postVotes.removeAll { $0.id == patchedVote.id }
                postVotes.append(originalVote)
                throw(error)
            }
        }
    }
    
    private func deletePostVote(postId: Int) throws {
        guard let deletedVote = postVotes.first(where: { $0.post == postId } ) else { return }
        postVotes.removeAll { $0.id == deletedVote.id }
        
        Task {
            do {
                try await PostVoteAPI.deleteVote(voter: UserService.singleton.getId(), post: postId)
            } catch {
                postVotes.append(deletedVote)
                throw(error)
            }
        }
    }
    
    //MARK: - Comment Vote Updaters
    
    // Intermediate layer
    func handleCommentVoteUpdate(commentId: Int, _ isAdding: Bool) throws {
        if isAdding {
            try castCommentVote(commentId: commentId)
        } else {
            try deleteCommentVote(commentId: commentId)
        }
    }
    
    private func castCommentVote(commentId: Int) throws {
        let addedVote = CommentVote(id: Int.random(in: 0..<Int.max), voter: UserService.singleton.getId(), comment: commentId, timestamp: Date().timeIntervalSince1970, rating: nil)
        print(commentVotes.filter { $0.comment == commentId })
        commentVotes.append(addedVote)
        print(commentVotes.filter { $0.comment == commentId })
        
        Task {
            do {
                let _ = try await CommentVoteAPI.postVote(voter: UserService.singleton.getId(), comment: commentId)
            } catch {
//                CustomSwiftMessages.displayError(error)
                commentVotes.removeAll { $0.id == addedVote.id }
                throw(error)
            }
        }
    }
    
    //you can't deleteVote by deletedVote.id like this because the deleted vote might have been a placeholderVote with a random, incorrect id
    //either: update the placeholderVote when the official vote loads in
    //or delete in a different way
    private func deleteCommentVote(commentId: Int) throws {
        guard let deletedVote = commentVotes.first(where: { $0.comment == commentId } ) else { return }
        print(commentVotes.filter { $0.comment == commentId })
        commentVotes.removeAll { $0.id == deletedVote.id }
        print(commentVotes.filter { $0.comment == commentId })

        Task {
            do {
                try await CommentVoteAPI.deleteVote(voter: UserService.singleton.getId(), comment: commentId)
            } catch {
                commentVotes.append(deletedVote)
//                CustomSwiftMessages.displayError(error)
                throw(error)
            }
        }
    }
    
}


//
//    private func handleVoteAdd(postId: Int, emoji: String) throws {
//        let addedVote = PostVote(id: Int.random(in: 0..<Int.max),
//                                 voter: UserService.singleton.getId(),
//                                 post: postId,
//                                 timestamp: Date().timeIntervalSince1970,
//                                 emoji: emoji,
//                                 rating: nil)
//        votes.append(addedVote)
//
//        Task {
//            do {
//                let _ = try await PostVoteAPI.postVote(voter: UserService.singleton.getId(), post: postId)
//            } catch {
//                votes.removeAll { $0.id == addedVote.id }
//                throw(error)
//            }
//        }
//    }
//
//    private func handleVoteDelete(postId: Int) throws {
//        let deletedVote = votes.first { $0.post == postId }!
//        votes.removeAll { $0.id == deletedVote.id }
//
//        Task {
//            do {
//                try await PostVoteAPI.deleteVote(voter: UserService.singleton.getId(), post: postId)
//            } catch {
//                votes.append(deletedVote)
//                throw(error)
//            }
//        }
//    }
