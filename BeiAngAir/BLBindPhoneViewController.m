//
//  BLBindPhoneViewController.m
//  BeiAngAir
//
//  Created by zhangbin on 1/4/15.
//  Copyright (c) 2015 BroadLink. All rights reserved.
//

#import "BLBindPhoneViewController.h"
#import "BLAPIClient.h"

@interface BLBindPhoneViewController ()

@property (readwrite) UITextField *accountTextField;
@property (readwrite) UITextField *codeTextField;
@property (readwrite) UIButton *getCodeButton;
@property (readwrite) UIButton *submitButton;

@end

@implementation BLBindPhoneViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = NSLocalizedString(@"绑定手机", nil);
	self.view.backgroundColor = [UIColor themeBlue];
	self.navigationController.navigationBarHidden = NO;
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
	[self.view addGestureRecognizer:tap];
	
	UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 30, 10, 30);
	CGRect frame = CGRectMake(edgeInsets.left, 100, self.view.frame.size.width - edgeInsets.left - edgeInsets.right, 40);
	
	_accountTextField.placeholder = @"请输入手机号";
	_accountTextField.backgroundColor = [UIColor whiteColor];
	_accountTextField.layer.cornerRadius = 4;
	[_accountTextField addTarget:self action:@selector(accountTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
	[self.view addSubview:_accountTextField];
	
	frame.origin.y = CGRectGetMaxY(_accountTextField.frame) + edgeInsets.bottom;
	_codeTextField = [[UITextField alloc] initWithFrame:frame];
	_codeTextField.placeholder = @"请输入验证码";
	_codeTextField.backgroundColor = [UIColor whiteColor];
	_codeTextField.layer.cornerRadius = 4;
	[self.view addSubview:_codeTextField];
	
	CGFloat buttonWidth = 100;
	frame.origin.x = CGRectGetMaxX(_codeTextField.frame) - buttonWidth;
	frame.size.width = buttonWidth;
	_getCodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_getCodeButton.frame = frame;
	[_getCodeButton setTitle:@"获取验证码" forState:UIControlStateNormal];
	[_getCodeButton setBackgroundColor:[UIColor grayColor]];
	[_getCodeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[_getCodeButton addTarget:self action:@selector(getCode) forControlEvents:UIControlEventTouchUpInside];
	_getCodeButton.hidden = YES;
	_getCodeButton.showsTouchWhenHighlighted = YES;
	[self.view addSubview:_getCodeButton];
	
	frame.origin.y = CGRectGetMaxY(_getCodeButton.frame) + edgeInsets.bottom;
	_submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_submitButton.frame = frame;
	[_submitButton setTitle:@"确定" forState:UIControlStateNormal];
	_submitButton.backgroundColor = [UIColor whiteColor];
	[_submitButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	_submitButton.layer.cornerRadius = 4;
	_submitButton.layer.borderWidth = 0.5;
	_submitButton.layer.borderColor = [[UIColor blackColor] CGColor];
	[_submitButton addTarget:self action:@selector(submit) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_submitButton];
}

- (void)accountTextFieldChanged:(UITextField *)textField {
	if (_accountTextField == textField) {
		BOOL isValidPhoneNumber = [[BLAPIClient shared] phoneNumberSimpleValidation:_accountTextField.text];
		_getCodeButton.hidden = !isValidPhoneNumber;
	}
}

- (void)getCode {
	[self displayHUD:@"获取验证码..."];
	[[BLAPIClient shared] authCodeWithPhone:_accountTextField.text withBlock:^(NSError *error) {
		if (!error) {
			[self hideHUD:YES];
		} else {
			[self displayHUDTitle:nil message:error.userInfo[BL_ERROR_MESSAGE_IDENTIFIER] duration:1];
		}
	}];
}

- (void)submit {
	if (!_accountTextField.text.length) {
		[self displayHUDTitle:nil message:@"请填写正确的手机号" duration:1];
		return;
	}
	
	if (!_codeTextField.text.length) {
		[self displayHUDTitle:nil message:@"请填写验证码" duration:1];
		return;
	}
	
	
}

@end
