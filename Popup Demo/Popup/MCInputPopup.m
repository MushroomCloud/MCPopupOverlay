//
//  MCInputPopup.m
//  Popup Demo
//
//  Created by Rayman Rosevear on 2015/08/07.
//  Copyright (c) 2015 Mushroom Cloud. All rights reserved.
//

#import "MCInputPopup.h"

#define kPopupInset 20.0
#define kContentHInset 20.0
#define kContentVInset 15.0
#define kButtonHeight 35.0

@interface MCInputPopup ()

@property (nonatomic, readonly) UIVisualEffectView * backgroundBlurView;

@property (nonatomic, readonly) UIButton * confirmButton;
@property (nonatomic, readonly) UIButton * destructButton;

@property (nonatomic, readonly) UIView * buttonHSeparator;
@property (nonatomic, readonly) UIView * buttonVSeparator;

- (void)setupInputPopup;

- (void)confirmButtonTap;
- (void)destructButtonTap;

@end

@implementation MCInputPopup

+ (instancetype)popupWithTitle:(NSString *)title initialText:(NSString *)initialText
{
    return [[self alloc] initWithTitle:title initialText:initialText];
}

- (instancetype)initWithTitle:(NSString *)title initialText:(NSString *)initialText
{
    if (self = [super init])
    {
        _titleLabel.text = title;
        _textView.text = initialText;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        [self setupInputPopup];
    }
    return self;
}

- (void)setupInputPopup
{
    _dismissOnDestructiveAction = YES;
    
    UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
    
    UILabel *titleLabel = [UILabel new];
    UITextView *textView = [UITextView new];
    UIButton *confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIButton *destructButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIView *buttonHSeparator = [UIView new];
    UIView *buttonVSeparator = [UIView new];
    UIVisualEffectView *backgroundBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    self.popupView.layer.cornerRadius = 10.0;
    self.popupView.clipsToBounds = YES;
    self.popupView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    
    UIColor *lightGray = [UIColor colorWithWhite:0.75 alpha:0.9];
    
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [self boldFontForFont:titleLabel.font];
    
    textView.layer.cornerRadius = 5.0;
    textView.clipsToBounds = YES;
    
    confirmButton.backgroundColor = destructButton.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    
    [confirmButton setTitle:NSLocalizedString(@"OK", @"Default confirm button title for input popup") forState:UIControlStateNormal];
    [confirmButton setTitleColor:self.tintColor forState:UIControlStateNormal];
    [destructButton setTitle:NSLocalizedString(@"Cancel", @"Default destructive button title for input popup") forState:UIControlStateNormal];
    [destructButton setTitleColor:self.tintColor forState:UIControlStateNormal];
    
    [destructButton.titleLabel setFont:[self boldFontForFont:destructButton.titleLabel.font]];
    
    [confirmButton addTarget:self action:@selector(confirmButtonTap) forControlEvents:UIControlEventTouchUpInside];
    [destructButton addTarget:self action:@selector(destructButtonTap) forControlEvents:UIControlEventTouchUpInside];
    
    buttonHSeparator.backgroundColor = buttonVSeparator.backgroundColor = lightGray;
    
    [self.popupView addSubview:backgroundBlurView];
    [self.popupView addSubview:titleLabel];
    [self.popupView addSubview:textView];
    [self.popupView addSubview:confirmButton];
    [self.popupView addSubview:destructButton];
    [self.popupView addSubview:buttonHSeparator];
    [self.popupView addSubview:buttonVSeparator];
    
    _backgroundBlurView = backgroundBlurView;
    _titleLabel = titleLabel;
    _textView = textView;
    _confirmButton = confirmButton;
    _destructButton = destructButton;
    _buttonHSeparator = buttonHSeparator;
    _buttonVSeparator = buttonVSeparator;
    
    typeof(self) __weak weakself = self;
    self.backgroundTapBlock = ^
    {
        [weakself.textView endEditing:YES];
    };
}

- (CGSize)preferredPopupSize
{
    const CGFloat defaultWidth = 414;
    const CGFloat defaultHeight = 180.0;
    
    CGFloat maxWidth = CGRectGetWidth(self.superview.bounds) - kPopupInset * 2.0;
    CGFloat maxHeight = CGRectGetHeight(self.superview.bounds) - kPopupInset * 2.0;
    
    return CGSizeMake(MIN(maxWidth, defaultWidth), MIN(maxHeight, defaultHeight));
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    const CGFloat separatorThickness = 1.0 / [UIScreen mainScreen].scale;
    const CGFloat buttonY = CGRectGetHeight(self.popupView.bounds) - kButtonHeight;
    const CGFloat buttonWidth = CGRectGetWidth(self.popupView.bounds) / 2.0;
    
    self.backgroundBlurView.frame = self.popupView.bounds;
    
    [self.titleLabel sizeToFit];
    self.titleLabel.frame = ({
        CGRect frame = self.titleLabel.frame;
        frame.origin.x = kContentHInset;
        frame.origin.y = kContentVInset;
        frame.size.width = CGRectGetWidth(self.popupView.bounds) - 2.0 * kContentHInset;
        frame;
    });
    
    const CGFloat textViewY = CGRectGetMaxY(self.titleLabel.frame) + kContentVInset;
    
    self.destructButton.frame = CGRectMake(0.0, buttonY, buttonWidth, kButtonHeight);
    self.confirmButton.frame = CGRectMake(buttonWidth, buttonY, buttonWidth, kButtonHeight);
    
    self.textView.frame = CGRectMake(kContentHInset,
                                     textViewY,
                                     CGRectGetWidth(self.popupView.bounds) - 2.0 * kContentHInset,
                                     CGRectGetMinY(self.destructButton.frame) - (kContentVInset + textViewY));
        
    self.buttonHSeparator.frame = CGRectMake(0.0, buttonY, CGRectGetWidth(self.popupView.bounds), separatorThickness);
    self.buttonVSeparator.frame = CGRectMake(0.0, buttonY, separatorThickness, kButtonHeight);
    
    self.buttonVSeparator.center = CGPointMake(buttonWidth, self.buttonVSeparator.center.y);
}

- (void)confirmButtonTap
{
    if (self.affirmativeButtonAction != nil)
    {
        self.affirmativeButtonAction(self);
    }
}

- (void)destructButtonTap
{
    if (self.desctructiveButtonAction != nil)
    {
        self.desctructiveButtonAction(self);
    }
    if (self.dismissOnDestructiveAction)
    {
        [self dismiss];
    }
}

- (NSString *)inputText
{
    return self.textView.text;
}

- (void)tintColorDidChange
{
    [self.confirmButton setTitleColor:self.tintColor forState:UIControlStateNormal];
    [self.destructButton setTitleColor:self.tintColor forState:UIControlStateNormal];
}

- (UIFont *)boldFontForFont:(UIFont *)font
{
    UIFontDescriptor *boldDescriptor = [[font fontDescriptor] fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    return [UIFont fontWithDescriptor:boldDescriptor size:font.pointSize];
}

@end
