//
//  FaceCaptureCameraPositionItem.swift
//  Catalog
//
//  Created by Pavel Kondrashkov on 5/19/21.
//  Copyright © 2021 Regula. All rights reserved.
//

import FaceSDK

final class FaceCaptureCameraPositionItem: CatalogItem {
    override init() {
        super.init()

        title = "Face Capture camera position"
        itemDescription = "Changes default camera position to back."
        category = .feature
    }

    override func onItemSelected(from viewController: UIViewController) {
        let configuration = FaceCaptureConfiguration {
            $0.cameraPosition = .back
        }

        Face.service.presentCaptureViewController(
            from: viewController,
            animated: true,
            configuration: configuration,
            onCapture: { [weak self, weak viewController] response in
                guard let self = self, let viewController = viewController else { return }
                self.showFaceCaptureResult(response, from: viewController)
            },
            completion: nil)
    }
}
