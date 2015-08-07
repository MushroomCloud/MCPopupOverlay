//
//  UIResponder+MCPFirstResponderNotifications.m
//  Popup Demo
//
//  Created by Rayman Rosevear on 2015/08/07.
//  Copyright (c) 2015 Mushroom Cloud. All rights reserved.
//

#import <JRSwizzle/JRSwizzle.h>
#import "UIResponder+MCPFirstResponderNotifications.h"

NSString * const kMCPUIResponderDidBecomFirstResponderNotification = @"kMCUIResponderDidBecomFirstResponderNotification";
NSString * const kMCPUIResponderDidResignFirstResponderNotification = @"kMCUIResponderDidResignFirstResponderNotification";

@interface UIResponder (MCPFirstResponderNotifications_Private)

- (BOOL)mcp_override_becomeFirstResponder;
- (BOOL)mcp_override_resignFirstResponder;

@end

@implementation UIResponder (MCPFirstResponderNotifications)

+ (void)ensureResponderNotificationsInitialized
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        NSError *error = nil;
        if ([UIResponder jr_swizzleMethod:@selector(becomeFirstResponder)
                               withMethod:@selector(mcp_override_becomeFirstResponder)
                                    error:&error])
        {
            [UIResponder jr_swizzleMethod:@selector(resignFirstResponder)
                               withMethod:@selector(mcp_override_resignFirstResponder)
                                    error:&error];
        }
        
        if (error != nil)
        {
            NSLog(@"Warning: an error occurred trying to swizzle UIResponder: %@", error);
        }
    });
}

@end

@implementation UIResponder (MCPFirstResponderNotifications_Private)

- (BOOL)mcp_override_becomeFirstResponder
{
    // invoke the original implementation
    BOOL result = [self mcp_override_becomeFirstResponder];
    if (result)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMCPUIResponderDidBecomFirstResponderNotification object:self];
    }
    return result;
}

- (BOOL)mcp_override_resignFirstResponder
{
    // invoke the original implementation
    BOOL result = [self mcp_override_resignFirstResponder];
    if (result)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kMCPUIResponderDidResignFirstResponderNotification object:self];
    }
    return result;
}

@end
