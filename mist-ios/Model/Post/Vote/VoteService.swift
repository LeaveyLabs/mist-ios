//
//  VoteService.swift
//  mist-ios
//
//  Created by Adam Monterey on 6/25/22.
//

import Foundation

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
    func handleVoteUpdate(postId: Int, _ isAdding: Bool) throws {
        if isAdding {
            try handleVoteAdd(postId: postId)
        } else {
            try handleVoteDelete(postId: postId)
        }
    }
    
    private func handleVoteAdd(postId: Int) throws {
        let addedVote = PostVote(id: Int.random(in: 0..<Int.max),
                                      voter: UserService.singleton.getId(),
                                      post: postId,
                                      timestamp: Date().timeIntervalSince1970)
        votes.append(addedVote)
        
        Task {
            do {
                let _ = try await PostVoteAPI.postVote(voter: UserService.singleton.getId(), post: postId)
            } catch {
                votes.removeAll { $0.id == addedVote.id }
                throw(error)
            }
        }
    }
    
    private func handleVoteDelete(postId: Int) throws {
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
    
}
