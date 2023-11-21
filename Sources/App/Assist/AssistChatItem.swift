//
//  AssistChatModel.swift
//  App
//
//  Created by Bruno Pantaleão on 20/11/2023.
//  Copyright © 2023 Home Assistant. All rights reserved.
//

import Foundation

struct AssistChatItem {
    let id: String
    let content: String
    let itemType: ItemType

    enum ItemType {
        case input
        case output
    }
}
