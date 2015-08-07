//
//  MCPSingleViewGestureDelegate.h
//  Popup Demo
//
//  Created by Rayman Rosevear on 2015/08/07.
//  Copyright (c) 2015 Mushroom Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 *  This is a UIGestureRecognizer delegate that restricts a gesture to be enabled in one single
 *  view only
 */
@interface MCPSingleViewGestureDelegate : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UIView *view;

@end
