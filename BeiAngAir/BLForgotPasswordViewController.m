//
//  BLForgotPasswordViewController.m
//  BeiAngAir
//
//  Created by zhangbin on 1/4/15.
//  Copyright (c) 2015 BroadLink. All rights reserved.
//

#import "BLForgotPasswordViewController.h"
#import "BLAPIClient.h"

@interface BLForgotPasswordViewController ()

@property (readwrite) UITextField *accountTextField;
@property (readwrite) UITextField *codeTextField;
@property (readwrite) UIButton *getCodeButton;
@property (readwrite) UITextField *passwordTextField;
@property (readwrite) UIButton *submitButton;

@end

@implementation BLForgotPasswordViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.title = NSLocalizedString(@"忘记密码", nil);
	self.view.backgroundColor = [UIColor themeBlue];
	self.navigationController.navigationBarHidden = NO;
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
	[self.view addGestureRecognizer:tap];
	
	UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 30, 10, 30);
	CGRect frame = CGRectMake(edgeInsets.left, 100, self.view.frame.size.width - edgeInsets.left - edgeInsets.right, 40);
	
	_accountTextField = [[UITextField alloc] initWithFrame:frame];
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
	
	frame.origin.x = edgeInsets.left;
	frame.origin.y = CGRectGetMaxY(_codeTextField.frame) + edgeInsets.bottom;
	frame.size.width = CGRectGetWidth(_codeTextField.frame);
	_passwordTextField = [[UITextField alloc] initWithFrame:frame];
	_passwordTextField.placeholder = @"请输入新密码";
	_passwordTextField.backgroundColor = [UIColor whiteColor];
	_passwordTextField.layer.cornerRadius = 4;
	_passwordTextField.secureTextEntry = YES;
	[self.view addSubview:_passwordTextField];
	
	frame.origin.y = CGRectGetMaxY(_passwordTextField.frame) + edgeInsets.bottom;
	_submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_submitButton.frame = frame;
	[_submitButton setTitle:@"设置" forState:UIControlStateNormal];
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
	if (!_accountTextField.text.length) {
		[self displayHUDTitle:nil message:@"请填写手机号" duration:3];
		return;
	}
	
	[self displayHUD:@"获取验证码..."];
	[[BLAPIClient shared] authCodeWithPhone:_accountTextField.text withBlock:^(NSError *error) {
		if (!error) {
			[self hideHUD:YES];
		} else {
			[self displayHUDTitle:nil message:error.userInfo[BL_ERROR_MESSAGE_IDENTIFIER] duration:3];
		}
	}];
}

- (void)submit {
	if (!_codeTextField.text.length) {
		[self displayHUDTitle:nil message:@"请填写验证码" duration:3];
		return;
	}
	
	if (!_passwordTextField.text.length) {
		[self displayHUDTitle:nil message:@"请输入新密码" duration:3];
		return;
	}
	
	[self displayHUD:@"重置密码中..."];
	[[BLAPIClient shared] resetPassword:_passwordTextField.text phone:_accountTextField.text code:_codeTextField.text withBlock:^(NSError *error) {
		if (!error) {
			[self displayHUDTitle:nil message:@"修改密码成功" duration:3];
			[self performSelector:@selector(back) withObject:nil afterDelay:2];
		} else {
			[self displayHUDTitle:nil message:error.userInfo[BL_ERROR_MESSAGE_IDENTIFIER] duration:2];
		}
	}];
}

- (void)back {
	[self.navigationController popViewControllerAnimated:YES];
}

@end
