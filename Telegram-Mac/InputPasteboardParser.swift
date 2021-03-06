//
//  InputPasteboardParser.swift
//  Telegram-Mac
//
//  Created by keepcoder on 02/11/2016.
//  Copyright © 2016 Telegram. All rights reserved.
//

import Cocoa
import TelegramCoreMac
import SwiftSignalKitMac
import PostboxMac
import TGUIKit
class InputPasteboardParser: NSObject {

    
    
    public class func proccess(pasteboard:NSPasteboard, account:Account, chatInteraction:ChatInteraction, window:Window) -> Bool {
        let items = pasteboard.pasteboardItems
        
        if let items = items, !items.isEmpty {
            var files:[URL] = []
            
            for item in items {
                let path = item.string(forType: NSPasteboard.PasteboardType(rawValue: "public.file-url"))
                if let path = path, let url = URL(string: path) {
                    files.append(url)
                }
                
            }
            
            var image:NSImage? = nil
            
            if files.isEmpty {
                if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], !images.isEmpty {
                    image = images[0]
                }
            }
            
            
            if let _ = items[0].types.index(of: NSPasteboard.PasteboardType(rawValue: "com.apple.traditional-mac-plain-text")) {
                return true
            }
            
            let previous = files.count
            
            files = files.filter { path -> Bool in
                if let size = fileSize(path.path) {
                    return size <= 1500000000
                }
                
                return false
            }
            
            let afterSizeCheck = files.count
            
            if afterSizeCheck == 0 && previous != afterSizeCheck {
                alert(for: mainWindow, header: appName, info: tr(.appMaxFileSize))
                return false
            }
            
            if let peer = chatInteraction.presentation.peer, peer.mediaRestricted {
                alertForMediaRestriction(peer)
                return false
            }
            
            if !files.isEmpty {
                showModal(with:PreviewSenderController(urls: files, account:account, chatInteraction:chatInteraction), for:window)
                
                return false
            } else if let image = image {
                _ = (putToTemp(image: image, compress: false) |> deliverOnMainQueue).start(next: { (path) in
                    showModal(with:PreviewSenderController(urls: [URL(fileURLWithPath: path)], account:account, chatInteraction:chatInteraction), for:window)
                })
                return false
            }
   
        }
        
        return true
    }
    
}

