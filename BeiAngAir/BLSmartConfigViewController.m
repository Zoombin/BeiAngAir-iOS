//
//  BLSmartConfigViewController.m
//  TCLAir
//
//  Created by yang on 4/11/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BLSmartConfigViewController.h"
#import "GlobalDefine.h"
#import "JSONKit.h"
#import "EASYLINK.h"
#import "BLAPIClient.h"
#import "BLQRCodeScanViewController.h"

#define EASYLINK_V2 1

@interface BLSmartConfigViewController () <UITextFieldDelegate, UIAlertViewDelegate, EasyLinkFTCDelegate>

@property (readwrite) UITextField *ssidTextField;
@property (readwrite) UITextField *passwordTextField;
@property (readwrite) EASYLINK *easylinkConfig;
@property (readwrite) NSThread *waitForAckThread;

@end

@implementation BLSmartConfigViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = NSLocalizedString(@"SmartConfigViewControllerTitle", nil);
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
	self.view.backgroundColor = [UIColor whiteColor];
	
	CGRect viewFrame = CGRectZero;
	viewFrame.origin.y = 80;
	viewFrame.size.width = self.view.bounds.size.width;
	viewFrame.size.height = 40;
	
    UILabel *addLabel = [[UILabel alloc] initWithFrame:viewFrame];
    [addLabel setTextColor:[UIColor grayColor]];
    [addLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [addLabel setTextAlignment:NSTextAlignmentCenter];
    [addLabel setText:NSLocalizedString(@"SmartConfigViewControllerAddLabelText", nil)];
    [self.view addSubview:addLabel];

    viewFrame = addLabel.frame;
    viewFrame.origin.y += viewFrame.size.height;
    viewFrame.size = CGSizeMake(80.0f, 32.0f);
    UILabel *ssidLabel = [[UILabel alloc] initWithFrame:viewFrame];
    [ssidLabel setBackgroundColor:[UIColor clearColor]];
    [ssidLabel setTextColor:[UIColor blackColor]];
    [ssidLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [ssidLabel setText:NSLocalizedString(@"SmartConfigViewControllerSSIDLabelText", nil)];
    [self.view addSubview:ssidLabel];
    
    //ssid
    viewFrame = ssidLabel.frame;
    viewFrame.origin.x += viewFrame.size.width + 5.0f;
    viewFrame.size.width = self.view.frame.size.width - 30.0f - viewFrame.origin.x;
    _ssidTextField = [[UITextField alloc] initWithFrame:viewFrame];
    [_ssidTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [_ssidTextField setReturnKeyType:UIReturnKeyNext];
    [_ssidTextField setTextColor:RGB(0x13, 0xb3, 0x5c)];
    [_ssidTextField setFont:[UIFont systemFontOfSize:17.0f]];
    [_ssidTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [_ssidTextField setDelegate:self];
    //passwordText背景颜色
    UIImage *image = [UIImage imageNamed:@"input_squre"];
    _ssidTextField.background = image;
    [_ssidTextField setText:[self getCurrentWiFiSSID]];
    [self.view addSubview:_ssidTextField];
    
    viewFrame = ssidLabel.frame;
    viewFrame.origin.y += viewFrame.size.height + 5.0f;
    viewFrame.size = CGSizeMake(80.0f, 32.0f);
    UILabel *PWDLabel = [[UILabel alloc] initWithFrame:viewFrame];
    [PWDLabel setBackgroundColor:[UIColor clearColor]];
    [PWDLabel setTextColor:[UIColor blackColor]];
    [PWDLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [PWDLabel setText:NSLocalizedString(@"SmartConfigViewControllerPWDLabelText", nil)];
    [self.view addSubview:PWDLabel];
    
    viewFrame = PWDLabel.frame;
    viewFrame.origin.x += viewFrame.size.width + 5.0f;
    viewFrame.size.width = self.view.frame.size.width - 30.0f - viewFrame.origin.x;
    _passwordTextField = [[UITextField alloc] initWithFrame:viewFrame];
    [_passwordTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [_passwordTextField setReturnKeyType:UIReturnKeyGo];
    [_passwordTextField setTextColor:RGB(0x13, 0xb3, 0x5c)];
    [_passwordTextField setFont:[UIFont systemFontOfSize:17.0f]];
    [_passwordTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [_passwordTextField setDelegate:self];
    [_passwordTextField setSecureTextEntry:YES];
    //passwordText背景颜色
    _passwordTextField.background = image;
	
	Wifi *wifi = [Wifi wifiWithSSID:_ssidTextField.text];
	_passwordTextField.text = wifi.password;
    [self.view addSubview:_passwordTextField];
	
    image = [UIImage imageNamed:@"check_normal"];
    viewFrame = _passwordTextField.frame;
    viewFrame.origin.y += viewFrame.size.height + 15.0f;
    viewFrame.size.height = 25.0f;
    viewFrame.size.width = self.view.frame.size.width;
    UIButton *showPasswordButton = [[UIButton alloc] initWithFrame:viewFrame];
    [showPasswordButton setBackgroundColor:[UIColor clearColor]];
    [showPasswordButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, viewFrame.size.width - image.size.width)];
    [showPasswordButton setImage:image forState:UIControlStateNormal];
    image = [UIImage imageNamed:@"check_press"];
    [showPasswordButton setImage:image forState:UIControlStateSelected];
    [showPasswordButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [showPasswordButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, image.size.width, 0.0f, -image.size.width)];
    [showPasswordButton setTitle:NSLocalizedString(@"SmartConfigViewControllerShowPasswordText", nil) forState:UIControlStateNormal];
    [showPasswordButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [showPasswordButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [showPasswordButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted | UIControlStateSelected];
    [showPasswordButton addTarget:self action:@selector(showPasswordButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [showPasswordButton.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [showPasswordButton sizeToFit];
    viewFrame = showPasswordButton.frame;
    viewFrame.origin.x = (self.view.frame.size.width - viewFrame.size.width) * 0.5f;
    [showPasswordButton setFrame:viewFrame];
    [showPasswordButton setImageEdgeInsets:UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, viewFrame.size.width - image.size.width)];
    [self.view addSubview:showPasswordButton];
	
    viewFrame.origin.x = 0;
    viewFrame.origin.y = CGRectGetMaxY(showPasswordButton.frame) + 15;
	viewFrame.size.width = self.view.bounds.size.width;
	viewFrame.size.height = 40;
    UIButton *configButton = [[UIButton alloc] initWithFrame:viewFrame];
    [configButton setBackgroundColor:[UIColor themeBlue]];
    [configButton setTitle:NSLocalizedString(@"SmartConfigViewControllerConfigButtonText", nil) forState:UIControlStateNormal];
    [configButton.titleLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [configButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [configButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    [configButton addTarget:self action:@selector(configButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:configButton];
	
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self.view action:@selector(endEditing:)];
	[self.view addGestureRecognizer:tapGestureRecognizer];
	
	
	viewFrame.origin.x = 50;
	viewFrame.origin.y = self.view.frame.size.height - 80;
	viewFrame.size.width = 64;
	viewFrame.size.height = 64;
	UIButton *qrcodeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	qrcodeButton.frame = viewFrame;
	[qrcodeButton addTarget:self action:@selector(qrcodeScan) forControlEvents:UIControlEventTouchUpInside];
	[qrcodeButton setImage:[UIImage imageNamed:@"config_qr_code"] forState:UIControlStateNormal];
	[self.view addSubview:qrcodeButton];
	
	viewFrame.origin.x = 210;
	UIButton *bindedDevicesButton = [UIButton buttonWithType:UIButtonTypeCustom];
	bindedDevicesButton.frame = viewFrame;
	[bindedDevicesButton addTarget:self action:@selector(bindedDevices) forControlEvents:UIControlEventTouchUpInside];
	[bindedDevicesButton setImage:[UIImage imageNamed:@"config_bound"] forState:UIControlStateNormal];
	[self.view addSubview:bindedDevicesButton];
	
	viewFrame.origin.x = 0;
	viewFrame.origin.y = CGRectGetMaxY(qrcodeButton.frame);
	viewFrame.size.width = self.view.frame.size.width / 2;
	viewFrame.size.height = 20;
	UILabel *qrcodeLabel = [[UILabel alloc] initWithFrame:viewFrame];
	qrcodeLabel.text = @"扫描二维码";
	qrcodeLabel.font = [UIFont systemFontOfSize:13];
	qrcodeLabel.textAlignment = NSTextAlignmentCenter;
	[self.view addSubview:qrcodeLabel];
	
	viewFrame.origin.x = self.view.frame.size.width / 2;
	UILabel *bindedDevicesLable = [[UILabel alloc] initWithFrame:viewFrame];
	bindedDevicesLable.text = @"已绑定设备";
	bindedDevicesLable.font = [UIFont systemFontOfSize:13];
	bindedDevicesLable.textAlignment = NSTextAlignmentCenter;
	[self.view addSubview:bindedDevicesLable];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)qrcodeScan {
	BLQRCodeScanViewController *qrCodeScanViewController = [[BLQRCodeScanViewController alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:qrCodeScanViewController animated:YES];
}

- (void)bindedDevices {
	[self displayHUDTitle:nil message:@"加载中..." duration:4];
	[self performSelector:@selector(dismiss) withObject:nil afterDelay:4];
}

/*获取当前连接的wifi网络名称，如果未连接，则为nil*/
- (NSString *)getCurrentWiFiSSID
{
	CFArrayRef ifs = CNCopySupportedInterfaces();
	if (ifs == NULL)
		return nil;
	CFDictionaryRef info = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(ifs, 0));
	CFRelease(ifs);
	if (info == NULL)
		return nil;
	NSDictionary *dic = (__bridge_transfer NSDictionary *)info;
	// If ssid is not exist.
	if ([dic isEqual:nil])
		return nil;
	NSString *ssid = [dic objectForKey:@"SSID"];
	return ssid;
}

- (void)dismiss
{
	[self stopAction];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)configButtonClicked
{
	if (_ssidTextField.text.length && _passwordTextField.text.length) {
		Wifi *wifi = [[Wifi alloc] init];
		wifi.SSID = _ssidTextField.text;
		wifi.password = _passwordTextField.text;
		[wifi persistence];
		
		_easylinkConfig = [[EASYLINK alloc] init];
		_easylinkConfig.delegate = self;
		[self startTransmitting:EASYLINK_V2];
	}
}

- (void)startTransmitting:(int)version {
	if (!_ssidTextField.text.length) {
		[self displayHUDTitle:nil message:@"请填写WIFI名称" duration:1];
		return;
	}
	
	if (!_passwordTextField.text.length) {
		[self displayHUDTitle:nil message:@"请填写密码" duration:1];
		return;
	}
	
	[self displayHUD:@"绑定中，该过程可能持续一分钟"];
	[self.view endEditing:YES];

	NSNumber *dhcp = @(NO);
	NSString *ipString = @"";
	NSString *netmaskString = @"";
	NSString *gatewayString = @"";
	NSString *dnsString = @"";
	
	NSArray *wlanConfigArray = [NSArray arrayWithObjects:_ssidTextField.text, _passwordTextField.text, dhcp, ipString, netmaskString, gatewayString, dnsString, nil];
	
	NSString *userID = [[BLAPIClient shared] userID];
	NSString *hex = [NSString hexStringFromString:@"Beiang"];
	NSData *data = [self hexToBytes:hex];
	NSUInteger number = userID.integerValue;
	NSMutableData *mutableData = [NSMutableData dataWithData:data];
	NSData *userIDData = [self dataFromInt:number];
	[mutableData appendData:userIDData];
//	unsigned char bytes[] = { 0x42, 0x65, 0x69, 0x61, 0x6e, 0x67, 0x05, 0xf5, 0xe1, 0x2e};
//	NSData *expectedData = [NSData dataWithBytes:bytes length:sizeof(bytes)];
//	NSLog(@"mutableData: %@", mutableData);
	[_easylinkConfig prepareEasyLink_withFTC:wlanConfigArray info:mutableData version:EASYLINK_V2];
	[self sendAction];
}

- (NSData *)dataFromInt:(int)num {
	unsigned char * arr = (unsigned char *) malloc(sizeof(num) * sizeof(unsigned char));
	for (int i = sizeof(num) - 1 ; i >= 0; i--) {
		arr[i] = num & 0xFF;
		num = num >> 8;
	}
	NSData *data = [NSData dataWithBytes:arr length:sizeof(num)];
	free(arr);
	return data;
}

- (NSData *)hexToBytes:(NSString *)string {
	NSMutableData* data = [NSMutableData data];
	int idx;
	for (idx = 0; idx+2 <= string.length; idx+=2) {
		NSRange range = NSMakeRange(idx, 2);
		NSString* hexStr = [string substringWithRange:range];
		NSScanner* scanner = [NSScanner scannerWithString:hexStr];
		unsigned int intValue;
		[scanner scanHexInt:&intValue];
		[data appendBytes:&intValue length:1];
	}
	return data;
}

- (void)sendAction {
	[_easylinkConfig transmitSettings];
	_waitForAckThread = [[NSThread alloc] initWithTarget:self selector:@selector(waitForAck:) object:nil];
	[_waitForAckThread start];
}

-(void)stopAction {
	[_waitForAckThread cancel];
	_waitForAckThread = nil;
}

- (void)waitForAck:(id)sender {
	__block BOOL bindSuccess = NO;
	__block NSInteger count = 0;
	while(_waitForAckThread) {
		count++;
		if (count > 15) {//1分钟超时
			[self hideHUD:NO];
			[self displayHUDTitle:@"错误" message:@"访问超时，请重试" duration:3];
			[self stopAction];
			break;
		}
		[[BLAPIClient shared] getBindResultWithBlock:^(BOOL newDeviceFound, NSError *error) {
			if (!error) {
				bindSuccess = newDeviceFound;
				if (newDeviceFound) {
					[self hideHUD:NO];
					[self stopAction];
					NSLog(@"find new device");
				}
			} else {
				[self hideHUD:NO];
				[self displayHUDTitle:@"错误" message:error.userInfo[BL_ERROR_MESSAGE_IDENTIFIER] duration:3];
				[self stopAction];
			}
		}];
		if (bindSuccess) {
			break;
		}
		sleep(4);
	}
	
	if (bindSuccess) {
		[self displayHUDTitle:@"绑定成功" message:nil];
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

#pragma marks - UIAlertViewDelegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[[NSNotificationCenter defaultCenter] postNotificationName:BEIANG_NOTIFICATION_IDENTIFIER_ADDED_DEVICE object:nil];
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showPasswordButtonClicked:(UIButton *)button
{
    [button setSelected:![button isSelected]];
    [_passwordTextField setSecureTextEntry:![button isSelected]];
}

#pragma mark - UITextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([textField isEqual:_ssidTextField]) {
        [_passwordTextField resignFirstResponder];
        return NO;
    }
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.30f];
    self.view.frame = CGRectMake(0.0f, (IsiOS7Later) ? 0.0f : 20.0f, self.view.frame.size.width, self.view.frame.size.height);
    [UIView commitAnimations];
    [self.view endEditing:YES];
    
    if ([textField isEqual:_passwordTextField]) {
        [self configButtonClicked];
    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    CGRect frame = textField.frame;
    int offset = self.view.frame.size.height - frame.origin.y - frame.size.height - 256;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.30f];
    float width = self.view.frame.size.width;
    float height = self.view.frame.size.height;
    if(offset < 0) {
        CGRect rect = CGRectMake(0.0f, offset,width,height);
        self.view.frame = rect;
    }
    [UIView commitAnimations];
    return YES;
}

#pragma mark - EasyLinkFTCDelegate

- (void)onFoundByFTC:(NSNumber *)client currentConfig: (NSData *)config {
	NSLog(@"config: %@", config);
}

@end
