//
//  MCPDynamicDismissPanController.h
//  Popup Demo
//
//  Created by Rayman Rosevear on 2015/08/07.
//  Copyright (c) 2015 Mushroom Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

extern CGFloat const kMCDynamicPanSnapAnimationDuration;

@protocol MCPDynamicDismissPanDelegate;

/**
 *	Sets up and coordinates a pan gesture for dismissing a view.
 *	On iOS >= 7, a dynamic animator is set up to add some dynamics
 *	to the interaction.
 *	On iOS 6, the view will just be panned vertically
 */
@interface MCPDynamicDismissPanController : NSObject

@property (nonatomic, strong, readonly) UIPanGestureRecognizer * gestureRecognizer;
@property (nonatomic, readonly) BOOL isActive; // YES after the gesture begins, but before it has ended

@property (nonatomic, weak) id<MCPDynamicDismissPanDelegate> delegate;

/**
 *	The gesture recognizer is set up for the given `view`. If you need
 *	the gesture recognizer to act on the container view of the view
 *	being dismissed, pass in the view's super view as containerView.
 *	This is useful if the frame of the view being dismissed is governed
 *	by autolayout.
 *
 *	NB:
 *	The view must already have been added to the view hierarchy at this point.
 */
- (instancetype)initForView:(UIView *)view inContainer:(UIView *)containerView NS_DESIGNATED_INITIALIZER;

@end

@protocol MCPDynamicDismissPanDelegate <NSObject>

- (void)dynamicPanDidStart:(MCPDynamicDismissPanController *)panController;
- (void)dynamicPanDidUpdate:(MCPDynamicDismissPanController *)panController;
- (void)dynamicPanWillSnapToOriginalLocation:(MCPDynamicDismissPanController *)panController;
/**
 *	Called when the view will be dismissed, and only in compatibility mode (iOS < 7.0), since
 *	the -dynamicPanDidUpdate: method is not called in compatibility mode during the
 *	dismiss animation
 */
- (void)dynamicPanWillEnd:(MCPDynamicDismissPanController *)panController withAnimationDuration:(CGFloat)duration;
/**
 *	Called when the view has been dismissed
 */
- (void)dynamicPanDidEnd:(MCPDynamicDismissPanController *)panController;

@end
