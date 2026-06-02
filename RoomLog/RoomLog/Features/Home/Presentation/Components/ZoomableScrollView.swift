//
//  ZoomableScrollView.swift
//  RoomLog
//
//  Created by 김도연 on 5/5/26.
//

import SwiftUI
import UIKit

// MARK: - Long Press Drag Phase

enum LongPressDragPhase {
    case began
    case changed
    case ended
}

/// ZoomableScrollView 내부의 UIScrollView를 외부에서 제어하기 위한 프록시
@Observable
final class ScrollProxy {
    fileprivate(set) weak var scrollView: UIScrollView?
    /// 마지막 스크롤 위치 (뷰 재생성 시 복원용)
    fileprivate(set) var lastOffset: CGPoint?

    /// 현재 화면에 보이는 캔버스 영역 (content 좌표계)
    var visibleRect: CGRect {
        guard let sv = scrollView else { return .zero }
        let zoom = sv.zoomScale
        return CGRect(
            x: sv.contentOffset.x / zoom,
            y: sv.contentOffset.y / zoom,
            width: sv.bounds.width / zoom,
            height: sv.bounds.height / zoom
        )
    }

    /// 캔버스 좌표의 특정 점이 화면 중앙에 오도록 스크롤
    func scrollTo(canvasPoint: CGPoint) {
        guard let sv = scrollView else { return }
        let zoom = sv.zoomScale
        let viewportW = sv.bounds.width
        let viewportH = sv.bounds.height
        let maxX = sv.contentSize.width - viewportW
        let maxY = sv.contentSize.height - viewportH
        let targetX = canvasPoint.x * zoom - viewportW / 2
        let targetY = canvasPoint.y * zoom - viewportH / 2
        sv.contentOffset = CGPoint(
            x: min(max(targetX, 0), maxX),
            y: min(max(targetY, 0), maxY)
        )
    }

    /// contentOffset을 delta만큼 이동 (캔버스 좌표 기준, zoom 반영)
    /// 실제 이동된 캔버스 좌표 delta를 반환 (클램프 반영)
    @discardableResult
    func adjustOffset(by delta: CGVector) -> CGVector {
        guard let sv = scrollView else { return .zero }
        let zoom = sv.zoomScale
        guard zoom > 0 else { return .zero }
        let oldOffset = sv.contentOffset
        let maxX = sv.contentSize.width - sv.bounds.width
        let maxY = sv.contentSize.height - sv.bounds.height
        let newX = min(max(oldOffset.x + delta.dx * zoom, 0), maxX)
        let newY = min(max(oldOffset.y + delta.dy * zoom, 0), maxY)
        sv.contentOffset = CGPoint(x: newX, y: newY)
        return CGVector(
            dx: (newX - oldOffset.x) / zoom,
            dy: (newY - oldOffset.y) / zoom
        )
    }
}

struct ZoomableScrollView<Content: View>: UIViewControllerRepresentable {

    let contentSize: CGSize
    let minZoom: CGFloat
    let maxZoom: CGFloat
    @Binding var isScrollEnabled: Bool
    var scrollProxy: ScrollProxy?
    var onLongPressDrag: ((_ canvasPoint: CGPoint, _ phase: LongPressDragPhase) -> Void)?
    @ViewBuilder let content: () -> Content

    func makeCoordinator() -> Coordinator {
        Coordinator(scrollProxy: scrollProxy)
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
        scrollView.scrollsToTop = false

        let hostingController = UIHostingController(rootView: content())
        hostingController.view.backgroundColor = .clear
        hostingController.view.frame = CGRect(origin: .zero, size: contentSize)

        vc.addChild(hostingController)
        scrollView.addSubview(hostingController.view)
        hostingController.didMove(toParent: vc)
        context.coordinator.hostingController = hostingController

        scrollProxy?.scrollView = scrollView

        // Long press gesture for house dragging
        if onLongPressDrag != nil {
            let longPress = UILongPressGestureRecognizer(
                target: context.coordinator,
                action: #selector(Coordinator.handleLongPress(_:))
            )
            longPress.minimumPressDuration = 0.3
            longPress.delegate = context.coordinator
            scrollView.addGestureRecognizer(longPress)
        }
        context.coordinator.onLongPressDrag = onLongPressDrag

        // 이전 스크롤 위치가 있으면 복원
        if let saved = scrollProxy?.lastOffset {
            Task {
                scrollView.contentOffset = saved
            }
        }

        return vc
    }

    func updateUIViewController(_ vc: ZoomableScrollViewController, context: Context) {
        context.coordinator.hostingController?.rootView = content()
        vc.scrollView.isScrollEnabled = isScrollEnabled
        vc.scrollView.pinchGestureRecognizer?.isEnabled = isScrollEnabled
        context.coordinator.onLongPressDrag = onLongPressDrag
    }

    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var hostingController: UIHostingController<Content>?
        private weak var scrollProxy: ScrollProxy?
        var onLongPressDrag: ((_ canvasPoint: CGPoint, _ phase: LongPressDragPhase) -> Void)?

        init(scrollProxy: ScrollProxy?) {
            self.scrollProxy = scrollProxy
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController?.view
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollProxy?.lastOffset = scrollView.contentOffset
        }

        // MARK: - Long Press Handling

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard let contentView = hostingController?.view else { return }
            let touchPoint = gesture.location(in: contentView)

            switch gesture.state {
            case .began:
                scrollProxy?.scrollView?.isScrollEnabled = false
                scrollProxy?.scrollView?.pinchGestureRecognizer?.isEnabled = false
                onLongPressDrag?(touchPoint, .began)
            case .changed:
                onLongPressDrag?(touchPoint, .changed)
            case .ended, .cancelled, .failed:
                onLongPressDrag?(touchPoint, .ended)
                scrollProxy?.scrollView?.isScrollEnabled = true
                scrollProxy?.scrollView?.pinchGestureRecognizer?.isEnabled = true
            default:
                break
            }
        }

        // MARK: - UIGestureRecognizerDelegate

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

/// `setContentOffset(_:animated:)` 형태의 외부 트리거(탭바 재탭 등)에 의한 자동 스크롤을 무시한다.
/// 내부 코드에서는 `contentOffset = ...` 형태(animated: false)로만 설정하므로 정상 동작에 영향이 없다.
final class NonAnimatedSetOffsetScrollView: UIScrollView {
    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        if animated { return }
        super.setContentOffset(contentOffset, animated: animated)
    }
}

final class ZoomableScrollViewController: UIViewController {
    let scrollView = NonAnimatedSetOffsetScrollView()

    override func loadView() {
        view = scrollView
    }
}
