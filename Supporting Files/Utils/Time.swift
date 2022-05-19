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

//TODO: fix this function
//TODO check for more cases if time was even longer
func getFormattedTimeString(postTimestamp: Double) -> String {
    let elapsedTimeSincePost = NSDate().timeIntervalSince1970.getElapsedTime(since: postTimestamp)
    
    //if the post happened very recently
    if elapsedTimeSincePost.days == 0 && elapsedTimeSincePost.hours == 0 && elapsedTimeSincePost.minutes == 0 {
        return "Seconds ago"
    } else if elapsedTimeSincePost.hours == 0 {
        if (elapsedTimeSincePost.minutes == 1) {
            return String(elapsedTimeSincePost.minutes) + " minute ago"
        } else {
            return String(elapsedTimeSincePost.minutes) + " minutes ago"
        }
    }
    //if the post happened today
    else if getDayOfWeek(currentTimeMillis: postTimestamp) == getDayOfWeek(currentTimeMillis: currentTimeMillis()) {
        if (elapsedTimeSincePost.hours == 0) {
            return String(elapsedTimeSincePost.hours) + " hour ago"
        } else {
            return String(elapsedTimeSincePost.hours) + " hours ago"
        }
    }
    //if the post happened within the last week
    else if elapsedTimeSincePost.days < 7 {
        return getRecentFormattedDate(currentTimeMillis: postTimestamp)
    }
    //if the post happened longer than a week ago
    else {
        return getFormattedDate(currentTimeMillis: postTimestamp)
    }
}

//types of dates:
//45 seconds ago
//10 minutes ago
//2 hours ago
//Yesterday, 4:59pm
//Last Sun, 4:59pm
//Last Fri, 4:59pm
//Apr 4 at 4:59pm

//date formatting reference: https://stackoverflow.com/questions/35700281/date-format-in-swift
func getFormattedDate(currentTimeMillis: Double) -> String {
    let myTimeInterval = TimeInterval(currentTimeMillis)
    let thedate = Date(timeIntervalSince1970: myTimeInterval)
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US")
    dateFormatter.dateFormat = "MMM d"
    
    let timeFormatter = DateFormatter()
    timeFormatter.locale = Locale(identifier: "en_US")
    timeFormatter.dateFormat = "h:mma"
    
    return dateFormatter.string(from: thedate) + ", " + timeFormatter.string(from: thedate).replacingOccurrences(of: "AM", with: "am").replacingOccurrences(of: "PM", with: "pm")
}

func getRecentFormattedDate(currentTimeMillis: Double) -> String {
    let myTimeInterval = TimeInterval(currentTimeMillis)
    let thedate = Date(timeIntervalSince1970: myTimeInterval)
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US")
    dateFormatter.dateFormat = "E, h:mma"
    
    return "Last " + dateFormatter.string(from: thedate).replacingOccurrences(of: "AM", with: "am").replacingOccurrences(of: "PM", with: "pm")
}

func getDayOfWeek(currentTimeMillis: Double) -> String {
    let myTimeInterval = TimeInterval(currentTimeMillis)
    let thedate = Date(timeIntervalSince1970: myTimeInterval)
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US")
    dateFormatter.dateFormat = "EEEE"
    
    return dateFormatter.string(from: thedate)
}

//MARK: - UISlider

func getDateFromSlider(indexFromOneToSeven index: Float) -> String {
    if index >= 6 {
        return "Today"
    }
    if index >= 5 {
        return "Yesterday"
    }
    let millisecondsAgo = Double(floor(7 - index) * 86400000.0)
    let dateString = getDayOfWeek(currentTimeMillis: currentTimeMillis() + millisecondsAgo)
    
    // In case you want to display the time of day of the post
//    let timeofday = index.truncatingRemainder(dividingBy: 1)
//    if timeofday < 0.33 {
//        dateString += " morning"
//    } else if timeofday < 0.67 {
//        dateString += " afternoon"
//    } else {
//        dateString += " evening"
//    }
    return dateString
}

func getDateFromSlider(indexFromZeroToOne index: Float) -> String {
    if index >= 1 - 1.0/7 {
        return "Today"
    }
    else if index >= 1 - 2.0/7 {
        return "Yesterday"
    }
    else {
        let millisecondsInADay = 86400000.0
        let millisecondsAgo = floor(6.999 - (7.0 * Double(index))) * millisecondsInADay
        let dateString = getDayOfWeek(currentTimeMillis: currentTimeMillis() + millisecondsAgo)
        return dateString
    }
}
