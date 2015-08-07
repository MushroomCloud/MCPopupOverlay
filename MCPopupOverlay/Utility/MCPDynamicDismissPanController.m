//
//  MCPDynamicDismissPanController.m
//  Popup Demo
//
//  Created by Rayman Rosevear on 2015/08/07.
//  Copyright (c) 2015 Mushroom Cloud. All rights reserved.
//

#import "MCPDynamicDismissPanController.h"

CGFloat const kMCDynamicPanSnapAnimationDuration = 0.6f;

@interface MCPDynamicDismissPanController ()

@property (nonatomic, strong, readwrite) UIView *                 viewToDismiss;
@property (nonatomic, strong, readwrite) UIPanGestureRecognizer * gestureRecognizer;
@property (nonatomic, strong, readwrite) UIDynamicAnimator *      dynamicAnimator;

@property (nonatomic, assign, readwrite) BOOL isActive;

@property (nonatomic, assign) CGPoint                startCenter;
@property (nonatomic, assign) CFAbsoluteTime         lastTimestamp;
@property (nonatomic, assign) CGFloat                lastAngle;
@property (nonatomic, assign) CGFloat                angularVelocity;
@property (nonatomic, strong) UIAttachmentBehavior * attachment;

- (void)setupGestureRecognizerInView:(UIView *)view;

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture;
- (void)handleCompatibilityPan:(UIPanGestureRecognizer *)gesture;

@end

@implementation MCPDynamicDismissPanController

- (instancetype)initForView:(UIView *)view inContainer:(UIView *)containerView
{
    if (self = [super init])
    {
        _viewToDismiss = containerView ?: view;
        [self setupGestureRecognizerInView:view];
    }
    return self;
}

- (void)setupGestureRecognizerInView:(UIView *)view
{
    Class dynamicAnimatorClass = NSClassFromString(@"UIDynamicAnimator");
    SEL panHandler = @selector(handleCompatibilityPan:);
    if (dynamicAnimatorClass != Nil)
    {
        self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.viewToDismiss.superview];
        panHandler = @selector(handlePanGesture:);
    }
    
    self.gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:panHandler];
    [view addGestureRecognizer:self.gestureRecognizer];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gesture
{
    typeof(self) __weak weakself = self;
    
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.isActive = YES;
            
            [self.dynamicAnimator removeAllBehaviors];
            self.startCenter = self.viewToDismiss.center;
            
            // Calculate the center offset and anchor point
            CGPoint pointWithinAnimatedView = [gesture locationInView:self.viewToDismiss];
            UIOffset offset = UIOffsetMake((pointWithinAnimatedView.x - self.viewToDismiss.bounds.size.width / 2.0) * 0.38f,
                                           (pointWithinAnimatedView.y - self.viewToDismiss.bounds.size.height / 2.0) * 0.38f);
            pointWithinAnimatedView = CGPointMake(self.viewToDismiss.bounds.size.width / 2.0f + offset.horizontal,
                                                  self.viewToDismiss.bounds.size.height / 2.0f + offset.vertical);
            
            CGPoint anchor = [self.viewToDismiss.superview convertPoint:pointWithinAnimatedView fromView:self.viewToDismiss];
            self.attachment = [[UIAttachmentBehavior alloc] initWithItem:self.viewToDismiss
                                                        offsetFromCenter:offset
                                                        attachedToAnchor:anchor];
            
            self.lastTimestamp = CFAbsoluteTimeGetCurrent();
            self.lastAngle = [self angleOfView:self.viewToDismiss];
            
            self.attachment.action = ^
            {
                typeof(weakself) __strong strongself = weakself;
                CFAbsoluteTime time = CFAbsoluteTimeGetCurrent();
                CGFloat angle = [strongself angleOfView:strongself.viewToDismiss];
                if (time > strongself.lastTimestamp)
                {
                    strongself.angularVelocity = (angle - strongself.lastAngle) / (time - strongself.lastTimestamp);
                    strongself.lastTimestamp = time;
                    strongself.lastAngle = angle;
                }
            };
            
            [self.dynamicAnimator addBehavior:self.attachment];
            [self.delegate dynamicPanDidStart:self];
            
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [gesture translationInView:self.viewToDismiss.superview];
            
            self.attachment.anchorPoint = CGPointMake(self.attachment.anchorPoint.x, self.startCenter.y + translation.y);
            [self.delegate dynamicPanDidUpdate:self];
            
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        {
            [self.dynamicAnimator removeAllBehaviors];
            self.attachment = nil;
            
            CGPoint velocity = [gesture velocityInView:self.viewToDismiss.superview];
            
            if (fabs(atan2(velocity.y, velocity.x) - M_PI_2) > M_PI_4)
            {
                // If we aren't dragging it down, just snap it back
                [self.delegate dynamicPanWillSnapToOriginalLocation:self];
                [UIView animateWithDuration:kMCDynamicPanSnapAnimationDuration
                delay:0.0f
                usingSpringWithDamping:0.6f
                initialSpringVelocity:0.5f
                options:0
                animations:^
                {
                    self.viewToDismiss.transform = CGAffineTransformIdentity;
                    self.viewToDismiss.center = self.startCenter;
                }
                completion:^(BOOL finished)
                {
                    self.isActive = NO;
                }];
            }
            else
            {
                velocity.x = 0.0f;
                
                // Otherwise, create UIDynamicItemBehavior that carries on animation from where the gesture left off (notably linear and angular velocity)
                UIDynamicItemBehavior *dynamic = [[UIDynamicItemBehavior alloc] initWithItems:@[ self.viewToDismiss ]];
                [dynamic addLinearVelocity:velocity forItem:self.viewToDismiss];
                [dynamic addAngularVelocity:self.angularVelocity forItem:self.viewToDismiss];
                [dynamic setAngularResistance:2];
                
                // When the view no longer intersects with its superview, go ahead and remove it
                dynamic.action = ^
                {
                    typeof(weakself) __strong strongself = weakself;
                    if (CGRectIntersectsRect(strongself.viewToDismiss.superview.bounds, strongself.viewToDismiss.frame))
                    {
                        [strongself.delegate dynamicPanDidUpdate:strongself];
                    }
                    else
                    {
                        [strongself.dynamicAnimator removeAllBehaviors];
                        [strongself.delegate dynamicPanDidEnd:strongself];
                        strongself.isActive = NO;
                    }
                };
                [self.dynamicAnimator addBehavior:dynamic];
                
                // Add a little gravity so it accelerates off the screen (in case user gesture was slow)
                UIGravityBehavior *gravity = [[UIGravityBehavior alloc] initWithItems:@[ self.viewToDismiss ]];
                [self.dynamicAnimator addBehavior:gravity];
            }
            break;
        }
        default:
            break;
    }
}

- (CGFloat)angleOfView:(UIView *)view
{
    // http://stackoverflow.com/a/2051861/1271826
    return atan2(view.transform.b, view.transform.a);
}

- (void)handleCompatibilityPan:(UIPanGestureRecognizer *)gesture
{
    typeof(self) __weak weakself = self;
    
    switch (gesture.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            self.isActive = YES;
            self.startCenter = self.viewToDismiss.center;
            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint translation = [gesture translationInView:self.viewToDismiss.superview];
            
            self.viewToDismiss.center = CGPointMake(self.viewToDismiss.center.x, self.startCenter.y + translation.y);
            [self.delegate dynamicPanDidUpdate:self];
            
            break;
        }
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
        {
            CGPoint velocity = [gesture velocityInView:self.viewToDismiss.superview];
            
            if (velocity.y <= 0)
            {
                // If we aren't dragging it down, just snap it back
                [self.delegate dynamicPanWillSnapToOriginalLocation:self];
                [UIView animateWithDuration:0.3
                animations:^
                {
                    self.viewToDismiss.transform = CGAffineTransformIdentity;
                    self.viewToDismiss.center = self.startCenter;
                }
                completion:^(BOOL finished)
                {
                    self.isActive = NO;
                }];
            }
            else
            {
                CGPoint destinationCenter = CGPointMake(self.startCenter.x,
                                                        self.viewToDismiss.superview.bounds.size.height + self.viewToDismiss.bounds.size.height / 2.0f);
                const CGFloat dy = destinationCenter.y - self.viewToDismiss.center.y;
                const CGFloat t = MIN(dy / velocity.y, 0.3f);
                
                [self.delegate dynamicPanWillEnd:self withAnimationDuration:t];
                
                [UIView animateWithDuration:t
                delay:0.0f
                options:UIViewAnimationOptionCurveLinear
                animations:^
                {
                    self.viewToDismiss.center = destinationCenter;
                }
                completion:^(BOOL finished)
                {
                    typeof(weakself) __strong strongself = weakself;
                    [strongself.delegate dynamicPanDidEnd:strongself];
                    strongself.isActive = NO;
                }];
            }
            break;
        }
        default:
            break;
    }
}

@end
