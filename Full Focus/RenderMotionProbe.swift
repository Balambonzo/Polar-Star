//import SwiftUI
//import UIKit
//
///// Sonda temporanea: controlla le differenze tra il layer di layout e il
///// presentation layer di Core Animation, senza scrivere alcuno stato SwiftUI.
///// Serve a individuare traslazioni applicate al di fuori del layout dichiarato.
//struct RenderMotionProbe: UIViewRepresentable {
//    let name: String
//
//    func makeUIView(context: Context) -> RenderMotionProbeView {
//        RenderMotionProbeView(name: name)
//    }
//
//    func updateUIView(_ uiView: RenderMotionProbeView, context: Context) {
//        uiView.name = name
//    }
//
//    static func dismantleUIView(_ uiView: RenderMotionProbeView, coordinator: ()) {
//        uiView.stop()
//    }
//}
//
//final class RenderMotionProbeView: UIView {
//    var name: String
//
//    private var displayLink: CADisplayLink?
//    private var lastSignature: String?
//    private var lastLogTime: CFTimeInterval = 0
//    private weak var nearestScrollView: UIScrollView?
//    private var lastScrollOffset: CGFloat?
//    private var lastScrollLogTime: CFTimeInterval = 0
//
//    init(name: String) {
//        self.name = name
//        super.init(frame: .zero)
//        isUserInteractionEnabled = false
//        backgroundColor = .clear
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func didMoveToWindow() {
//        super.didMoveToWindow()
//        window == nil ? stop() : start()
//    }
//
//    func stop() {
//        displayLink?.invalidate()
//        displayLink = nil
//    }
//
//    private func start() {
//        guard displayLink == nil else { return }
//
//        let link = CADisplayLink(target: self, selector: #selector(samplePresentationLayers))
//        link.add(to: .main, forMode: .common)
//        displayLink = link
//    }
//
//    @objc private func samplePresentationLayers() {
//        sampleScrollView()
//
//        var currentLayer: CALayer? = layer
//        var depth = 0
//
//        while let modelLayer = currentLayer, depth < 16 {
//            guard let presentationLayer = modelLayer.presentation() else {
//                currentLayer = modelLayer.superlayer
//                depth += 1
//                continue
//            }
//
//            let positionDelta = presentationLayer.position.y - modelLayer.position.y
//            let boundsDelta = presentationLayer.bounds.origin.y - modelLayer.bounds.origin.y
//            let transformDelta = presentationLayer.transform.m42 - modelLayer.transform.m42
//
//            if max(abs(positionDelta), abs(boundsDelta), abs(transformDelta)) > 0.2 {
//                let signature = String(
//                    format: "%d|%.1f|%.1f|%.1f",
//                    depth,
//                    positionDelta,
//                    boundsDelta,
//                    transformDelta
//                )
//                let now = CACurrentMediaTime()
//
//                if signature != lastSignature, now - lastLogTime > 0.25 {
//                    print(
//                        "RENDER MOTION [\(name)] depth=\(depth) " +
//                        "layer=\(String(describing: type(of: modelLayer))) " +
//                        "positionY=\(positionDelta) boundsY=\(boundsDelta) " +
//                        "transformY=\(transformDelta)"
//                    )
//                    lastSignature = signature
//                    lastLogTime = now
//                }
//            }
//
//            currentLayer = modelLayer.superlayer
//            depth += 1
//        }
//    }
//
//    private func sampleScrollView() {
//        let scrollView = nearestScrollView ?? findNearestScrollView()
//        guard let scrollView else { return }
//
//        if nearestScrollView == nil {
//            nearestScrollView = scrollView
//            print(
//                "SCROLL PROBE [\(name)] attached " +
//                "bounces=\(scrollView.bounces) alwaysBounceVertical=\(scrollView.alwaysBounceVertical) " +
//                "contentHeight=\(scrollView.contentSize.height) boundsHeight=\(scrollView.bounds.height)"
//            )
//        }
//
//        let offset = scrollView.contentOffset.y
//        let now = CACurrentMediaTime()
//
//        defer { lastScrollOffset = offset }
//
//        guard let previousOffset = lastScrollOffset,
//              abs(offset - previousOffset) > 0.05,
//              now - lastScrollLogTime > 0.4 else {
//            return
//        }
//
//        print(
//            "SCROLL MOTION [\(name)] offsetY=\(offset) " +
//            "delta=\(offset - previousOffset) dragging=\(scrollView.isDragging) " +
//            "decelerating=\(scrollView.isDecelerating) tracking=\(scrollView.isTracking) " +
//            "pan=\(scrollView.panGestureRecognizer.state.rawValue) " +
//            "contentHeight=\(scrollView.contentSize.height) boundsHeight=\(scrollView.bounds.height) " +
//            "adjustedInsets=\(scrollView.adjustedContentInset)"
//        )
//        lastScrollLogTime = now
//    }
//
//    private func findNearestScrollView() -> UIScrollView? {
//        var currentView = superview
//
//        while let view = currentView {
//            if let scrollView = view as? UIScrollView {
//                return scrollView
//            }
//            currentView = view.superview
//        }
//
//        return nil
//    }
//}
