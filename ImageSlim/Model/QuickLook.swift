//
//  QuickLook.swift
//  ImageSlim
//
//  Created by 方君宇 on 2025/7/8.
//

import QuickLook
import QuickLookUI

class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?

    init(url: URL) {
        self.previewItemURL = url
        self.previewItemTitle = url.lastPathComponent
    }
}

class PreviewDataSource: NSObject, QLPreviewPanelDataSource {
    var items: [PreviewItem]

    init(urls: [URL]) {
        self.items = urls.map { PreviewItem(url: $0) }
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        items.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        items[index]
    }
}
