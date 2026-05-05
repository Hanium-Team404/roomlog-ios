//
//  ZoomableScrollView.swift
//  RoomLog
//
//  Created by 김도연 on 5/5/26.
//

import SwiftUI
import UIKit

struct ZoomableScrollView<Content: View>: UIViewControllerRepresentable {

    let contentSize: CGSize
    let minZoom: CGFloat
    let maxZoom: CGFloat
    @ViewBuilder let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> ZoomableScrollViewController {
        let vc = ZoomableScrollViewController()
        let scrollView = vc.scrollView
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minZoom
        scrollView.maximumZoomScale = maxZoom
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        scrollView.contentSize = contentSize
        scrollView.decelerationRate = .fast

        let hostingController = UIHostingController(rootView: content())
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = CGRect(origin: .zero, size: contentSize)

        vc.addChild(hostingController)
        scrollView.addSubview(hostingController.view)
        hostingController.didMove(toParent: vc)
        context.coordinator.hostingController = hostingController

        // 초기 스크롤 위치를 캔버스 중앙으로
        DispatchQueue.main.async {
            let offsetX = (contentSize.width - scrollView.bounds.width) / 2
            let offsetY = ((contentSize.height - scrollView.bounds.height) / 2) - 100
            scrollView.contentOffset = CGPoint(x: max(offsetX, 0), y: max(offsetY, 0))
        }

        return vc
    }

    func updateUIViewController(_ vc: ZoomableScrollViewController, context: Context) {
        context.coordinator.hostingController?.rootView = content()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController?.view
        }
    }
}

final class ZoomableScrollViewController: UIViewController {
    let scrollView = UIScrollView()

    override func loadView() {
        view = scrollView
    }
}
