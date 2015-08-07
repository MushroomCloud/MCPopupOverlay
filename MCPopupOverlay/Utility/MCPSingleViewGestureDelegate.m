//
//  MCPSingleViewGestureDelegate.m
//  Popup Demo
//
//  Created by Rayman Rosevear on 2015/08/07.
//  Copyright (c) 2015 Mushroom Cloud. All rights reserved.
//

#import "MCPSingleViewGestureDelegate.h"

@implementation MCPSingleViewGestureDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return touch.view == self.view;
}

@end
