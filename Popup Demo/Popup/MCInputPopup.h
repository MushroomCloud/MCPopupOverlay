//
//  MCInputPopup.h
//  Popup Demo
//
//  Created by Rayman Rosevear on 2015/08/07.
//  Copyright (c) 2015 Mushroom Cloud. All rights reserved.
//

#import <MCPopupOverlay/MCPopupOverlay.h>

@interface MCInputPopup : MCPopupOverlayView

@property (nonatomic, readonly) UILabel * titleLabel;
@property (nonatomic, readonly) UITextView * textView;

// Defaults to YES
@property (nonatomic, assign) BOOL dismissOnDestructiveAction;

@property (nonatomic, copy) void (^affirmativeButtonAction)(MCInputPopup *popup);
@property (nonatomic, copy) void (^desctructiveButtonAction)(MCInputPopup *popup);

+ (instancetype)popupWithTitle:(NSString *)title initialText:(NSString *)initialText;
- (instancetype)initWithTitle:(NSString *)title initialText:(NSString *)initialText;

- (NSString *)inputText;

@end
