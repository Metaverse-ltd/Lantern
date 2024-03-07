//
//  Lantern.swift
//  Lantern
//
//  Created by JiongXing on 2019/11/11.
//  Copyright © 2021 Shenzhen Hive Box Technology Co.,Ltd All rights reserved.
//

import UIKit

open class Lantern: UIViewController, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {
    
    /// 通过本回调，把图片浏览器嵌套在导航控制器里
    public typealias PresentEmbedClosure = (Lantern) -> UINavigationController
    
    /// 打开方式类型
    public enum ShowMethod {
        case push(inNC: UINavigationController?)
        case present(fromVC: UIViewController?, embed: PresentEmbedClosure?)
    }
    
    /// 滑动方向类型
    public enum ScrollDirection {
        case horizontal
        case vertical
    }
    
    /// 自实现转场动画
    open lazy var transitionAnimator: LanternAnimatedTransitioning = LanternFadeAnimator()
    
    /// 滑动方向
    open var scrollDirection: Lantern.ScrollDirection {
        set { browserView.scrollDirection = newValue }
        get { browserView.scrollDirection }
    }
    
    /// 项间距
    open var itemSpacing: CGFloat {
        set { browserView.itemSpacing = newValue }
        get { browserView.itemSpacing }
    }
    
    /// 新增更多num之前的数据总量
    open var lastNumberOfItems: Int {
        set { browserView.lastNumberOfItems = newValue }
        get { browserView.lastNumberOfItems }
    }
    
    /// 当前页码
    open var pageIndex: Int {
        set { browserView.pageIndex = newValue }
        get { browserView.pageIndex }
    }
    
    /// 浏览过程中实时获取数据总量
    open var numberOfItems: () -> Int {
        set { browserView.numberOfItems = newValue }
        get { browserView.numberOfItems }
    }
    
    /// 返回可复用的Cell类。用户可根据index返回不同的类。本闭包将在每次复用Cell时实时调用。
    open var cellClassAtIndex: (_ index: Int) -> LanternCell.Type {
        set { browserView.cellClassAtIndex = newValue }
        get { browserView.cellClassAtIndex }
    }
    
    /// Cell刷新时用的上下文。index: 刷新的Cell对应的index；currentIndex: 当前显示的页
    public typealias ReloadCellContext = (cell: LanternCell, index: Int, currentIndex: Int)
    
    /// 刷新Cell数据。本闭包将在Cell完成位置布局后调用。
    open var reloadCellAtIndex: (ReloadCellContext) -> Void {
        set { browserView.reloadCellAtIndex = newValue }
        get { browserView.reloadCellAtIndex }
    }
    
    /// 自然滑动引起的页码改变时回调
    open lazy var didChangedPageIndex: (_ index: Int) -> Void = { _ in }
    
    /// Cell将显示
    open var cellWillAppear: (LanternCell, Int) -> Void {
        set { browserView.cellWillAppear = newValue }
        get { browserView.cellWillAppear }
    }
    
    /// Cell将不显示
    open var cellWillDisappear: (LanternCell, Int) -> Void {
        set { browserView.cellWillDisappear = newValue }
        get { browserView.cellWillDisappear }
    }
    
    /// Cell已显示
    open var cellDidAppear: (LanternCell, Int) -> Void {
        set { browserView.cellDidAppear = newValue }
        get { browserView.cellDidAppear }
    }
    
    /// 即将dismiss
    /// - Returns: 是否执行动画
    open var willDismiss: ((Lantern) -> Bool)?
    
    /// 已经dismiss
    open var didDismiss: ((Lantern) -> Void)?
    
    /// 主视图
    open lazy var browserView = LanternView()
    
    /// 页码指示
    open var pageIndicator: LanternPageIndicator?
    
    /// 背景蒙版
    open lazy var maskView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    
    open weak var previousNavigationControllerDelegate: UINavigationControllerDelegate?
    
    deinit {
        LanternLog.high("deinit - \(self.classForCoder)")
    }
    
    /// 显示图片浏览器
    open func show(method: ShowMethod = .present(fromVC: nil, embed: nil)) {
        switch method {
        case .push(let inNC):
            let nav = inNC ?? Lantern.topMost?.navigationController
            previousNavigationControllerDelegate = nav?.delegate
            nav?.delegate = self
            nav?.pushViewController(self, animated: true)
        case .present(let fromVC, let embed):
            let toVC = embed?(self) ?? self
            toVC.modalPresentationStyle = .custom
            toVC.transitioningDelegate = self
            let from = fromVC ?? Lantern.topMost
            from?.present(toVC, animated: true, completion: nil)
        }
    }
    
    /// 刷新
    open func reloadData() {
        // 图片数量为0时，移除
        if numberOfItems() == 0 {
            dismiss()
            return
        }
        browserView.reloadData()
        pageIndicator?.reloadData(numberOfItems: numberOfItems(), pageIndex: pageIndex)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 11.0, *) {
            self.browserView.scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        hideNavigationBar(true)
        
        browserView.lantern = self
        transitionAnimator.lantern = self
        
        view.backgroundColor = .clear
        view.addSubview(maskView)
        view.addSubview(browserView)
        
        browserView.didChangedPageIndex = { [weak self] index in
            guard let `self` = self else { return }
            self.pageIndicator?.didChanged(pageIndex: index)
            self.didChangedPageIndex(index)
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        maskView.frame = view.bounds
        browserView.frame = view.bounds
        pageIndicator?.reloadData(numberOfItems: numberOfItems(), pageIndex: pageIndex)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideNavigationBar(true)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.delegate = previousNavigationControllerDelegate
        if let indicator = pageIndicator {
            view.addSubview(indicator)
            indicator.setup(with: self)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.delegate = previousNavigationControllerDelegate
        hideNavigationBar(false)
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        browserView.isRotating = true
    }
    
    //
    // MARK: - Navigation Bar
    //
    
    /// 在PhotoBrowser打开之前，导航栏是否隐藏
    open var isPreviousNavigationBarHidden: Bool?
    
    private func hideNavigationBar(_ hide: Bool) {
        if hide {
            if isPreviousNavigationBarHidden == nil {
                isPreviousNavigationBarHidden = navigationController?.isNavigationBarHidden
            }
            navigationController?.setNavigationBarHidden(true, animated: false)
        } else {
            if let barHidden = isPreviousNavigationBarHidden {
                navigationController?.setNavigationBarHidden(barHidden, animated: false)
            }
        }
    }
    
    //
    // MARK: - 转场
    //
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = true
        transitionAnimator.lantern = self
        return transitionAnimator
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = false
        transitionAnimator.lantern = self
        return transitionAnimator
    }
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isForShow = (operation == .push)
        transitionAnimator.lantern = self
        transitionAnimator.isNavigationAnimation = true
        return transitionAnimator
    }
    
    /// 关闭PhotoBrowser
    open func dismiss() {
        let animated = willDismiss?(self) ?? true
        pageIndicator?.removeFromSuperview()
        if presentingViewController != nil {
            presentingViewController?.dismiss(animated: animated) { [weak self] in
                if let self {
                    self.didDismiss?(self)
                }
            }
        } else {
            navigationController?.delegate = self
            navigationController?.popViewController(animated: true)
            didDismiss?(self)
        }
    }
    
    //
    // MARK: - 取顶层控制器
    //

    /// 取最顶层的ViewController
    open class var topMost: UIViewController? {
        return topMost(of: UIApplication.shared.keyWindow?.rootViewController)
    }
    
    open class func topMost(of viewController: UIViewController?) -> UIViewController? {
        // presented view controller
        if let presentedViewController = viewController?.presentedViewController {
            return self.topMost(of: presentedViewController)
        }
        
        // UITabBarController
        if let tabBarController = viewController as? UITabBarController,
            let selectedViewController = tabBarController.selectedViewController {
            return self.topMost(of: selectedViewController)
        }
        
        // UINavigationController
        if let navigationController = viewController as? UINavigationController,
            let visibleViewController = navigationController.visibleViewController {
            return self.topMost(of: visibleViewController)
        }
        
        // UIPageController
        if let pageViewController = viewController as? UIPageViewController,
            pageViewController.viewControllers?.count == 1 {
            return self.topMost(of: pageViewController.viewControllers?.first)
        }
        
        // child view controller
        for subview in viewController?.view?.subviews ?? [] {
            if let childViewController = subview.next as? UIViewController {
                return self.topMost(of: childViewController)
            }
        }
        
        return viewController
    }
}
