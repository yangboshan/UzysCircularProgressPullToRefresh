//
//  UIScrollView+UzysInteractiveIndicator.m
//  UzysRadialProgressActivityIndicator
//
//  Created by Uzysjung on 2013. 11. 12..
//  Copyright (c) 2013년 Uzysjung. All rights reserved.
//

#import "UIScrollView+UzysCircularProgressPullToRefresh.h"
#import <objc/runtime.h>
#define IS_IOS7 (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1)
#define cDefaultFloatComparisonEpsilon    0.001
#define cEqualFloats(f1, f2, epsilon)    ( fabs( (f1) - (f2) ) < epsilon )
#define cNotEqualFloats(f1, f2, epsilon)    ( !cEqualFloats(f1, f2, epsilon) )

static char UIScrollViewPullToRefreshView;

@implementation UIScrollView (UzysCircularProgressPullToRefresh)
@dynamic pullToRefreshView, showPullToRefresh;

- (void)addPullToRefreshActionHandler:(actionHandler)handler
{
    if(self.pullToRefreshView == nil)
    {
        [self addPullToRefreshActionHandler:handler portraitContentInsetTop:CGFLOAT_MAX landscapeInsetTop:CGFLOAT_MAX];
    }
}
- (void)addPullToRefreshActionHandler:(actionHandler)handler portraitContentInsetTop:(CGFloat)pInsetTop landscapeInsetTop:(CGFloat)lInsetTop
{
    if(self.pullToRefreshView == nil)
    {
        UzysRadialProgressActivityIndicator *view = [[UzysRadialProgressActivityIndicator alloc] initWithImage:[UIImage imageNamed:@"centerIcon"]];
        view.pullToRefreshHandler = handler;
        view.scrollView = self;
        view.frame = CGRectMake((self.bounds.size.width - view.bounds.size.width)/2,
                                -view.bounds.size.height, view.bounds.size.width, view.bounds.size.height);
        view.originalTopInset = self.contentInset.top;
        
        if(cEqualFloats(pInsetTop, CGFLOAT_MAX, cDefaultFloatComparisonEpsilon) && cEqualFloats(lInsetTop, CGFLOAT_MAX, cDefaultFloatComparisonEpsilon)) //NOT DEFINE LANDSCAPE , PORTRAIT INSET
        {
            if(IS_IOS7)
            {
                if(cEqualFloats(self.contentInset.top, 64.00, cDefaultFloatComparisonEpsilon))
                {
                    view.portraitTopInset = 64.0;
                    view.landscapeTopInset = 52.0;
                }
            }

        }
        else //DEFINE LANDSCAPE PORTRAIT INSET
        {
            view.portraitTopInset = pInsetTop;
            view.landscapeTopInset = lInsetTop;
        }
        
        [self addSubview:view];
        [self sendSubviewToBack:view];
        self.pullToRefreshView = view;
        self.showPullToRefresh = YES;
    }
}

- (void)triggerPullToRefresh
{
    [self.pullToRefreshView manuallyTriggered];
}
- (void)stopRefreshAnimation
{
    [self.pullToRefreshView stopIndicatorAnimation];
}
#pragma mark - property
- (void)addTopInsetInPortrait:(CGFloat)pInset TopInsetInLandscape:(CGFloat)lInset
{
    self.pullToRefreshView.portraitTopInset = pInset;
    self.pullToRefreshView.landscapeTopInset = lInset;
}
- (void)setPullToRefreshView:(UzysRadialProgressActivityIndicator *)pullToRefreshView
{
    [self willChangeValueForKey:@"UzysRadialProgressActivityIndicator"];
    objc_setAssociatedObject(self, &UIScrollViewPullToRefreshView, pullToRefreshView, OBJC_ASSOCIATION_ASSIGN);
    [self didChangeValueForKey:@"UzysRadialProgressActivityIndicator"];
}
- (UzysRadialProgressActivityIndicator *)pullToRefreshView
{
    return objc_getAssociatedObject(self, &UIScrollViewPullToRefreshView);
}

- (void)setShowPullToRefresh:(BOOL)showPullToRefresh {
    self.pullToRefreshView.hidden = !showPullToRefresh;
    
    if(showPullToRefresh)
    {
        if(!self.pullToRefreshView.isObserving)
        {
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.pullToRefreshView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];

            self.pullToRefreshView.isObserving = YES;
        }
    }
    else
    {
        if(self.pullToRefreshView.isObserving)
        {
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentOffset"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"contentSize"];
            [self removeObserver:self.pullToRefreshView forKeyPath:@"frame"];
            [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];

            self.pullToRefreshView.isObserving = NO;
        }
    }
}

- (BOOL)showPullToRefresh
{
    return !self.pullToRefreshView.hidden;
}

- (void) orientationChanged:(NSNotification *)note
{
    UIDevice * device = note.object;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(UIDeviceOrientationIsLandscape(device.orientation))
        {
            if(cNotEqualFloats( self.pullToRefreshView.landscapeTopInset , 0.0 , cDefaultFloatComparisonEpsilon))
                self.pullToRefreshView.originalTopInset = self.pullToRefreshView.landscapeTopInset;
        }
        else
        {
            if(cNotEqualFloats( self.pullToRefreshView.portraitTopInset , 0.0 , cDefaultFloatComparisonEpsilon))
                self.pullToRefreshView.originalTopInset = self.pullToRefreshView.portraitTopInset;
        }
        [self.pullToRefreshView setSize:self.pullToRefreshView.frame.size];
     });
}

@end
