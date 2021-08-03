//
//  HandlePN.swift
//  NotificationService
//
//  Created by Nguyen Tien Hoang on 02/08/2021.
//  Copyright © 2021 Ray Wenderlich. All rights reserved.
//

import UserNotifications

class HandlePN: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"

            // Save notification data to UserDefaults
            let data = bestAttemptContent.userInfo as NSDictionary
            print(data)
            let pref = UserDefaults.init(suiteName: "group.com.hoang.pushdemo")
            pref?.set(data, forKey: "PN_DATA")
            pref?.synchronize()
            guard let attachmentURL = bestAttemptContent.userInfo["attachment-url"] as? String else {
                contentHandler(bestAttemptContent)
                return
            }
            
            do {
                let imageData = try Data(contentsOf: URL(string: attachmentURL)!)
                guard let attachment = UNNotificationAttachment.download(imageFileIdentifier: "image.jpg", data: imageData, options: nil) else {
                    contentHandler(bestAttemptContent)
                    return
                }
                bestAttemptContent.attachments = [attachment]
                contentHandler(bestAttemptContent.copy() as! UNNotificationContent)
            } catch {
                contentHandler(bestAttemptContent)
                print("Unable to load data: \(error)")
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}

extension UNNotificationAttachment {
    static func download(imageFileIdentifier: String, data: Data, options: [NSObject : AnyObject]?)
        -> UNNotificationAttachment? {
            let fileManager = FileManager.default
            if let directory = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.hoang.pushdemo") {
                do {
                    let newDirectory = directory.appendingPathComponent("Images")
                    if !fileManager.fileExists(atPath: newDirectory.path) {
                        try? fileManager.createDirectory(at: newDirectory, withIntermediateDirectories: true, attributes: nil)
                    }
                    let fileURL = newDirectory.appendingPathComponent(imageFileIdentifier)
                    do {
                        try data.write(to: fileURL, options: [])
                    } catch {
                        print("Unable to load data: \(error)")
                    }
                    let pref = UserDefaults(suiteName: "group.com.hoang.pushdemo")
                    pref?.set(data, forKey: "PN_IMAGE")
                    pref?.synchronize()
                    let imageAttachment = try UNNotificationAttachment.init(identifier: imageFileIdentifier, url: fileURL, options: options)
                    return imageAttachment
                } catch let error {
                    print("Error: \(error)")
                }
            }
            return nil
    }
}
