//
//  ElasticRefreshHeader.swift
//  PullToRefreshKit
//
//  Created by huangwenchen on 16/7/29.
//  Copyright © 2016年 Leo. All rights reserved.
//

import Foundation
import UIKit

open class ElasticRefreshHeader: UIView, RefreshableHeader {
    let control: ElasticRefreshControl
    open let textLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 120, height: 40))
    open let imageView: UIImageView = UIImageView(frame: CGRect.zero)
    fileprivate var textDic = [RefreshKitHeaderText: String]()
    override init(frame: CGRect) {
        control = ElasticRefreshControl(frame: frame)
        super.init(frame: frame)
        autoresizingMask = .flexibleWidth
        backgroundColor = UIColor.white
        imageView.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        textLabel.font = UIFont.systemFont(ofSize: 12)
        textLabel.textAlignment = .center
        textLabel.textColor = UIColor.darkGray
        addSubview(control)
        addSubview(textLabel)
        addSubview(imageView)
        textDic[.refreshSuccess] = PullToRefreshKitHeaderString.refreshSuccess
        textDic[.refreshFailure] = PullToRefreshKitHeaderString.refreshFailure
        textLabel.text = nil
    }

    open func setText(_ text: String, mode: RefreshKitHeaderText) {
        textDic[mode] = text
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        control.frame = bounds
        textLabel.sizeToFit()
        textLabel.center = CGPoint(x: frame.size.width / 2.0, y: frame.size.height * 0.75)
        imageView.center = CGPoint(x: textLabel.frame.origin.x - imageView.frame.size.width - 8.0, y: frame.size.height * 0.75)
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if let superView = newSuperview {
            frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: superView.frame.size.width, height: frame.size.height)
        }
    }

    // MARK: - Refreshable Header -

    open func heightForHeader() -> CGFloat {
        return 80.0
    }

    public func heightForFireRefreshing() -> CGFloat {
        return 80.0
    }

    open func heightForRefreshingState() -> CGFloat {
        return 80.0 / 2.0
    }

    open func percentUpdateDuringScrolling(_ percent: CGFloat) {
        control.animating = false
        if percent > 0.5 && percent <= 1.0 {
            control.progress = (percent - 0.5) / 0.5
        } else if percent <= 0.5 {
            control.progress = 0.0
        } else {
            control.progress = 1.0
        }
    }

    open func didBeginRefreshingState() {
        control.animating = true
    }

    open func didBeginHideAnimation(_ result: RefreshResult) {
        switch result {
        case .success:
            control.isHidden = true
            imageView.isHidden = false
            textLabel.isHidden = false
            textLabel.text = textDic[.refreshSuccess]
            imageView.image = UIImage(named: "success", in: Bundle(for: DefaultRefreshHeader.self), compatibleWith: nil)
        case .failure:
            control.isHidden = true
            imageView.isHidden = false
            textLabel.isHidden = false
            textLabel.text = textDic[.refreshFailure]
            imageView.image = UIImage(named: "failure", in: Bundle(for: DefaultRefreshHeader.self), compatibleWith: nil)
        case .none:
            control.isHidden = false
            imageView.isHidden = true
            textLabel.isHidden = true
            textLabel.text = textDic[.pullToRefresh]
            imageView.image = nil
        }
        setNeedsLayout()
    }

    open func didCompleteHideAnimation(_: RefreshResult) {
        control.isHidden = false
        imageView.isHidden = true
        textLabel.isHidden = true
    }
}
