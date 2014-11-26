//
//  BLSmartConfigViewController.m
//  TCLAir
//
//  Created by yang on 4/11/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BLSmartConfigViewController.h"
#import "GlobalDefine.h"
#import "BLNetwork.h"
#import "JSONKit.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "Reachability.h"
#import "EASYLINK.h"
#import "BLAPIClient.h"

#define EASYLINK_V2 1

@interface BLSmartConfigViewController () <UITextFieldDelegate,UIAlertViewDelegate>

@property (readwrite) UITextField *ssidTextField;
@property (readwrite) UITextField *passwordTextField;
@property (readwrite) BLNetwork *configAPI;
@property (readwrite) Reachability *wifiReachability;
@property (readwrite) EASYLINK *easylinkConfig;
@property (readwrite) NSTimer *sendInterval;
@property (readwrite) NSThread *waitForAckThread;

@end

@implementation BLSmartConfigViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"SmartConfigViewControllerTitle", nil);
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor whiteColor];
    _configAPI = [[BLNetwork alloc] init];
	
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
    [_passwordTextField becomeFirstResponder];
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

/*获取当前连接的wifi网络名称，如果未连接，则为nil*/
- (NSString *)getCurrentWiFiSSID
{
	CFArrayRef ifs = CNCopySupportedInterfaces();       //得到支持的网络接口 eg. "en0", "en1"
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
	[_waitForAckThread cancel];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)configButtonClicked
{
	CGRect viewFrame = CGRectZero;
	viewFrame.origin.y = 80;
	viewFrame.size.width = self.view.frame.size.width;
	viewFrame.size.height = self.view.frame.size.height - viewFrame.origin.y;
	UIView *waitingView = [[UIView alloc] initWithFrame:viewFrame];
	[waitingView setBackgroundColor:[UIColor whiteColor]];
	[self.view addSubview:waitingView];
	viewFrame = waitingView.frame;
	viewFrame.origin.x = 20.0f;
	viewFrame.size.width -= 40.0f;
	UILabel *configLabel = [[UILabel alloc] initWithFrame:viewFrame];
	[configLabel setBackgroundColor:[UIColor clearColor]];
	[configLabel setFont:[UIFont systemFontOfSize:15.0f]];
	[configLabel setTextColor:[UIColor grayColor]];
	[configLabel setText:NSLocalizedString(@"SmartConfigViewControllerConfigLabelText", nil)];
	[configLabel setNumberOfLines:3];
	viewFrame = [configLabel textRectForBounds:viewFrame limitedToNumberOfLines:3];
	viewFrame.origin.x = (waitingView.frame.size.width - viewFrame.size.width) * 0.5f;
	viewFrame.origin.y = (waitingView.frame.size.height - viewFrame.size.height) * 0.5f - 30.0f;
	[configLabel setFrame:viewFrame];
	[configLabel setTextAlignment:NSTextAlignmentCenter];
	[waitingView addSubview:configLabel];
	UIImage *image = [UIImage imageNamed:@"wait"];
	viewFrame = configLabel.frame;
	viewFrame.origin.y += viewFrame.size.height + 10.0f;
	viewFrame.origin.x = (waitingView.frame.size.width - image.size.width) * 0.5f;
	viewFrame.size = image.size;
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:viewFrame];
	[imageView setBackgroundColor:[UIColor clearColor]];
	[imageView setImage:image];
	CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];  
	rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 ];  
	rotationAnimation.duration = 2.0f;  
	rotationAnimation.cumulative = YES;  
	rotationAnimation.repeatCount = NSIntegerMax;  
	[imageView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
	[waitingView addSubview:imageView];

	
	if (_ssidTextField.text.length && _passwordTextField.text.length) {
		Wifi *wifi = [[Wifi alloc] init];
		wifi.SSID = _ssidTextField.text;
		wifi.password = _passwordTextField.text;
		[wifi persistence];
//		[self startConfig];
		
		_easylinkConfig = [[EASYLINK alloc] init];
		[self startTransmitting:EASYLINK_V2];
	}
}

- (NSString *)hexStringFromString:(NSString *)string {
	NSData *myD = [string dataUsingEncoding:NSUTF8StringEncoding];
	Byte *bytes = (Byte *)[myD bytes];
	//下面是Byte 转换为16进制。
	NSString *hexStr = @"";
	for(int i=0; i < [myD length]; i++) {
		NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];///16进制数
		if([newHexStr length] == 1) {
			hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
		} else {
			hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
		}
	}
	return hexStr;
}

- (NSString *)hexString:(NSString *)str {
	NSString * hexStr = [NSString stringWithFormat:@"%@", [NSData dataWithBytes:[str cStringUsingEncoding:NSUTF8StringEncoding] length:strlen([str cStringUsingEncoding:NSUTF8StringEncoding])]];
	for(NSString * toRemove in [NSArray arrayWithObjects:@"<", @">", @" ", nil]) {
		hexStr = [hexStr stringByReplacingOccurrencesOfString:toRemove withString:@""];
	}
	return hexStr;
}

- (void)startTransmitting:(int)version {
//	NetworkStatus netStatus = [_wifiReachability currentReachabilityStatus];
//	if ( netStatus == NotReachable ){// No activity if no wifi
//		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"WiFi not available. Please check your WiFi connection" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//		[alertView show];
//		return;
//	}
	
//	if([userInfoField.text length] > 0 && version == EASYLINK_V1) {
//		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:@"Custom information cannot be delivered by EasyLink V1" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
//		[alertView show];
//	}
	
	if (!_ssidTextField.text.length) {
		[self displayHUDTitle:nil message:@"请填写WIFI名称" duration:1];
		return;
	}
	
	if (!_passwordTextField.text.length) {
		[self displayHUDTitle:nil message:@"请填写密码" duration:1];
		return;
	}
	
	[self displayHUD:@"加载中..."];
	[self.view endEditing:YES];
//	NSString *userID = [[BLAPIClient shared] userID];
//	NSString *beiangAddUserID = [NSString stringWithFormat:@"%@%@", @"Beiang", userID];
//	NSData *data = [userID dataUsingEncoding:NSUTF8StringEncoding];
//	uint8_t *dataBuffer = (uint8_t *)[data bytes];
//	for (int i = 0; i < [userID lengthOfBytesUsingEncoding:NSUTF8StringEncoding]; i++) {
//		uint8_t c = dataBuffer[i];
//		NSLog(@"%i", c);
//	}
	
//	uint8_t *buffer = new Byte[0x42 ,0x65 ,0x69 ,0x61 ,0x6e ,0x67 ,0x05 ,0xf5 ,0xe1 ,0x2e];
//	Byte buffer[] = {0x42 ,0x65 ,0x69 ,0x61 ,0x6e ,0x67 ,0x05 ,0xf5 ,0xe1 ,0x2e};
//	NSLog(@"buffer: %s", buffer);
//	NSData *data = [[NSData alloc] initWithBytes:buffer length:10];
//	NSString *string = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
//	NSLog(@"string: %@", string);
	
//	NSString *hexUserID = [self hexStringFromString:userID];
//	NSLog(@"userID: %@", userID);
//	NSLog(@"hex userID: %@", hexUserID);
//	NSLog(@"hex string: %@", [self hexString:userID]);
//	hexUserID = @"426569616e6705f5e12e";
//	
//	hexUserID = [NSString stringWithUTF8String:buffer];
	[_easylinkConfig prepareEasyLinkV2:_ssidTextField.text password:_passwordTextField.text info:@"here bug"];
	[self sendAction];
}

- (void)stopTransmitting {
	if(_sendInterval != nil){
		[_sendInterval invalidate];
		_sendInterval = nil;
	}
}

- (void)sendAction {
//	newModuleFound = NO;
	[_easylinkConfig transmitSettings];
	_waitForAckThread = [[NSThread alloc] initWithTarget:self selector:@selector(waitForAck:) object:nil];
	[_waitForAckThread start];
}

-(void)stopAction {
	[_easylinkConfig stopTransmitting];
	[_waitForAckThread cancel];
	_waitForAckThread= nil;
}

- (void)waitForAck:(id)sender {
	while([_waitForAckThread isCancelled] == NO) {
//		if (newModuleFound == YES ){
			//[self stopAction];
			//[self.navigationController popToRootViewControllerAnimated:YES];
			//break;
//		}
		sleep(1);
	}
}

- (void)startConfig {
	[self.view endEditing:YES];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSDictionary *dictionary = [NSDictionary dictionaryEashConfigWithSSID:_ssidTextField.text password:_passwordTextField.text];
        NSData *requestData = [dictionary JSONData];
        NSData *responseData = [_configAPI requestDispatch:requestData];
		NSLog(@"responseData: %@", [responseData objectFromJSONData]);
		int code = [[[responseData objectFromJSONData] objectForKey:@"code"] intValue];
		if (code == 0) {
			dispatch_async(dispatch_get_main_queue(), ^{
				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"添加设备成功", nil) message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
				[alertView show];
			});
		} else {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"设备添加失败，请重新尝试", nil) message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
			[alertView show];
		}
    });
}

- (void)cancelConfig
{
	NSDictionary *dictionary = [NSDictionary dictionaryCancelEashConfig];
	NSData *requestData = [dictionary JSONData];
	[_configAPI requestDispatch:requestData];
}

#pragma marks -- UIAlertViewDelegate --

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

@end
