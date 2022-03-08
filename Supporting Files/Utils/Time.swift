//
//  Time.swift
//  mist-ios
//
//  Created by Adam Novak on 2022/03/06.
//

import Foundation

func currentTimeMillis() -> Double {
    return Date().timeIntervalSince1970
}

struct ElapsedTime {
    let seconds, minutes, hours, days, months, years: Int
}

extension TimeInterval{
    func getElapsedTime(since timestamp: TimeInterval) -> ElapsedTime {
        let time = NSInteger(self)
        let elapsedTime = time - NSInteger(timestamp)

        let seconds = elapsedTime % 60
        let minutes = (elapsedTime / 60) % 60
        let hours = (elapsedTime / 3600)
        let days = hours / 24
        let months = days / 30
        let years = months / 12

        return ElapsedTime(seconds: seconds, minutes: minutes, hours: hours, days: days, months: months, years: years)
    }
}

//TODO check for more cases if time was even longer
func getFormattedTimeString(postTimestamp: Double) -> String {
    let elapsedTimeSincePost = NSDate().timeIntervalSince1970.getElapsedTime(since: postTimestamp)
    var timeToPrint = ""
    if elapsedTimeSincePost.days == 0 && elapsedTimeSincePost.hours == 0 && elapsedTimeSincePost.minutes == 0 {
        timeToPrint = "Just seconds"
    } else if elapsedTimeSincePost.hours == 0 {
        if (elapsedTimeSincePost.minutes == 1) {
            timeToPrint = String(elapsedTimeSincePost.minutes) + " minute"
        } else {
            timeToPrint = String(elapsedTimeSincePost.minutes) + " minutes"
        }
    } else if elapsedTimeSincePost.days == 0 {
        timeToPrint = String(elapsedTimeSincePost.hours) + " hours"
    } else if elapsedTimeSincePost.days > 30 {
        return getFormattedDate(currentTimeMillis: postTimestamp)
    }
    return timeToPrint + " ago"
}


func getFormattedDate(currentTimeMillis: Double) -> String {
    let myTimeInterval = TimeInterval(currentTimeMillis)
    let thedate = Date(timeIntervalSince1970: myTimeInterval)
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd-MM-yyyy"
    return dateFormatter.string(from: thedate)
}
