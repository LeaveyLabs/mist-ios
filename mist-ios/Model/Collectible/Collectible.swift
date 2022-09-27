//
//  Prompt.swift
//  mist-ios
//
//  Created by Adam Monterey on 9/24/22.
//

import Foundation

struct Collectible {
    
    static let COLLECTIBLES_COUNT = 30
    
    var type: Int
    
    var image: UIImage {
        return UIImage(named: "collectible-" + String(type))!
    }
    
    var title: String {
        switch type {
        case 1:
            return "someone who's always been there for you"
        case 2:
            return "someone who you look up to"
        case 3:
            return "something you gotta get off your chest"
        case 4:
            return "someone who's always got your back"
        case 5:
            return "someone who makes the world a better place"
        case 6:
            return "someone who came in clutch"
        case 7:
            return "someone who's got a bright future'"
        case 8:
            return "someone who made your day a little brighter"
        case 9:
            return "your bestie since day 1"
        case 10:
            return "someone you can't live without"
        case 11:
            return "someone from one of your classes"
        case 12:
            return "someone with a contagious laugh"
        case 13:
            return "a stranger who held the door for you"
        case 14:
            return "someone who's been grinding this week"
        case 15:
            return "a stranger whose fit was fire"
        case 16:
            return "someone who inspires you"
        case 17:
            return "the most brilliant person you know"
        case 18:
            return "someone's who's great with words"
        case 19:
            return "your friend crush"
        case 20:
            return "someone you passed on your way to class"
        case 21:
            return "someone you're tryna cuff this season"
        case 22:
            return "a stranger with a cute smile"
        case 23:
            return "the perfect date you'd take them on"
        case 24:
            return "your 3 favorite things about a certain someone"
        case 25:
            return "alright, what's the tea"
        case 26:
            return "someone with an upcoming birthday"
        case 27:
            return "your crush with a romantic love letter"
        case 28:
            return "put someone in the hot seat"
        case 29:
            return "someone who might be having a bad day"
        case 30:
            return "a stranger who made your day"
        default:
            return ""
        }
    }
}
