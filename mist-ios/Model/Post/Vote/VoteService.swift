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
    
    private var votes: [PostVote] = []

    //MARK: - Initialization
    
    private override init(){
        super.init()
    }
    
    //MARK: - Load
    
    func loadVotes() async throws {
        votes = try await PostVoteAPI.fetchVotesByUser(voter: UserService.singleton.getId())
    }
    
    //MARK: - Getters
    
    func votesForPost(postId: Int) -> [PostVote] {
        return votes.filter { $0.post == postId }
    }
    
    //MARK: - Updaters
    
    // Intermediate layer
    func handleVoteUpdate(postId: Int, emoji: String, _ action: VoteAction) throws {
        switch action {
        case .cast:
            try castVote(postId: postId, emoji: emoji)
        case .patch:
            try patchVote(postId: postId, emoji: emoji)
        case .delete:
            try deleteVote(postId: postId)
        }
    }
    
    private func castVote(postId: Int, emoji: String) throws {
        let addedVote = PostVote(id: Int.random(in: 0..<Int.max),
                                 voter: UserService.singleton.getId(),
                                 post: postId,
                                 timestamp: Date().timeIntervalSince1970,
                                 emoji: emoji,
                                 rating: nil)
        votes.append(addedVote)
        
        Task {
            do {
                let _ = try await PostVoteAPI.postVote(voter: UserService.singleton.getId(), post: postId, emoji: emoji)
            } catch {
                votes.removeAll { $0.id == addedVote.id }
                throw(error)
            }
        }
    }
    
    private func patchVote(postId: Int, emoji: String) throws {
        let originalVote = votes.first { $0.post == postId }!
        votes.removeAll { $0.id == originalVote.id }
        let patchedVote = PostVote(id: Int.random(in: 0..<Int.max),
                                 voter: UserService.singleton.getId(),
                                 post: postId,
                                 timestamp: Date().timeIntervalSince1970,
                                 emoji: emoji,
                                 rating: nil)
        votes.append(patchedVote)
        
        Task {
            do {
                let _ = try await PostVoteAPI.patchVote(voter: UserService.singleton.getId(), post: postId, emoji: emoji)
            } catch {
                print(error.localizedDescription)
                votes.removeAll { $0.id == patchedVote.id }
                votes.append(originalVote)
                throw(error)
            }
        }
    }
    
    private func deleteVote(postId: Int) throws {
        let deletedVote = votes.first { $0.post == postId }!
        votes.removeAll { $0.id == deletedVote.id }
        
        Task {
            do {
                try await PostVoteAPI.deleteVote(voter: UserService.singleton.getId(), post: postId)
            } catch {
                votes.append(deletedVote)
                throw(error)
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
    
}
