//
//  BLSigninViewController.m
//  BeiAngAir
//
//  Created by zhangbin on 11/24/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BLSigninViewController.h"
#import "BLForgotPasswordViewController.h"
#import "BLSignupViewController.h"
#import "BLAPIClient.h"
#import "BLDeviceListViewController.h"

@interface BLSigninViewController ()

@property (readwrite) UITextField *accountTextField;
@property (readwrite) UITextField *passwordTextField;
@property (readwrite) UIButton *signinButton;
@property (readwrite) UIButton *cancelButton;
@property (readwrite) UILabel *signupLabel;
@property (readwrite) UILabel *forgotPasswordLabel;

@end

@implementation BLSigninViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = NSLocalizedString(@"登录", nil);
	self.view.backgroundColor = [UIColor themeBlue];
	
	CGRect viewFrame = CGRectZero;
	UIImage *image = [UIImage imageNamed:@"home_logo"];
	viewFrame.origin.y = 20;
	viewFrame.origin.x = (self.view.frame.size.width - image.size.width) / 2;
	viewFrame.size = image.size;
	UIImageView *logoImageView = [[UIImageView alloc] initWithFrame:viewFrame];
	[logoImageView setImage:image];
	[self.view addSubview:logoImageView];
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
	[self.view addGestureRecognizer:tap];
	
	UIEdgeInsets edgeInsets = UIEdgeInsetsMake(0, 30, 15, 30);

	CGRect frame = CGRectMake(edgeInsets.left, CGRectGetMaxY(logoImageView.frame), self.view.frame.size.width - edgeInsets.left - edgeInsets.right, 40);
	_accountTextField = [[UITextField alloc] initWithFrame:frame];
	_accountTextField.placeholder = @"请输入手机号/用户名";
	_accountTextField.backgroundColor = [UIColor whiteColor];
	_accountTextField.layer.cornerRadius = 4;
	[self.view addSubview:_accountTextField];
	
	frame.origin.y = CGRectGetMaxY(_accountTextField.frame) + edgeInsets.bottom;
	_passwordTextField = [[UITextField alloc] initWithFrame:frame];
	_passwordTextField.placeholder = @"请输入密码";
	_passwordTextField.layer.cornerRadius = 4;
	_passwordTextField.backgroundColor = [UIColor whiteColor];
	_passwordTextField.secureTextEntry = YES;
	[self.view addSubview:_passwordTextField];
	
	frame.origin.y = CGRectGetMaxY(_passwordTextField.frame) + edgeInsets.bottom;
	frame.size.width = 120;
	_signinButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_signinButton.frame = frame;
	_signinButton.layer.borderColor = [[UIColor blackColor] CGColor];
	_signinButton.layer.borderWidth = 0.5;
	_signinButton.layer.cornerRadius = 6;
	_signinButton.backgroundColor = [UIColor whiteColor];
	[_signinButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[_signinButton setTitle:@"登录" forState:UIControlStateNormal];
	[_signinButton addTarget:self action:@selector(signin) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_signinButton];
	
	frame.origin.x = CGRectGetMaxX(_signinButton.frame) + 20;
	_cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_cancelButton.frame = frame;
	_cancelButton.layer.borderColor = [[UIColor blackColor] CGColor];
	_cancelButton.layer.borderWidth = 0.5;
	_cancelButton.layer.cornerRadius = 6;
	_cancelButton.backgroundColor = [UIColor whiteColor];
	[_cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[_cancelButton setTitle:@"取消" forState:UIControlStateNormal];
	[_cancelButton addTarget:self action:@selector(cancel) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_cancelButton];
	
	frame.origin.x = edgeInsets.left;
	frame.origin.y = CGRectGetMaxY(_cancelButton.frame) + edgeInsets.bottom;
	frame.size.width = (self.view.frame.size.width - edgeInsets.left - edgeInsets.right) / 2;
	_forgotPasswordLabel = [[UILabel alloc] initWithFrame:frame];
	_forgotPasswordLabel.text = @"忘记密码";
	_forgotPasswordLabel.textAlignment = NSTextAlignmentLeft;
	_forgotPasswordLabel.userInteractionEnabled = YES;
	_forgotPasswordLabel.font = [UIFont systemFontOfSize:15];
	[self.view addSubview:_forgotPasswordLabel];
	UITapGestureRecognizer *forgotPasswordTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(forgotPassword)];
	[_forgotPasswordLabel addGestureRecognizer:forgotPasswordTap];
	
	frame.origin.x = CGRectGetMaxX(_forgotPasswordLabel.frame);
	frame.origin.y = CGRectGetMaxY(_cancelButton.frame) + edgeInsets.bottom;
	frame.size.width = (self.view.frame.size.width - edgeInsets.left - edgeInsets.right) / 2;
	_signupLabel = [[UILabel alloc] initWithFrame:frame];
	_signupLabel.text = @"没有账号?点击注册";
	_signupLabel.font = _forgotPasswordLabel.font;
	_signupLabel.textAlignment = NSTextAlignmentRight;
	_signupLabel.userInteractionEnabled = YES;
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(signup)];
	[_signupLabel addGestureRecognizer:tapGestureRecognizer];
	[self.view addSubview:_signupLabel];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.navigationBarHidden = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)signin {
//#warning hardcode account and password
//#ifdef DEBUG
//	_accountTextField.text = @"AricMr";
//	_passwordTextField.text = @"123456";
//#endif
	if (!_accountTextField.text.length) {
		[self displayHUDTitle:@"错误" message:@"账号不能为空" duration:3];
		return;
	}
	
	if (!_passwordTextField.text.length) {
		[self displayHUDTitle:@"错误" message:@"密码不能为空" duration:3];
		return;
	}
	
	[self displayHUD:@"登录中..."];
	[[BLAPIClient shared] signinAccount:_accountTextField.text password:_passwordTextField.text withBlock:^(NSError *error) {
		[self hideHUD:YES];
		if (!error) {
			BLDeviceListViewController *deviceListViewController = [[BLDeviceListViewController alloc] initWithStyle:UITableViewStyleGrouped];
			[self.navigationController pushViewController:deviceListViewController animated:YES];
		} else {
			[self displayHUDTitle:@"错误" message:error.userInfo[BL_ERROR_MESSAGE_IDENTIFIER]];
		}
	}];
}

- (void)cancel {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)forgotPassword {
	BLForgotPasswordViewController *forgotPasswordViewController = [[BLForgotPasswordViewController alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:forgotPasswordViewController animated:YES];
}

- (void)signup {
	BLSignupViewController *signupViewController = [[BLSignupViewController alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:signupViewController animated:YES];
}

@end
