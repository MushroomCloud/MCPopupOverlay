//
//  MCPopupOverlayView.m
//  Popup Demo
//
//  Created by Rayman Rosevear on 2015/08/07.
//  Copyright (c) 2015 Mushroom Cloud. All rights reserved.
//

#import "MCPopupOverlayView.h"

#import "MCPDynamicDismissPanController.h"
#import "MCPSingleViewGestureDelegate.h"
#import "UIResponder+MCPFirstResponderNotifications.h"

static const CGFloat kAnimationDuration = 0.2f;

@interface MCPopupOverlayView () <MCPDynamicDismissPanDelegate>

/**
 *	This view fills the background view, and contains the popup.
 *	It is used with UIKit Dynamics to dismiss the popup
 */
@property (nonatomic, strong) UIScrollView * popupContainerView;

@property (nonatomic, strong) UIView *  backgroundView;
@property (nonatomic, strong) UIView *  popupView;
@property (nonatomic, strong) UILabel * panToDismissLabel;

@property (nonatomic, assign) BOOL   keyboardIsUp;
@property (nonatomic, assign) CGRect keyboardIntersectionFrame;
@property (nonatomic, weak) UIView *previousFirstResponder;

@property (nonatomic, strong) MCPSingleViewGestureDelegate *backgroundTapGestureDelegate;
@property (nonatomic, strong) NSArray *disabledGestureRecognizers;

@property (nonatomic, strong) MCPDynamicDismissPanController * dismissGestureController;

- (void)setupPopupOverlay;
- (void)setupBackgroundView;
- (void)setupPopupContainerView;
- (void)setupPopupView;
- (void)setupPanToDismissLabel;

- (void)adjustContentOffsetForFirstResponder;

- (void)keyboardFrameChanged:(NSNotification *)notification;
- (void)firstResponderDidChange:(NSNotification *)notification;

/**
 *	Disables all gesture recognizers in the view, returning all
 *	the gesture recognizers that were disabled (any recognizers
 *	that were already disabled are not included in the return
 *	value)
 */
- (NSArray *)disableGestureRecognizersInView:(UIView *)view;
- (void)backgroundTap:(UITapGestureRecognizer *)gesture;

- (void)animateBackgroundOut:(CGFloat)duration;
- (void)finishDismiss;

@end

@implementation MCPopupOverlayView

// *****************************************************************************************************
#pragma mark - Object Life Cycle
// *****************************************************************************************************

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setupPopupOverlay];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        [self setupPopupOverlay];
    }
    return self;
}

- (void)setupPopupOverlay
{
    self.clipsToBounds = YES;
    
    [self setupBackgroundView];
    [self setupPopupContainerView];
    [self setupPopupView];
    [self setupPanToDismissLabel];
    
    [_popupView addSubview:_panToDismissLabel];
    [_popupContainerView addSubview:_popupView];
    
    [self addSubview:_backgroundView];
    [self addSubview:_popupContainerView];
    
    [UIResponder ensureResponderNotificationsInitialized];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardFrameChanged:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(firstResponderDidChange:)
                                                 name:kMCPUIResponderDidBecomFirstResponderNotification
                                               object:nil];
}

- (void)setupBackgroundView
{
    // During autorotation, it is more efficient/smoother to just rotate the background instead of scale its size as well,
    // especially on older devices
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat maxDimension = MAX(screenSize.width, screenSize.height);
    
    UIView *backgroundView = [UIView new];
    backgroundView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.4f];
    backgroundView.bounds = CGRectMake(0.0f, 0.0f, maxDimension, maxDimension);
    
    self.backgroundView = backgroundView;
}

- (void)setupPopupContainerView
{
    UIScrollView *popupContainerView = [UIScrollView new];
    popupContainerView.delaysContentTouches = NO;
    popupContainerView.showsHorizontalScrollIndicator = NO;
    popupContainerView.showsVerticalScrollIndicator = NO;
    popupContainerView.backgroundColor = [UIColor clearColor];
    
    self.backgroundTapGestureDelegate = [MCPSingleViewGestureDelegate new];
    self.backgroundTapGestureDelegate.view = popupContainerView;
    
    UITapGestureRecognizer *backgroundTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)];
    backgroundTapGesture.cancelsTouchesInView = NO;
    backgroundTapGesture.delegate = self.backgroundTapGestureDelegate;
    
    [popupContainerView addGestureRecognizer:backgroundTapGesture];
    
    self.popupContainerView = popupContainerView;
}

- (void)setupPopupView
{
    UIView *popupView = [UIView new];
    popupView.backgroundColor = [UIColor whiteColor];
    popupView.layer.shadowColor = [UIColor blackColor].CGColor;
    popupView.layer.shadowOffset = CGSizeZero;
    popupView.layer.shadowRadius = 5.0f;
    popupView.layer.shadowOpacity = 0.5f;
    popupView.layer.borderWidth = 1;
    popupView.layer.borderColor = [UIColor clearColor].CGColor;
    popupView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    popupView.layer.shouldRasterize = YES;
    
    _dismissGestureController = [[MCPDynamicDismissPanController alloc] initForView:_popupView inContainer:nil];
    _dismissGestureController.delegate = self;
    _dismissGestureController.gestureRecognizer.enabled = _panToDismissEnabled;
    
    self.popupView = popupView;
}

- (void)setupPanToDismissLabel
{
    UILabel *panToDismissLabel = [UILabel new];
    panToDismissLabel.backgroundColor = [UIColor clearColor];
    panToDismissLabel.textColor = [UIColor whiteColor];
    panToDismissLabel.text = NSLocalizedString(@"Swipe down to dismiss", nil);
    panToDismissLabel.alpha = _panToDismissEnabled ? 1.0f : 0.0f;
    
    self.panToDismissLabel = panToDismissLabel;
}

// *****************************************************************************************************
#pragma mark - Layout
// *****************************************************************************************************

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.backgroundView.center = CGPointMake(self.bounds.size.width / 2.0f, self.bounds.size.height / 2.0f);
    
    CGSize preferredContentSize = [self preferredPopupSize];
    self.popupView.bounds = CGRectMake(0.0f,
                                       0.0f,
                                       MIN(preferredContentSize.width, self.bounds.size.width - self.popupViewMaxInsets.width),
                                       MIN(preferredContentSize.height, self.bounds.size.height - self.popupViewMaxInsets.height));
    self.popupView.center = CGPointMake(self.bounds.size.width / 2.0f, self.bounds.size.height / 2.0f);
    self.popupView.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.popupView.bounds].CGPath;
    
    [self.panToDismissLabel sizeToFit];
    self.panToDismissLabel.frame = CGRectMake((self.popupView.bounds.size.width - self.panToDismissLabel.bounds.size.width) / 2.0f,
                                              -(self.panToDismissLabel.bounds.size.height + 5.0f),
                                              self.panToDismissLabel.bounds.size.width,
                                              self.panToDismissLabel.bounds.size.height);
    
    if (self.dismissGestureController.isActive)
    {
        // Don't change the position if the popup is being dragged
        self.popupContainerView.bounds = self.bounds;
    }
    else
    {
        self.popupContainerView.frame = self.bounds;
    }
    self.popupContainerView.contentSize = CGSizeMake(CGRectGetWidth(self.popupContainerView.bounds),
                                                     CGRectGetMaxY(self.popupView.frame));
}

- (CGSize)preferredPopupSize
{
    return CGSizeMake(290.0f,
                      200.0f);
}

// *****************************************************************************************************
#pragma mark - Lazy Accessors
// *****************************************************************************************************

// Make this lazily evaulated, so that a subclass can replace the on screen popup with a new one by
// setting this property to nil
- (UIView *)popupView
{
    if (_popupView == nil)
    {
        [self setupPopupView];
    }
    return _popupView;
}

// *****************************************************************************************************
#pragma mark - Public Interface
// *****************************************************************************************************

- (void)showInView:(UIView *)view
{
    [view endEditing:YES];
    [view addSubview:self];
    self.disabledGestureRecognizers = [self disableGestureRecognizersInView:view];
    
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.frame = view.bounds;
    self.alpha = 1.0;
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    [self animateBackgroundIn];
    [self animatePopupIn];
}

- (void) dismiss
{
    [self animateBackgroundOut];
    [self animatePopupOut];
}

- (void)setPanToDismissEnabled:(BOOL)panToDismissEnabled
{
    _panToDismissEnabled = panToDismissEnabled;
    self.dismissGestureController.gestureRecognizer.enabled = _panToDismissEnabled;
    
    self.panToDismissLabel.alpha = self.panToDismissEnabled ? 1.0f : 0.0f;
    if (self.panToDismissEnabled && self.superview != nil)
    {
        [UIView animateWithDuration:kAnimationDuration animations:^
        {
            self.panToDismissLabel.alpha = 0.0f;
        }];
    }
}

// *****************************************************************************************************
#pragma mark -
#pragma mark - Private Implementation
// *****************************************************************************************************

- (NSArray*)disableGestureRecognizersInView:(UIView *)view
{
    NSMutableArray *disabledRecognizers = [NSMutableArray arrayWithCapacity:view.gestureRecognizers.count];
    for (UIGestureRecognizer *gesture in view.gestureRecognizers)
    {
        if (gesture.enabled)
        {
            gesture.enabled = NO;
            [disabledRecognizers addObject:gesture];
        }
    }
    
    return disabledRecognizers;
}

// *****************************************************************************************************
#pragma mark - UI Events
// *****************************************************************************************************

- (void)adjustContentOffsetForFirstResponder
{
    if ([self.previousFirstResponder isFirstResponder])
    {
        const CGFloat inset = 10.0;
        CGRect responderFrame = [self convertRect:self.previousFirstResponder.frame fromView:self.previousFirstResponder.superview];
        responderFrame.origin.y += inset;
        if (CGRectGetMaxY(responderFrame) > CGRectGetMinY(self.keyboardIntersectionFrame))
        {
            [UIView animateWithDuration:0.3 animations:^
            {
                [self.popupContainerView setContentOffset:CGPointMake(0.0, self.popupContainerView.contentSize.height - CGRectGetMaxY(responderFrame))];
            }];
        }
    }
}

- (void)keyboardFrameChanged:(NSNotification *)notification
{
    NSDictionary* userInfo = [notification userInfo];
    
    // Get animation info from userInfo
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    // Animate up or down
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    CGRect frame = self.frame;
    CGRect keyboardFrame = [self convertRect:keyboardEndFrame toView:self];
    CGRect intersectionFrame = CGRectIntersection(frame, keyboardFrame);
    
    self.popupContainerView.contentInset = UIEdgeInsetsMake(0.0, 0.0, intersectionFrame.size.height + self.keyboardPadding, 0.0);
    self.popupContainerView.scrollIndicatorInsets = self.popupContainerView.contentInset;
    
    [UIView commitAnimations];
    
    self.keyboardIntersectionFrame = intersectionFrame;
    self.keyboardIsUp = intersectionFrame.size.height > 0.0;
    self.dismissGestureController.gestureRecognizer.enabled = (self.panToDismissEnabled && !self.keyboardIsUp);
    
    if (self.keyboardIsUp && self.previousFirstResponder != nil)
    {
        [self adjustContentOffsetForFirstResponder];
    }
}

- (void)firstResponderDidChange:(NSNotification *)notification
{
    id firstResponder = notification.object;
    if ([firstResponder isKindOfClass:[UIView class]])
    {
        self.previousFirstResponder = notification.object;
        if (self.keyboardIsUp)
        {
            [self adjustContentOffsetForFirstResponder];
        }
    }
}

- (void)backgroundTap:(UITapGestureRecognizer *)gesture
{
    if (self.backgroundTapBlock != nil)
    {
        self.backgroundTapBlock();
    }
}

// *****************************************************************************************************
#pragma mark - Default Animations
// *****************************************************************************************************

- (void)animateBackgroundIn
{
    self.backgroundView.alpha = 0.0f;
    [UIView animateWithDuration:kAnimationDuration
    animations:^
    {
        self.backgroundView.alpha = 1.0f;
    }];
}

- (void)animateBackgroundOut
{
    [self animateBackgroundOut:kAnimationDuration];
}

- (void)animateBackgroundOut:(CGFloat)duration
{
    [UIView animateWithDuration:duration
    delay:0.0f
    options:UIViewAnimationOptionBeginFromCurrentState
    animations:^
    {
        self.backgroundView.alpha = 0.0f;
    }
    completion:^(BOOL finished)
    {
        [self finishDismiss];
    }];
}

- (void)animatePopupIn
{
    self.popupView.transform = CGAffineTransformMakeScale(1.3f, 1.3f);
    self.popupView.alpha = 0.0f;
    [UIView animateWithDuration:kAnimationDuration animations:^
    {
        self.popupView.transform = CGAffineTransformIdentity;
        self.popupView.alpha = 1.0f;
    }
    completion:^(BOOL finished)
    {
        [UIView animateWithDuration:1.0f animations:^
        {
            self.panToDismissLabel.alpha = 0.0f;
        }];
    }];
}

- (void)animatePopupOut
{
    [UIView animateWithDuration:kAnimationDuration
    delay:0.0f
    options:UIViewAnimationOptionBeginFromCurrentState
    animations:^
    {
        self.popupView.alpha = 0.0f;
    }
    completion:nil];
}

- (void)finishDismiss
{
    for (UIGestureRecognizer *gesture in self.disabledGestureRecognizers)
    {
        gesture.enabled = YES;
    }
    self.disabledGestureRecognizers = nil;
    
    [self removeFromSuperview];
    
    if (self.dismissBlock != nil)
    {
        self.dismissBlock();
    }
}

// *****************************************************************************************************
#pragma mark - Dismiss Gesture
// *****************************************************************************************************

- (void)dynamicPanDidStart:(MCPDynamicDismissPanController *)panController
{
    [UIView animateWithDuration:kAnimationDuration animations:^
    {
        self.panToDismissLabel.alpha = 1.0f;
    }];
}

- (void)dynamicPanDidUpdate:(MCPDynamicDismissPanController *)panController
{
    CGFloat dy = self.popupView.center.y - self.backgroundView.center.y;
    CGFloat alpha = 1.0f;
    if (dy > 0)
    {
        alpha = 1.0f - 2.0f * dy / self.bounds.size.height;
    }
    self.backgroundView.alpha = alpha;
}

- (void)dynamicPanWillSnapToOriginalLocation:(MCPDynamicDismissPanController *)panController
{
    [UIView animateWithDuration:kMCDynamicPanSnapAnimationDuration animations:^
    {
        self.backgroundView.alpha = 1.0f;
        self.panToDismissLabel.alpha = 0.0f;
    }];
}

- (void)dynamicPanWillEnd:(MCPDynamicDismissPanController *)panController withAnimationDuration:(CGFloat)duration
{
    [self animateBackgroundOut:duration];
}

- (void)dynamicPanDidEnd:(MCPDynamicDismissPanController *)panController
{
    [self finishDismiss];
}

@end
