//
//  SIAlertView.m
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "SIAlertView.h"
#import "UIWindow+SIUtils.h"
#import <QuartzCore/QuartzCore.h>

#define DEBUG_LAYOUT 0

#define GAP 10
#define CANCEL_BUTTON_PADDING_TOP 10
#define CONTENT_PADDING_LEFT 20
#define CONTENT_PADDING_TOP 22
#define CONTENT_PADDING_BOTTOM 22
#define BUTTON_HEIGHT 44

@interface SIAlertView ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;

@property (nonatomic, strong) NSMutableArray *items;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) NSMutableArray *buttons;

@property (nonatomic, assign) BOOL subviewsCreated;

@end

#pragma mark - SIAlertItem

@interface SIAlertItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) SIAlertViewButtonType type;
@property (nonatomic, copy) SIAlertViewHandler action;

@end

@implementation SIAlertItem

@end

#pragma mark - SIAlert

@implementation SIAlertView

+ (void)initialize
{
    if (self != [SIAlertView class])
        return;
    
    SIAlertView *appearance = [self appearance];
    appearance.viewBackgroundColor = [UIColor whiteColor];
    appearance.titleColor = [UIColor blackColor];
    appearance.messageColor = [UIColor darkGrayColor];
    appearance.titleFont = [UIFont boldSystemFontOfSize:20];
    appearance.messageFont = [UIFont systemFontOfSize:16];
    appearance.buttonFont = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
    appearance.buttonColor = [UIColor colorWithWhite:0.4 alpha:1];
    appearance.cancelButtonColor = [UIColor colorWithWhite:0.3 alpha:1];
    appearance.destructiveButtonColor = [UIColor whiteColor];
    appearance.cornerRadius = 2;
    appearance.shadowRadius = 8;
    appearance.containerWidth = 300;
}

- (id)init
{
	return [self initWithTitle:@"" andMessage:@""];
}

- (id)initWithTitle:(NSString *)title andMessage:(NSString *)message
{
	self = [super init];
	if (self) {
		_title = title;
        _message = message;
		self.items = [[NSMutableArray alloc] init];
        
        self.titleFont = [SIAlertView appearance].titleFont;
        self.messageFont = [SIAlertView appearance].messageFont;
        self.buttonFont = [SIAlertView appearance].buttonFont;
        self.containerWidth = [SIAlertView appearance].containerWidth;
        
        self.backgroundColor = _viewBackgroundColor ? _viewBackgroundColor : [UIColor whiteColor];
        self.layer.cornerRadius = self.cornerRadius;
        self.layer.shadowOffset = CGSizeZero;
        self.layer.shadowRadius = self.shadowRadius;
        self.layer.shadowOpacity = 0.5;
	}
	return self;
}


#pragma mark - Setters

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.subviewsCreated = NO;
	[self setNeedsLayout];
}

- (void)setMessage:(NSString *)message
{
	_message = message;
    self.subviewsCreated = NO;
    [self setNeedsLayout];
}

#pragma mark - Public

- (void)addButtonWithTitle:(NSString *)title type:(SIAlertViewButtonType)type handler:(SIAlertViewHandler)handler
{
    SIAlertItem *item = [[SIAlertItem alloc] init];
	item.title = title;
	item.type = type;
	item.action = handler;
	[self.items addObject:item];
    self.subviewsCreated = NO;
    [self setNeedsLayout];
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self createSubviewsIfNeeded];

    self.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius].CGPath;
    
    CGFloat y = CONTENT_PADDING_TOP;
	if (self.titleLabel && [self.title length] > 0) {
        self.titleLabel.text = self.title;
        CGFloat titleHeight = [self heightForTitleLabelForWidth:self.bounds.size.width];
        self.titleLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.bounds.size.width - CONTENT_PADDING_LEFT * 2, titleHeight);
        y += titleHeight+GAP;
	}
    if (self.messageLabel && [self.message length] > 0) {
        self.messageLabel.text = self.message;
        CGFloat messageHeight = [self heightForMessageLabelForWidth:self.bounds.size.width];
        self.messageLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.bounds.size.width - CONTENT_PADDING_LEFT * 2, messageHeight);
        y += messageHeight+GAP;
    }
    if (self.items.count > 0) {
            y += GAP;
        if (self.items.count == 2 && self.buttonsListStyle == SIAlertViewButtonsListStyleNormal) {
            CGFloat width = (self.bounds.size.width - CONTENT_PADDING_LEFT * 2 - GAP) * 0.5;
            if(self.buttons.count > 0){
                UIButton *button = self.buttons[0];
                button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, width, BUTTON_HEIGHT);
                if(self.buttons.count > 1){
                    button = self.buttons[1];
                    button.frame = CGRectMake(CONTENT_PADDING_LEFT + width + GAP, y, width, BUTTON_HEIGHT);
                }
            }
        } else {
            for (NSUInteger i = 0; i < self.buttons.count; i++) {
                UIButton *button = self.buttons[i];
                button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.bounds.size.width - CONTENT_PADDING_LEFT * 2, BUTTON_HEIGHT);
                if (self.buttons.count > 1) {
                    if (i == self.buttons.count - 1 && ((SIAlertItem *)self.items[i]).type == SIAlertViewButtonTypeCancel) {
                        CGRect rect = button.frame;
                        rect.origin.y += CANCEL_BUTTON_PADDING_TOP;
                        button.frame = rect;
                    }
                    y += BUTTON_HEIGHT + GAP;
                }
            }
        }
    }
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width
{
    [self createSubviewsIfNeeded];
    
	CGFloat height = CONTENT_PADDING_TOP;
	if (self.title && [self.title length] > 0) {
		height += [self heightForTitleLabelForWidth:width]+GAP;
	}
    if (self.message && [self.message length] > 0) {
        height += [self heightForMessageLabelForWidth:width]+GAP;
    }
    if (self.items.count > 0) {
            height += GAP;
        if (self.items.count <= 2 && self.buttonsListStyle == SIAlertViewButtonsListStyleNormal) {
            height += BUTTON_HEIGHT;
        } else {
            height += (BUTTON_HEIGHT + GAP) * self.items.count - GAP;
            if (self.buttons.count > 2 && ((SIAlertItem *)[self.items lastObject]).type == SIAlertViewButtonTypeCancel) {
                height += CANCEL_BUTTON_PADDING_TOP;
            }
        }
    }
    height += CONTENT_PADDING_BOTTOM;
	return height;
}

- (CGFloat)heightForTitleLabelForWidth:(CGFloat)width
{
    if (self.titleLabel) {
        self.titleLabel.text = self.title;
        self.titleLabel.font = self.titleFont;
        CGRect rect = [self.titleLabel textRectForBounds:CGRectMake(0, 0, width - CONTENT_PADDING_LEFT * 2, MAXFLOAT) limitedToNumberOfLines:0];
        return rect.size.height;
    }
    return 0;
}

- (CGFloat)heightForMessageLabelForWidth:(CGFloat)width
{
    if (self.messageLabel) {
        self.messageLabel.text = self.message;
        self.messageLabel.font = self.messageFont;
        CGRect rect = [self.messageLabel textRectForBounds:CGRectMake(0, 0, width - CONTENT_PADDING_LEFT * 2, MAXFLOAT) limitedToNumberOfLines:0];
        return rect.size.height;
    }
    return 0;
}

#pragma mark - Setup

- (void)createSubviewsIfNeeded{
    if(!self.subviewsCreated){
        [self updateTitleLabel];
        [self updateMessageLabel];
        [self setupButtons];
        self.subviewsCreated = YES;
    }
}

- (void)updateTitleLabel
{
	if (self.title) {
		if (!self.titleLabel) {
			self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
			self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.backgroundColor = [UIColor clearColor];
			self.titleLabel.font = self.titleFont;
            self.titleLabel.textColor = self.titleColor;
            self.titleLabel.numberOfLines = 0;
			[self addSubview:self.titleLabel];
#if DEBUG_LAYOUT
            self.titleLabel.backgroundColor = [UIColor redColor];
#endif
		}
		self.titleLabel.text = self.title;
	} else {
		[self.titleLabel removeFromSuperview];
		self.titleLabel = nil;
	}
}

- (void)updateMessageLabel
{
    if (self.message) {
        if (!self.messageLabel) {
            self.messageLabel = [[UILabel alloc] initWithFrame:self.bounds];
            self.messageLabel.textAlignment = NSTextAlignmentCenter;
            self.messageLabel.backgroundColor = [UIColor clearColor];
            self.messageLabel.font = self.messageFont;
            self.messageLabel.textColor = self.messageColor;
            self.messageLabel.numberOfLines = 0;
            [self addSubview:self.messageLabel];
#if DEBUG_LAYOUT
            self.messageLabel.backgroundColor = [UIColor redColor];
#endif
        }
        self.messageLabel.text = self.message;
    } else {
        [self.messageLabel removeFromSuperview];
        self.messageLabel = nil;
    }
}

- (void)setupButtons
{
    self.buttons = [[NSMutableArray alloc] initWithCapacity:self.items.count];
    for (NSUInteger i = 0; i < self.items.count; i++) {
        UIButton *button = [self buttonForItemIndex:i];
        [self.buttons addObject:button];
        [self addSubview:button];
    }
}

- (UIButton *)buttonForItemIndex:(NSUInteger)index
{
    SIAlertItem *item = self.items[index];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.tag = index;
	button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.titleLabel.font = self.buttonFont;
	[button setTitle:item.title forState:UIControlStateNormal];
	UIImage *normalImage = nil;
	UIImage *highlightedImage = nil;
	switch (item.type) {
		case SIAlertViewButtonTypeCancel:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-default"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-default-d"];
			[button setTitleColor:self.cancelButtonColor forState:UIControlStateNormal];
            [button setTitleColor:[self.cancelButtonColor colorWithAlphaComponent:0.8] forState:UIControlStateHighlighted];
			break;
		case SIAlertViewButtonTypeDestructive:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-destructive"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-destructive-d"];
            [button setTitleColor:self.destructiveButtonColor forState:UIControlStateNormal];
            [button setTitleColor:[self.destructiveButtonColor colorWithAlphaComponent:0.8] forState:UIControlStateHighlighted];
			break;
		case SIAlertViewButtonTypeDefault:
		default:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-default"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-default-d"];
			[button setTitleColor:self.buttonColor forState:UIControlStateNormal];
            [button setTitleColor:[self.buttonColor colorWithAlphaComponent:0.8] forState:UIControlStateHighlighted];
			break;
	}
	CGFloat hInset = floorf(normalImage.size.width / 2);
	CGFloat vInset = floorf(normalImage.size.height / 2);
	UIEdgeInsets insets = UIEdgeInsetsMake(vInset, hInset, vInset, hInset);
	normalImage = [normalImage resizableImageWithCapInsets:insets];
	highlightedImage = [highlightedImage resizableImageWithCapInsets:insets];
	[button setBackgroundImage:normalImage forState:UIControlStateNormal];
	[button setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
	[button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

#pragma mark - Actions

- (void)buttonAction:(UIButton *)button
{
    SIAlertItem *item = self.items[button.tag];
	if (item.action) {
		item.action(self);
	}
}

#pragma mark - UIAppearance setters

- (void)setViewBackgroundColor:(UIColor *)viewBackgroundColor
{
    if (_viewBackgroundColor == viewBackgroundColor) {
        return;
    }
    _viewBackgroundColor = viewBackgroundColor;
    self.backgroundColor = viewBackgroundColor;
}

- (void)setTitleFont:(UIFont *)titleFont
{
    if (_titleFont == titleFont) {
        return;
    }
    _titleFont = titleFont;
    self.titleLabel.font = titleFont;
    [self setNeedsLayout];
}

- (void)setMessageFont:(UIFont *)messageFont
{
    if (_messageFont == messageFont) {
        return;
    }
    _messageFont = messageFont;
    self.messageLabel.font = messageFont;
    [self setNeedsLayout];
}

- (void)setTitleColor:(UIColor *)titleColor
{
    if (_titleColor == titleColor) {
        return;
    }
    _titleColor = titleColor;
    self.titleLabel.textColor = titleColor;
}

- (void)setMessageColor:(UIColor *)messageColor
{
    if (_messageColor == messageColor) {
        return;
    }
    _messageColor = messageColor;
    self.messageLabel.textColor = messageColor;
}

- (void)setButtonFont:(UIFont *)buttonFont
{
    if (_buttonFont == buttonFont) {
        return;
    }
    _buttonFont = buttonFont;
    for (UIButton *button in self.buttons) {
        button.titleLabel.font = buttonFont;
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius == cornerRadius) {
        return;
    }
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = cornerRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
    if (_shadowRadius == shadowRadius) {
        return;
    }
    _shadowRadius = shadowRadius;
    self.layer.shadowRadius = shadowRadius;
}

- (void)setButtonColor:(UIColor *)buttonColor
{
    if (_buttonColor == buttonColor) {
        return;
    }
    _buttonColor = buttonColor;
    [self setColor:buttonColor toButtonsOfType:SIAlertViewButtonTypeDefault];
}

- (void)setCancelButtonColor:(UIColor *)buttonColor
{
    if (_cancelButtonColor == buttonColor) {
        return;
    }
    _cancelButtonColor = buttonColor;
    [self setColor:buttonColor toButtonsOfType:SIAlertViewButtonTypeCancel];
}

- (void)setDestructiveButtonColor:(UIColor *)buttonColor
{
    if (_destructiveButtonColor == buttonColor) {
        return;
    }
    _destructiveButtonColor = buttonColor;
    [self setColor:buttonColor toButtonsOfType:SIAlertViewButtonTypeDestructive];
}


- (void)setDefaultButtonImage:(UIImage *)defaultButtonImage forState:(UIControlState)state
{
    [self setButtonImage:defaultButtonImage forState:state andButtonType:SIAlertViewButtonTypeDefault];
}


- (void)setCancelButtonImage:(UIImage *)cancelButtonImage forState:(UIControlState)state
{
    [self setButtonImage:cancelButtonImage forState:state andButtonType:SIAlertViewButtonTypeCancel];
}


- (void)setDestructiveButtonImage:(UIImage *)destructiveButtonImage forState:(UIControlState)state
{
    [self setButtonImage:destructiveButtonImage forState:state andButtonType:SIAlertViewButtonTypeDestructive];
}


- (void)setButtonImage:(UIImage *)image forState:(UIControlState)state andButtonType:(SIAlertViewButtonType)type
{
    for (NSUInteger i = 0; i < self.items.count; i++)
    {
        SIAlertItem *item = self.items[i];
        if(item.type == type)
        {
            UIButton *button = self.buttons[i];
            [button setBackgroundImage:image forState:state];
        }
    }
}


-(void)setColor:(UIColor *)color toButtonsOfType:(SIAlertViewButtonType)type {
    for (NSUInteger i = 0; i < self.items.count; i++) {
        SIAlertItem *item = self.items[i];
        if(item.type == type) {
            UIButton *button = self.buttons[i];
            [button setTitleColor:color forState:UIControlStateNormal];
            [button setTitleColor:[color colorWithAlphaComponent:0.8] forState:UIControlStateHighlighted];
        }
    }
}

@end
