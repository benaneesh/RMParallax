// RMParallax
//
// Copyright (c) 2015 RMParallax
//
// Created by Raphael Miller & Michael Babiy
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

/**
*  Completion handler for dismissal of the parallax view.
*/
typealias RMParallaxCompletionHandler = () -> Void
typealias RMParallaxLoginHandler = () -> Void
typealias RMParallaxSignupHandler = () -> Void

enum ScrollDirection: Int {
    case Right = 0, Left
}

var rm_text_span_width: CGFloat = 320.0
let rm_percentage_multiplier: CGFloat = 0.4
let rm_percentage_multiplier_text: CGFloat = 0.8

let rm_motion_frame_offset: CGFloat = 15.0
let rm_motion_magnitude: CGFloat = rm_motion_frame_offset / 3.0

import UIKit

protocol RMParallaxDelegate {
    func didPressSignupButton()
    func didPressLoginButton()
}

class RMParallax : UIViewController, UIScrollViewDelegate {
    
    var completionHandler: RMParallaxCompletionHandler!
    var delegate: RMParallaxDelegate?
    
    var items: [RMParallaxItem]!
    var motion = false
    
    var scrollView: UIScrollView!
    var loginButton: UIButton!
    var signupButton: UIButton!
    var pageControl: UIPageControl!
    var pageControlOffset: CGFloat = 17.0
    
    var currentPageNumber: Int = 0 {
        didSet {
            pageControl.currentPage = currentPageNumber
        }
    }
    
    var otherPageNumber = 0
    var viewWidth: CGFloat = 0.0
    var lastContentOffset: CGFloat = 0.0
    var titleFont: UIFont?
    var loginButtonOffset: CGFloat = 15.0
    var loginTintColor: UIColor?
    var signupButtonOffset: CGFloat = 17.0
    var signupTintColor: UIColor?
    
    var textOffset: CGFloat = 17
    
    /**
    *  Designated initializer.
    *
    *  @param items  - an array of RMParallaxItems to page through.
    *  @param motion - if set to TRUE, a very subtle motion effect will be added to the image view.
    */
    required init(items: [RMParallaxItem], motion: Bool) {
        super.init(nibName: nil, bundle: nil)
        self.items = items
        self.motion = motion
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Use init with items, motion.")
    }
    
    // MARK : Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rm_text_span_width = self.view.frame.width
        self.setupRMParallax()
    }
    
    // MARK : Setup
    
    func setupRMParallax() {
        let frame = CGRectMake(0, 0, self.view.frame.width - 100, 44)
        self.loginButton = UIButton(frame: frame)
        self.loginButton.setTitle("Log In", forState: .Normal)
        self.loginButton.tintColor = loginTintColor ?? UIColor.whiteColor()
        self.loginButton.center = CGPointMake(self.view.center.x, self.view.frame.size.height - loginButtonOffset - frame.height/2 )
        self.loginButton.addTarget(self, action: "loginButtonSelected:", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.signupButton = UIButton(frame: frame)
        self.signupButton.setTitle("Sign In", forState: .Normal)
        self.signupButton.backgroundColor = UIColor.whiteColor()
        self.signupButton.setTitleColor(signupTintColor ?? UIColor.redColor(), forState: .Normal)
        self.signupButton.center = CGPointMake(self.view.center.x, self.loginButton.center.y - signupButtonOffset - frame.height/2 - self.loginButton.frame.height/2 )
        self.signupButton.layer.cornerRadius = 5
        self.signupButton.addTarget(self, action: "signupButtonSelected:", forControlEvents: UIControlEvents.TouchUpInside)
        
        self.pageControl = UIPageControl(frame: CGRectMake(0, 20, self.view.frame.width, 20))
        self.pageControl.numberOfPages = self.items.count
        self.pageControl.hidesForSinglePage = true
        self.pageControl.pageIndicatorTintColor = UIColor.whiteColor()
        self.pageControl.currentPageIndicatorTintColor = signupTintColor ?? UIColor.redColor()
        self.pageControl.center = CGPointMake(self.view.center.x, self.signupButton.center.y - self.pageControlOffset - self.pageControl.frame.height/2 - self.signupButton.frame.height/2)
        
        self.scrollView = UIScrollView(frame: self.view.frame)
        self.scrollView.showsHorizontalScrollIndicator = false;
        self.scrollView.pagingEnabled = true;
        self.scrollView.delegate = self;
        self.scrollView.bounces = false;
        
        self.viewWidth = self.view.frame.size.width
        
        self.view.addSubview(self.scrollView)
        self.view.insertSubview(self.loginButton, aboveSubview: self.scrollView)
        self.view.insertSubview(self.signupButton, aboveSubview: self.scrollView)
        self.view.insertSubview(self.pageControl, aboveSubview: self.scrollView)
        
        for (index, item) in self.items.enumerate() {
            let diff: CGFloat = 0.0
            let frame = CGRectMake((self.view.frame.size.width * CGFloat(index)), 0.0, self.viewWidth, self.view.frame.size.height)
            let subview = UIView(frame: frame)
            
            let internalScrollView = UIScrollView(frame: CGRectMake(diff, 0.0, self.viewWidth - (diff * 2.0), self.view.frame.size.height))
            internalScrollView.scrollEnabled = false
            
            let internalTextScrollView = UIScrollView(frame: CGRectMake(diff, 0.0, self.viewWidth - (diff * 2.0), self.view.frame.size.height))
            internalTextScrollView.scrollEnabled = false
            internalTextScrollView.backgroundColor = UIColor.clearColor()
            
            //
            
            let imageViewFrame = self.motion ?
                CGRectMake(0.0, 0.0, internalScrollView.frame.size.width + rm_motion_frame_offset, self.view.frame.size.height + rm_motion_frame_offset) :
                CGRectMake(0.0, 0.0, internalScrollView.frame.size.width, self.view.frame.size.height)
            let imageView = UIImageView(frame: imageViewFrame)
            if self.motion { self.addMotionEffectToView(imageView, magnitude: rm_motion_magnitude) }
            imageView.contentMode = UIViewContentMode.ScaleAspectFill
            internalScrollView.tag = (index + 1) * 10
            internalTextScrollView.tag = (index + 1) * 100
            imageView.tag = (index + 1) * 1000
            
            //
            
            
            let attributes = [NSFontAttributeName : titleFont ?? UIFont.systemFontOfSize(35.0)]
            let context = NSStringDrawingContext()
            let rect = (item.text as NSString).boundingRectWithSize(CGSizeMake(rm_text_span_width, CGFloat.max),
                options: NSStringDrawingOptions.UsesLineFragmentOrigin,
                attributes: attributes,
                context: context)
            
            //
            
            let textView = UITextView(frame: CGRectMake(textOffset, textOffset, rect.size.width, rect.size.height))
            textView.text = item.text
            textView.textColor = UIColor.whiteColor()
            textView.backgroundColor = UIColor.clearColor()
            textView.userInteractionEnabled = false
            imageView.image = item.image
            textView.font = UIFont.systemFontOfSize(32.0)

            internalTextScrollView.addSubview(textView)
            internalScrollView.bringSubviewToFront(textView)
            
            internalScrollView.addSubview(imageView)
            internalScrollView.addSubview(internalTextScrollView)
            
            subview.addSubview(internalScrollView)
            self.scrollView.addSubview(subview)
        }
        self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width * CGFloat(self.items.count), self.view.frame.size.height)
    }
    
    // MARK : Action Functions
    
    func loginButtonSelected(sender: UIButton) {
        delegate?.didPressLoginButton()
    }
    
    func signupButtonSelected(sender: UIButton) {
        delegate?.didPressSignupButton()
    }
    
    // MARK : UIScrollViewDelegate
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        let internalScrollView = scrollView.viewWithTag((self.currentPageNumber + 1) * 10) as? UIScrollView
        let otherScrollView = scrollView.viewWithTag((self.otherPageNumber + 1) * 10) as? UIScrollView
        let internalTextScrollView = scrollView.viewWithTag((self.currentPageNumber + 1) * 100) as? UIScrollView
        let otherTextScrollView = scrollView.viewWithTag((self.otherPageNumber + 1) * 100) as? UIScrollView
        
        if let internalScrollView = internalScrollView {
            internalScrollView.contentOffset = CGPointMake(0.0, 0.0)
        }
        
        if let otherScrollView = otherScrollView {
            otherScrollView.contentOffset = CGPointMake(0.0, 0.0)
        }
        
        if let internalTextScrollView = internalTextScrollView {
            internalTextScrollView.contentOffset = CGPointMake(0.0, 0.0)
        }
        
        if let otherTextScrollView = otherTextScrollView {
            otherTextScrollView.contentOffset = CGPointMake(0.0, 0.0)
        }
        
        self.currentPageNumber = Int(scrollView.contentOffset.x) / Int(scrollView.frame.size.width)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var multiplier: CGFloat = 1.0
        
        let offset: CGFloat = scrollView.contentOffset.x

        if self.lastContentOffset > scrollView.contentOffset.x {
            if self.currentPageNumber > 0 {
                if offset >  CGFloat(self.currentPageNumber - 1) * viewWidth{
                    self.otherPageNumber = self.currentPageNumber + 1
                    multiplier = 1.0
                } else {
                    self.otherPageNumber = self.currentPageNumber - 1
                    multiplier = -1.0
                }
            }
            
        } else if self.lastContentOffset < scrollView.contentOffset.x {
            if offset <  CGFloat(self.currentPageNumber - 1) * viewWidth{
                self.otherPageNumber = self.currentPageNumber - 1
                multiplier = -1.0
            } else {
                self.otherPageNumber = self.currentPageNumber + 1
                multiplier = 1.0
            }
        }
        
        self.lastContentOffset = scrollView.contentOffset.x
        
        let internalScrollView = scrollView.viewWithTag((self.currentPageNumber + 1) * 10) as? UIScrollView
        let otherScrollView = scrollView.viewWithTag((self.otherPageNumber + 1) * 10) as? UIScrollView
        let internalTextScrollView = scrollView.viewWithTag((self.currentPageNumber + 1) * 100) as? UIScrollView
        let otherTextScrollView = scrollView.viewWithTag((self.otherPageNumber + 1) * 100) as? UIScrollView
        
        if let internalScrollView = internalScrollView {
            internalScrollView.contentOffset = CGPointMake(-rm_percentage_multiplier * (offset - (self.viewWidth * CGFloat(self.currentPageNumber))), 0.0)
        }
        
        if let otherScrollView = otherScrollView {
            otherScrollView.contentOffset = CGPointMake(multiplier * rm_percentage_multiplier * self.viewWidth - (rm_percentage_multiplier * (offset - (self.viewWidth * CGFloat(self.currentPageNumber)))), 0.0)
        }

        if let internalTextScrollView = internalTextScrollView {
            internalTextScrollView.contentOffset = CGPointMake(-rm_percentage_multiplier_text * (offset - (self.viewWidth * CGFloat(self.currentPageNumber))), 0.0)
        }
        
        if let otherTextScrollView = otherTextScrollView {
            otherTextScrollView.contentOffset = CGPointMake(multiplier * rm_percentage_multiplier_text * self.viewWidth - (rm_percentage_multiplier_text * (offset - (self.viewWidth * CGFloat(self.currentPageNumber)))), 0.0)
        }
        
    }
    
    // MARK : Motion Effects
    
    func addMotionEffectToView(view: UIView, magnitude: CGFloat) -> Void {
        let xMotion = UIInterpolatingMotionEffect(keyPath: "center.x", type: UIInterpolatingMotionEffectType.TiltAlongHorizontalAxis)
        let yMotion = UIInterpolatingMotionEffect(keyPath: "center.y", type: UIInterpolatingMotionEffectType.TiltAlongVerticalAxis)
        xMotion.minimumRelativeValue = (-magnitude)
        xMotion.maximumRelativeValue = (magnitude)
        yMotion.minimumRelativeValue = (-magnitude)
        yMotion.maximumRelativeValue = (magnitude)
        let motionGroup = UIMotionEffectGroup()
        motionGroup.motionEffects = [xMotion, yMotion]
        view.addMotionEffect(motionGroup)
    }
}
