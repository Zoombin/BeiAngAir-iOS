//
//  BLSignupViewController.m
//  BeiAngAir
//
//  Created by zhangbin on 11/24/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BLSignupViewController.h"
#import "BLAPIClient.h"
#import "BLDeviceListViewController.h"

@interface BLSignupViewController ()

@property (readwrite) UITextField *accountTextField;
@property (readwrite) UITextField *passwordTextField;
@property (readwrite) UITextField *passwordConfirmTextField;
@property (readwrite) UITextField *codeTextField;
@property (readwrite) UIButton *getCodeButton;
@property (readwrite) UIButton *signupButton;
@property (readwrite) BOOL isMobilePhoneNumber;

@end

@implementation BLSignupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = NSLocalizedString(@"注册", nil);
	self.navigationController.navigationBarHidden = NO;
	self.view.backgroundColor = [UIColor themeBlue];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
	[self.view addGestureRecognizer:tap];
	
	UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 30, 10, 30);
	CGRect frame = CGRectMake(edgeInsets.left, 100, self.view.frame.size.width - edgeInsets.left - edgeInsets.right, 40);
	_accountTextField = [[UITextField alloc] initWithFrame:frame];
	_accountTextField.placeholder = @"请输入手机号/用户名";
	_accountTextField.backgroundColor = [UIColor whiteColor];
	_accountTextField.layer.cornerRadius = 4;
	[_accountTextField addTarget:self action:@selector(accountTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
	[self.view addSubview:_accountTextField];
	
	frame.origin.y = CGRectGetMaxY(_accountTextField.frame) + edgeInsets.bottom;
	_passwordTextField = [[UITextField alloc] initWithFrame:frame];
	_passwordTextField.placeholder = @"请输入密码";
	_passwordTextField.backgroundColor = [UIColor whiteColor];
	_passwordTextField.layer.cornerRadius = 4;
	_passwordTextField.secureTextEntry = YES;
	[self.view addSubview:_passwordTextField];
	
	frame.origin.y = CGRectGetMaxY(_passwordTextField.frame) + edgeInsets.bottom;
	_passwordConfirmTextField = [[UITextField alloc] initWithFrame:frame];
	_passwordConfirmTextField.placeholder = @"请再次输入密码";
	_passwordConfirmTextField.backgroundColor = [UIColor whiteColor];
	_passwordConfirmTextField.layer.cornerRadius = 4;
	_passwordConfirmTextField.secureTextEntry = YES;
	[self.view addSubview:_passwordConfirmTextField];
	
	frame.origin.y = CGRectGetMaxY(_passwordConfirmTextField.frame) + edgeInsets.bottom;
	_codeTextField = [[UITextField alloc] initWithFrame:frame];
	_codeTextField.placeholder = @"请输入验证码";
	_codeTextField.backgroundColor = [UIColor whiteColor];
	_codeTextField.layer.cornerRadius = 4;
	_codeTextField.hidden = YES;
	[self.view addSubview:_codeTextField];
	
	CGFloat buttonWidth = 100;
	frame.origin.x = CGRectGetMaxX(_codeTextField.frame) - buttonWidth;
	frame.size.width = buttonWidth;
	_getCodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_getCodeButton.frame = frame;
	[_getCodeButton setTitle:@"获取验证码" forState:UIControlStateNormal];
	[_getCodeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	_getCodeButton.backgroundColor = [UIColor grayColor];
	_getCodeButton.showsTouchWhenHighlighted = YES;
	[_getCodeButton addTarget:self action:@selector(getCode) forControlEvents:UIControlEventTouchUpInside];
	_getCodeButton.hidden = YES;
	[self.view addSubview:_getCodeButton];
	
	frame.origin.x = CGRectGetMinX(_codeTextField.frame);
	frame.origin.y = CGRectGetMaxY(_codeTextField.frame) + edgeInsets.bottom;
	frame.size.width = CGRectGetWidth(_codeTextField.frame);
	_signupButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_signupButton.frame = frame;
	_signupButton.layer.cornerRadius = 6;
	_signupButton.layer.borderWidth = 0.5;
	_signupButton.layer.borderColor = [[UIColor blackColor] CGColor];
	_signupButton.backgroundColor = [UIColor whiteColor];
	[_signupButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[_signupButton setTitle:@"注册" forState:UIControlStateNormal];
	[_signupButton addTarget:self action:@selector(signup) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_signupButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (BOOL)phoneNumberSimpleValidation:(NSString *)string {
	NSString *regex = @"^[0-9]{11}$";
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	return [predicate evaluateWithObject:string];
}

- (void)getCode {
	NSLog(@"get code");
}

- (void)accountTextFieldChanged:(UITextField *)textField {
	if (_accountTextField == textField) {
		_isMobilePhoneNumber = [self phoneNumberSimpleValidation:_accountTextField.text];
		_codeTextField.hidden = !_isMobilePhoneNumber;
		_getCodeButton.hidden = !_isMobilePhoneNumber;
	}
}

- (void)signup {
	if (!_accountTextField.text.length) {
		[self displayHUDTitle:nil message:@"账号不能为空" duration:1];
		return;
	}
	
	if (!_passwordTextField.text.length) {
		[self displayHUDTitle:nil message:@"密码不能为空" duration:1];
		return;
	}
	
	if (!_passwordConfirmTextField.text.length) {
		[self displayHUDTitle:nil message:@"密码确认不能为空" duration:1];
		return;
	}
	
	if (![_passwordTextField.text isEqualToString:_passwordConfirmTextField.text]) {
		[self displayHUDTitle:nil message:@"两次密码输入不一致" duration:1];
		return;
	}
	
	[self displayHUD:@"加载中..."];
	[[BLAPIClient shared] registerAccount:_accountTextField.text password:_passwordTextField.text withBlock:^(NSError *error) {
		[self hideHUD:YES];
		if (!error) {
			[self displayHUD:@"登录中..."];
			[[BLAPIClient shared] signinAccount:_accountTextField.text password:_passwordTextField.text withBlock:^(NSError *error) {
				[self hideHUD:YES];
				if (!error) {
					BLDeviceListViewController *deviceListViewController = [[BLDeviceListViewController alloc] initWithStyle:UITableViewStyleGrouped];
					[self.navigationController pushViewController:deviceListViewController animated:YES];
				}
			}];
		} else {
			[self displayHUDTitle:@"错误" message:error.userInfo[BL_ERROR_MESSAGE_IDENTIFIER] duration:2];
		}
	}];
}

@end
