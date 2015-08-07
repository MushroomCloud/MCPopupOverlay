//
//  UIResponder+MCPFirstResponderNotifications.h
//  Popup Demo
//
//  Created by Rayman Rosevear on 2015/08/07.
//  Copyright (c) 2015 Mushroom Cloud. All rights reserved.
//

#import <UIKit/UIKit.h>

// The object of the notification will be the responder. The user info dictionary is not used.
extern NSString * const kMCPUIResponderDidBecomFirstResponderNotification;
extern NSString * const kMCPUIResponderDidResignFirstResponderNotification;

@interface UIResponder (MCPFirstResponderNotifications)

// Call this method to ensure that the correct methods have been swizzled.
// It is safe to call this method multiple times
+ (void)ensureResponderNotificationsInitialized;

@end
