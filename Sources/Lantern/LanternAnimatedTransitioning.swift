//
//  LanternAnimatedTransitioning.swift
//  Lantern
//
//  Created by JiongXing on 2019/11/25.
//  Copyright © 2021 Shenzhen Hive Box Technology Co.,Ltd All rights reserved.
//

import UIKit

public protocol LanternAnimatedTransitioning: UIViewControllerAnimatedTransitioning {
    var isForShow: Bool { get set }
    var lantern: Lantern? { get set }
    var isNavigationAnimation: Bool { get set }
}

private var isForShowKey = "isForShowKey"
private var lanternKey = "lanternKey"

extension LanternAnimatedTransitioning {
    
    public var isForShow: Bool {
        get {
            if let value = objc_getAssociatedObject(self, &isForShowKey) as? Bool {
                return value
            }
            return true
        }
        set {
            objc_setAssociatedObject(self, &isForShowKey, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    public weak var lantern: Lantern? {
        get {
            if let wrapper = objc_getAssociatedObject(self, &lanternKey) as? LanternWeakAssociationWrapper {
                return wrapper.target as? Lantern
            }
            return nil
        }
        set {
            let wrapper = LanternWeakAssociationWrapper(target: newValue)
            objc_setAssociatedObject(self, &lanternKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var isNavigationAnimation: Bool {
        get { false }
        set { }
    }
    
    public func fastSnapshot(with view: UIView) -> UIView? {
        let snapshot = view.snapshotView(afterScreenUpdates: true)
        return snapshot
    }
    
    public func snapshot(with view: UIView) -> UIView? {
        let snapshot = view.snapshotView(afterScreenUpdates: true)
        return snapshot
    }
}

struct LanternWeakAssociationWrapper {
    
    weak var target: AnyObject?
    
    init(target: AnyObject? = nil) {
        self.target = target
    }
}
