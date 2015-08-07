//
//  MCPopupOverlayView.h
//  Popup Demo
//
//  Created by Rayman Rosevear on 2015/08/07.
//  Copyright (c) 2015 Mushroom Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MCPopupOverlayView : UIView

@property (nonatomic, readonly) UIScrollView * popupContainerView;

@property (nonatomic, readonly) UIView *  backgroundView;
@property (nonatomic, readonly) UIView *  popupView;
@property (nonatomic, readonly) UILabel * panToDismissLabel;

@property (nonatomic, copy) dispatch_block_t backgroundTapBlock;
@property (nonatomic, copy) dispatch_block_t dismissBlock;

@property (nonatomic, assign) BOOL panToDismissEnabled;

/// The popup view is constrained to have these maximum insets from the superview.
@property (nonatomic, assign) CGSize popupViewMaxInsets;
/// The amoutn of space between the keyboard and popupView.
@property (nonatomic, assign) CGFloat keyboardPadding;

- (void)showInView:(UIView *)view;
- (void)dismiss;

/**
 *	These can be overridden by subclasses to alter behaviour or appearance.
 *	These methods should not be called directly.
 */
/**
 *	Override this method to return the preferred size of the
 *	popup view. The final size of the popup may be smaller,
 *	so keep this in mind when laying out the content.
 *	The default size is 290x200
 */
- (CGSize)preferredPopupSize;

/**
 *	Remember to remove self from its superview after animating
 *	out.
 */
- (void)animateBackgroundIn;
- (void)animateBackgroundOut;

- (void)animatePopupIn;
- (void)animatePopupOut;

@end
