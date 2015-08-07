//
//  ViewController.m
//  Popup Demo
//
//  Created by Rayman Rosevear on 2015/08/07.
//  Copyright (c) 2015 Mushroom Cloud. All rights reserved.
//

#import "ViewController.h"
#import "MCInputPopup.h"

@interface ViewController ()

@end

@implementation ViewController

- (IBAction)showPopup
{
    MCInputPopup *popup = [MCInputPopup popupWithTitle:@"Input Popup" initialText:nil];
    [popup setAffirmativeButtonAction:^(MCInputPopup *popup)
    {
        [popup dismiss];
        NSLog(@"Dismissed with text: %@", popup.textView.text);
    }];
    
    [popup showInView:self.view];
}

@end
