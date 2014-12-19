//
//  BLMobileBindViewController.m
//  BeiAngAir
//
//  Created by zhangbin on 12/10/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BLMobileBindViewController.h"

@interface BLMobileBindViewController ()

@property (readwrite) UITextField *mobileTextField;
@property (readwrite) UITextField *codeTextField;
@property (readwrite) UIButton *getCodeButton;
@property (readwrite) UIButton *bindButton;

@end

@implementation BLMobileBindViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
	scrollView.backgroundColor = [UIColor themeBlue];
	
	CGRect viewFrame = CGRectZero;
	UIImage *image = [UIImage imageNamed:@"home_logo"];
	viewFrame.origin.y = 20;
	viewFrame.origin.x = (self.view.frame.size.width - image.size.width) / 2;
	viewFrame.size = image.size;
	UIImageView *logoImageView = [[UIImageView alloc] initWithFrame:viewFrame];
	[logoImageView setImage:image];
	[scrollView addSubview:logoImageView];
	
	UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 15, 5, 15);
	CGRect frame = CGRectZero;
	frame.origin.x = edgeInsets.left;
	frame.origin.y = 150;
	frame.size.width = self.view.frame.size.width - edgeInsets.left - edgeInsets.right;
	frame.size.height = 30;
	_mobileTextField = [[UITextField alloc] initWithFrame:frame];
	_mobileTextField.placeholder = @"请输入手机号";
	_mobileTextField.keyboardType = UIKeyboardTypeNumberPad;
	[scrollView addSubview:_mobileTextField];
	
	frame.origin.y = CGRectGetMaxY(_mobileTextField.frame) + edgeInsets.bottom;
	_codeTextField = [[UITextField alloc] initWithFrame:frame];
	_codeTextField.placeholder = @"请输入验证码";
	_codeTextField.keyboardType = UIKeyboardTypeNumberPad;
	[scrollView addSubview:_codeTextField];
	
	frame.size.width = CGRectGetWidth(_codeTextField.frame) / 3;
	frame.origin.x = CGRectGetMaxX(_codeTextField.frame) - frame.size.width;
	_getCodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_getCodeButton.frame = frame;
	[_getCodeButton setTitle:@"获取验证码" forState:UIControlStateNormal];
	[_getCodeButton addTarget:self action:@selector(getCode) forControlEvents:UIControlEventTouchUpInside];
	[scrollView addSubview:_getCodeButton];
	
	frame.origin.x = CGRectGetMinX(_codeTextField.frame);
	frame.origin.y = CGRectGetMaxY(_codeTextField.frame) + edgeInsets.bottom;
	frame.size.width = CGRectGetWidth(_codeTextField.frame);
	_bindButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_bindButton.frame = frame;
	[_bindButton setTitle:@"绑定" forState:UIControlStateNormal];
	[_bindButton addTarget:self action:@selector(bind) forControlEvents:UIControlEventTouchUpInside];
	[scrollView addSubview:_bindButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)getCode {
	if (!_mobileTextField.text.length) {
		[self displayHUDTitle:nil message:@"手机号码不能为空"];
		return;
	}
}

- (void)bind {
	if (!_codeTextField.text.length) {
		[self displayHUDTitle:nil message:@"验证码不能为空"];
		return;
	}
	
	if (!_mobileTextField.text.length) {
		[self displayHUDTitle:nil message:@"手机号码不能为空"];
		return;
	}
	
	
}

@end
