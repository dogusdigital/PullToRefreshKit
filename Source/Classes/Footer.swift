//
//  Footer.swift
//  PullToRefreshKit
//
//  Created by huangwenchen on 16/7/11.
//  I refer a lot logic for MJRefresh https://github.com/CoderMJLee/MJRefresh ,thanks to this lib and all contributors.
//  Copyright © 2016年 Leo. All rights reserved.

import Foundation
import UIKit

@objc public protocol RefreshableFooter: class {
    /**
     footer的高度
     */
    func heightForFooter() -> CGFloat
    /**
     不需要下拉加载更多的回调
     */
    func didUpdateToNoMoreData()
    /**
     重新设置到常态的回调
     */
    func didResetToDefault()
    /**
     结束刷新的回调
     */
    func didEndRefreshing()
    /**
     已经开始执行刷新逻辑，在一次刷新中，只会调用一次
     */
    func didBeginRefreshing()

    /**
     当Scroll触发刷新，这个方法返回是否需要刷新（比如你只想要点击刷新）
     */
    func shouldBeginRefreshingWhenScroll() -> Bool
}

fileprivate func < <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T: Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

public enum RefreshKitFooterText {
    case pullToRefresh
    case tapToRefresh
    case scrollAndTapToRefresh
    case refreshing
    case noMoreData
}

public enum RefreshMode {
    /// 只有Scroll才会触发
    case scroll
    /// 只有Tap才会触发
    case tap
    /// Scroll和Tap都会触发
    case scrollAndTap
}

open class DefaultRefreshFooter: UIView, RefreshableFooter {
    open static func footer() -> DefaultRefreshFooter {
        return DefaultRefreshFooter()
    }

    open let spinner: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    open let textLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 140, height: 40))
    /// 触发刷新的模式
    open var refreshMode = RefreshMode.scrollAndTap {
        didSet {
            tap.isEnabled = (refreshMode != .scroll)
            udpateTextLabelWithMode(refreshMode)
        }
    }

    fileprivate func udpateTextLabelWithMode(_ refreshMode: RefreshMode) {
        switch refreshMode {
        case .scroll:
            textLabel.text = textDic[.pullToRefresh]
        case .tap:
            textLabel.text = textDic[.tapToRefresh]
        case .scrollAndTap:
            textLabel.text = textDic[.scrollAndTapToRefresh]
        }
    }

    fileprivate var tap: UITapGestureRecognizer!
    fileprivate var textDic = [RefreshKitFooterText: String]()
    /**
     This function can only be called before Refreshing
     */
    open func setText(_ text: String, mode: RefreshKitFooterText) {
        textDic[mode] = text
        textLabel.text = textDic[.pullToRefresh]
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(spinner)
        addSubview(textLabel)
        textDic[.pullToRefresh] = PullToRefreshKitFooterString.pullUpToRefresh
        textDic[.refreshing] = PullToRefreshKitFooterString.refreshing
        textDic[.noMoreData] = PullToRefreshKitFooterString.noMoreData
        textDic[.tapToRefresh] = PullToRefreshKitFooterString.tapToRefresh
        textDic[.scrollAndTapToRefresh] = PullToRefreshKitFooterString.scrollAndTapToRefresh
        udpateTextLabelWithMode(refreshMode)
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.textAlignment = .center
        tap = UITapGestureRecognizer(target: self, action: #selector(DefaultRefreshFooter.catchTap(_:)))
        addGestureRecognizer(tap)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        spinner.center = CGPoint(x: frame.width / 2, y: frame.size.height / 2)
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func catchTap(_: UITapGestureRecognizer) {
        let scrollView = superview?.superview as? UIScrollView
        scrollView?.switchRefreshFooter(to: .refreshing)
    }

    // MARK: - Refreshable  -

    open func heightForFooter() -> CGFloat {
        return PullToRefreshKitConst.defaultFooterHeight
    }

    open func didBeginRefreshing() {
        isUserInteractionEnabled = true
        textLabel.text = textDic[.refreshing]
        spinner.startAnimating()
    }

    open func didEndRefreshing() {
        udpateTextLabelWithMode(refreshMode)
        spinner.stopAnimating()
    }

    open func didUpdateToNoMoreData() {
        isUserInteractionEnabled = false
        textLabel.text = textDic[.noMoreData]
    }

    open func didResetToDefault() {
        isUserInteractionEnabled = true
        udpateTextLabelWithMode(refreshMode)
    }

    open func shouldBeginRefreshingWhenScroll() -> Bool {
        return refreshMode != .tap
    }

    // MARK: - Handle touch -

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard refreshMode != .scroll else {
            return
        }
        backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard refreshMode != .scroll else {
            return
        }
        backgroundColor = UIColor.white
    }

    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        guard refreshMode != .scroll else {
            return
        }
        backgroundColor = UIColor.white
    }

    open override var tintColor: UIColor! {
        didSet {
            textLabel.textColor = tintColor
            spinner.color = tintColor
        }
    }
}

class RefreshFooterContainer: UIView {
    enum RefreshFooterState {
        case idle
        case refreshing
        case willRefresh
        case noMoreData
    }

    // MARK: - Propertys -

    var refreshAction: (() -> Void)?
    var attachedScrollView: UIScrollView!
    weak var delegate: RefreshableFooter?
    fileprivate var _state: RefreshFooterState = .idle
    var state: RefreshFooterState {
        get {
            return _state
        }
        set {
            guard newValue != _state else {
                return
            }
            _state = newValue
            if newValue == .refreshing {
                DispatchQueue.main.async(execute: {
                    self.delegate?.didBeginRefreshing()
                    self.refreshAction?()
                })
            } else if newValue == .noMoreData {
                self.delegate?.didUpdateToNoMoreData()
            } else if newValue == .idle {
                self.delegate?.didResetToDefault()
            }
        }
    }

    // MARK: - Init -

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    func commonInit() {
        backgroundColor = UIColor.clear
        autoresizingMask = .flexibleWidth
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life circle -

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        if state == .willRefresh {
            state = .refreshing
        }
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        guard newSuperview != nil else { // remove from superview
            if !isHidden {
                var inset = attachedScrollView.contentInset
                inset.bottom = inset.bottom - frame.height
                attachedScrollView.contentInset = inset
            }
            return
        }
        guard newSuperview is UIScrollView else {
            return
        }
        attachedScrollView = newSuperview as? UIScrollView
        attachedScrollView.alwaysBounceVertical = true
        if !isHidden {
            var contentInset = attachedScrollView.contentInset
            contentInset.bottom = contentInset.bottom + frame.height
            attachedScrollView.contentInset = contentInset
        }
        frame = CGRect(x: 0, y: attachedScrollView.contentSize.height, width: frame.width, height: frame.height)
        addObservers()
    }

    deinit {
        removeObservers()
    }

    // MARK: - Private -

    fileprivate func addObservers() {
        attachedScrollView?.addObserver(self, forKeyPath: PullToRefreshKitConst.KPathOffSet, options: [.old, .new], context: nil)
        attachedScrollView?.addObserver(self, forKeyPath: PullToRefreshKitConst.KPathContentSize, options: [.old, .new], context: nil)
        attachedScrollView?.panGestureRecognizer.addObserver(self, forKeyPath: PullToRefreshKitConst.KPathPanState, options: [.old, .new], context: nil)
    }

    fileprivate func removeObservers() {
        attachedScrollView?.removeObserver(self, forKeyPath: PullToRefreshKitConst.KPathContentSize, context: nil)
        attachedScrollView?.removeObserver(self, forKeyPath: PullToRefreshKitConst.KPathOffSet, context: nil)
        attachedScrollView?.panGestureRecognizer.removeObserver(self, forKeyPath: PullToRefreshKitConst.KPathPanState, context: nil)
    }

    func handleScrollOffSetChange(_ change: [NSKeyValueChangeKey: Any]?) {
        if state != .idle && frame.origin.y != 0 {
            return
        }
        let insetTop = attachedScrollView.contentInset.top
        let contentHeight = attachedScrollView.contentSize.height
        let scrollViewHeight = attachedScrollView.frame.size.height
        if insetTop + contentHeight > scrollViewHeight {
            let offSetY = attachedScrollView.contentOffset.y
            if offSetY > frame.origin.y - scrollViewHeight + attachedScrollView.contentInset.bottom {
                let oldOffset = (change?[NSKeyValueChangeKey.oldKey] as AnyObject).cgPointValue
                let newOffset = (change?[NSKeyValueChangeKey.newKey] as AnyObject).cgPointValue
                guard newOffset?.y > oldOffset?.y else {
                    return
                }
                let shouldStart = delegate?.shouldBeginRefreshingWhenScroll()
                guard shouldStart! else {
                    return
                }
                beginRefreshing()
            }
        }
    }

    func handlePanStateChange(_: [NSKeyValueChangeKey: Any]?) {
        guard state == .idle else {
            return
        }
        if attachedScrollView.panGestureRecognizer.state == .ended {
            let scrollInset = attachedScrollView.contentInset
            let scrollOffset = attachedScrollView.contentOffset
            let contentSize = attachedScrollView.contentSize
            if scrollInset.top + contentSize.height <= attachedScrollView.frame.height {
                if scrollOffset.y >= -1 * scrollInset.top {
                    let shouldStart = delegate?.shouldBeginRefreshingWhenScroll()
                    guard shouldStart! else {
                        return
                    }
                    beginRefreshing()
                }
            } else {
                if scrollOffset.y > contentSize.height + scrollInset.bottom - attachedScrollView.frame.height {
                    let shouldStart = delegate?.shouldBeginRefreshingWhenScroll()
                    guard shouldStart! else {
                        return
                    }
                    beginRefreshing()
                }
            }
        }
    }

    func handleContentSizeChange(_: [NSKeyValueChangeKey: Any]?) {
        frame = CGRect(x: 0, y: attachedScrollView.contentSize.height, width: frame.size.width, height: frame.size.height)
    }

    // MARK: - KVO -

    override func observeValue(forKeyPath keyPath: String?, of _: Any?, change: [NSKeyValueChangeKey: Any]?, context _: UnsafeMutableRawPointer?) {
        if keyPath == PullToRefreshKitConst.KPathOffSet && isUserInteractionEnabled {
            handleScrollOffSetChange(change)
        }
        guard !isHidden else {
            return
        }
        if keyPath == PullToRefreshKitConst.KPathPanState && isUserInteractionEnabled {
            handlePanStateChange(change)
        }
        if keyPath == PullToRefreshKitConst.KPathContentSize {
            handleContentSizeChange(change)
        }
    }

    // MARK: - API -

    func beginRefreshing() {
        if window != nil {
            state = .refreshing
        } else {
            if state != .refreshing {
                state = .willRefresh
            }
        }
    }

    func endRefreshing() {
        state = .idle
        delegate?.didEndRefreshing()
    }

    func resetToDefault() {
        state = .idle
    }

    func updateToNoMoreData() {
        state = .noMoreData
    }
}
