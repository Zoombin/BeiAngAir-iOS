//
//  BLAirQualityViewController.m
//  TCLAir
//
//  Created by yang on 4/11/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "BLDeviceControlViewController.h"
#import "GlobalDefine.h"
#import "BLAppDelegate.h"
#import "BLFilterViewController.h"
#import "JSONKit.h"
#import "BLAboutViewController.h"
#import "SBJson.h"
#import "UIViewController+MMDrawerController.h"
#import "MMDrawerController.h"
#import "MMDrawerVisualState.h"
#import "MMExampleDrawerVisualStateManager.h"
#import "Weather.h"
#import "BLShareViewController.h"
#import "BLScheduleManager.h"
#import "BLAPIClient.h"

NSTimeInterval const scheduleRefreshInterval = 4;

@interface BLDeviceControlViewController () <UIScrollViewDelegate, CLLocationManagerDelegate, MKMapViewDelegate>

@property (readwrite) dispatch_queue_t httpQueue;
@property (readwrite) UIView *backView;
@property (readwrite) UILabel *airQualityLabel;
@property (readwrite) UIButton *switchButton;
@property (readwrite) UIButton *handOrAutoButton;
@property (readwrite) UIButton *childLockButton;
@property (readwrite) UIButton *sleepButton;
@property (readwrite) UILabel *weatherLabel;
@property (readwrite) UILabel *leftTimerLabel;
@property (readwrite) UIButton *shareButton;
@property (readwrite) CLLocationManager *locationManager;
@property (readwrite) CLLocation *currentLocation;
@property (readwrite) Weather *weather;
@property (readwrite) BLShareViewController *shareViewController;
@property (readwrite) NSTimer *timer;

@end

@implementation BLDeviceControlViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Airdog", nil) style:UIBarButtonItemStylePlain target:self action:@selector(rightButtonClick:)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_weather = [[Weather alloc] init];
	_httpQueue = dispatch_queue_create("BLHttpQueue", DISPATCH_QUEUE_SERIAL);
    
    _locationManager = [[CLLocationManager alloc] init];
    [_locationManager setDelegate:self];
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [_locationManager setDistanceFilter:500.0f];
	if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
		[_locationManager requestWhenInUseAuthorization];
	}
    [_locationManager startUpdatingLocation];

	self.view.backgroundColor = [UIColor greenColor];
	UIEdgeInsets edgeInsets = UIEdgeInsetsMake(20, 30, 0, 30);
	
	CGRect viewFrame = CGRectZero;
	viewFrame.origin.x = 20;
	viewFrame.origin.y = 70;
    viewFrame.size.width = self.view.frame.size.width - viewFrame.origin.x * 2;
    viewFrame.size.height = 80;
    _weatherLabel = [[UILabel alloc] initWithFrame:viewFrame];
	_weatherLabel.numberOfLines = 0;
    [_weatherLabel setBackgroundColor:[UIColor clearColor]];
    [_weatherLabel setTextColor:[UIColor whiteColor]];
    [_weatherLabel setFont:[UIFont systemFontOfSize:17.f]];
	[self.view addSubview:_weatherLabel];
	

	UIImage *shareImage = [UIImage imageNamed:@"Share"];
	viewFrame.origin.x = self.view.frame.size.width - shareImage.size.width - edgeInsets.right;
	viewFrame.origin.y = 90;
	viewFrame.size = shareImage.size;
	
	_shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_shareButton.frame = viewFrame;
	_shareButton.showsTouchWhenHighlighted = YES;
	[_shareButton setImage:shareImage forState:UIControlStateNormal];
	[_shareButton addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_shareButton];
    
    //底部视图
    viewFrame.origin.x =  0;
	viewFrame.origin.y = 145;
    viewFrame.size.width = self.view.frame.size.width;
    viewFrame.size.height = self.view.frame.size.height - viewFrame.origin.y;
	
    UIView *bottomView = [[UIView alloc] initWithFrame:viewFrame];
    [bottomView.layer setMasksToBounds:YES];
    [bottomView.layer setCornerRadius:10.f];
    [bottomView setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:bottomView];
    
    //空气质量指数
    _airQualityLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, edgeInsets.top, self.view.frame.size.width, 60)];
    [_airQualityLabel setBackgroundColor:[UIColor clearColor]];
	_airQualityLabel.numberOfLines = 0;
    [_airQualityLabel setTextColor:[UIColor blackColor]];
    [_airQualityLabel setFont:[UIFont boldSystemFontOfSize:16]];
	_airQualityLabel.textAlignment = NSTextAlignmentCenter;
    [bottomView addSubview:_airQualityLabel];
	[self refreshInsideAirQuality];
	
	//风速
	UIImage *image = [UIImage imageNamed:@"wind"];
	viewFrame.origin.x = edgeInsets.left - 10;
	viewFrame.origin.y = edgeInsets.top + 20;
	viewFrame.size = CGSizeMake(image.size.width, image.size.height);
	UIButton *speedButton = [[UIButton alloc] initWithFrame:viewFrame];
	[speedButton setBackgroundColor:[UIColor clearColor]];
	[speedButton setImage:image forState:UIControlStateNormal];
	[speedButton addTarget:self action:@selector(speedButtonClick:) forControlEvents:UIControlEventTouchUpInside];
	[bottomView addSubview:speedButton];
	
    //定时任务
	UIImage *timeImage = [UIImage imageNamed:@"time"];
    viewFrame.origin.x =  self.view.frame.size.width - timeImage.size.width - edgeInsets.left + 10;
    viewFrame.origin.y = edgeInsets.top + 20;
    viewFrame.size = timeImage.size;
    UIButton *timerButton = [[UIButton alloc] initWithFrame:viewFrame];
    [timerButton setBackgroundColor:[UIColor clearColor]];
    [timerButton setImage:timeImage forState:UIControlStateNormal];
    [timerButton addTarget:self action:@selector(timerButtonClick) forControlEvents:UIControlEventTouchUpInside];
	timerButton.hidden = YES;
    [bottomView addSubview:timerButton];
	
	CGSize buttonSize = CGSizeMake(110, 110);
	viewFrame.origin.x =  (self.view.frame.size.width - buttonSize.width) / 2.f;
	viewFrame.origin.y = timerButton.frame.origin.y + timerButton.frame.size.height + 15.f;
	viewFrame.size = buttonSize;
	
    _switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[_switchButton setFrame:viewFrame];
	[_switchButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self deviceOn:[_device isOn]];
    [_switchButton addTarget:self action:@selector(allButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_switchButton];
	
	CGSize titleSize = CGSizeZero;
	buttonSize = CGSizeMake(47, 47 + 15);
	viewFrame.origin.x = edgeInsets.left;
	viewFrame.origin.y = CGRectGetMaxY(_switchButton.frame) - 5;
	viewFrame.size = buttonSize;
	UIFont *font = [UIFont systemFontOfSize:13];
	
	//自动/手动
    _handOrAutoButton  = [UIButton buttonWithType:UIButtonTypeCustom];
	[_handOrAutoButton setFrame:viewFrame];
	_handOrAutoButton.titleLabel.font = font;
	[_handOrAutoButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self deviceAutoOn:[_device isAutoOn]];
	[_handOrAutoButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -buttonSize.width, - buttonSize.height, 0)];
	titleSize = _handOrAutoButton.titleLabel.frame.size;
	[_handOrAutoButton setImageEdgeInsets:UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width)];
	_handOrAutoButton.contentMode = UIViewContentModeCenter;
	
    [_handOrAutoButton addTarget:self action:@selector(allButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_handOrAutoButton];

	viewFrame.origin.x =  (self.view.frame.size.width - buttonSize.width) / 2.f;
	viewFrame.origin.y = _handOrAutoButton.frame.origin.y + _handOrAutoButton.frame.size.height * 2.f / 3.f;
	
	_sleepButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[_sleepButton setFrame:viewFrame];
	_sleepButton.titleLabel.font = font;
	[_sleepButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self deviceSleepOn:[_device isSleepOn]];
	[_sleepButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -buttonSize.width, - buttonSize.height, 0)];
	titleSize = _sleepButton.titleLabel.frame.size;
	[_sleepButton setImageEdgeInsets:UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width)];
	_sleepButton.contentMode = UIViewContentModeCenter;
    [_sleepButton addTarget:self action:@selector(allButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_sleepButton];

	viewFrame.origin.x = self.view.frame.size.width - buttonSize.width - edgeInsets.right;
	viewFrame.origin.y = _handOrAutoButton.frame.origin.y;

    _childLockButton  = [UIButton buttonWithType:UIButtonTypeCustom];
	[_childLockButton setFrame:viewFrame];
	_childLockButton.titleLabel.font = font;
	[_childLockButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self deviceChildLockOn:[_device isChildLockOn]];
	[_childLockButton setTitleEdgeInsets:UIEdgeInsetsMake(0, -buttonSize.width, - buttonSize.height, 0)];
	titleSize = _childLockButton.titleLabel.frame.size;
	[_childLockButton setImageEdgeInsets:UIEdgeInsetsMake(-titleSize.height, 0, 0, -titleSize.width)];
	_childLockButton.contentMode = UIViewContentModeCenter;
	[_childLockButton addTarget:self action:@selector(allButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:_childLockButton];
	
    viewFrame.origin.x =  0;
    viewFrame.origin.y = bottomView.frame.size.height - 20;
    viewFrame.size.width = self.view.frame.size.width;
    viewFrame.size.height = 20;
	
    _leftTimerLabel = [[UILabel alloc] initWithFrame:viewFrame];
	_leftTimerLabel.font = [UIFont systemFontOfSize:13];
    [_leftTimerLabel setBackgroundColor:[UIColor clearColor]];
    [_leftTimerLabel setTextColor:[UIColor blackColor]];
    [_leftTimerLabel setTextAlignment:NSTextAlignmentCenter];
    [_leftTimerLabel setNumberOfLines:1];
    [bottomView addSubview:_leftTimerLabel];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scheduleDeviceOver) name:[[BLScheduleManager shared] scheduleNotificationIdentity] object:nil];

	_timer = [NSTimer scheduledTimerWithTimeInterval:scheduleRefreshInterval target:self selector:@selector(getDeviceStatus) userInfo:nil repeats:YES];
	[_timer fire];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)getDeviceStatus {
	[[BLAPIClient shared] getDeviceStatus:_device.ID withBlock:^(NSDictionary *attributes, NSError *error) {
		if (!error) {
			_device = [[ELDevice alloc] initWithAttributes:attributes];
			[self refreshELDevice];
		}
	}];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //插入定时数据
    BLTimerInfomation *timerInfomation = [BLTimerInfomation timerInfomation];
    if(timerInfomation) {
        //判断定时时间已经过去
        NSDate *datenow = [NSDate date];
        long currentSecond = (long)[datenow timeIntervalSince1970];
        if(currentSecond >= (timerInfomation.secondSince + timerInfomation.secondCount))
            return;
		_leftTimerLabel.hidden = NO;
		if(timerInfomation.switchState) {
            [_leftTimerLabel setText:[NSString stringWithFormat:@"%ld%@%ld%@%@",timerInfomation.secondCount / 3600,NSLocalizedString(@"hour", nil),(timerInfomation.secondCount % 3600) / 60,NSLocalizedString(@"minute", nil),NSLocalizedString(@"open", nil)]];
		} else {
            [_leftTimerLabel setText:[NSString stringWithFormat:@"%ld%@%ld%@%@",timerInfomation.secondCount / 3600,NSLocalizedString(@"hour", nil),timerInfomation.secondCount / 60,NSLocalizedString(@"minute", nil),NSLocalizedString(@"close", nil)]];
		}
    }
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:[[BLScheduleManager shared] scheduleNotificationIdentity] object:nil];
}

- (void)refreshELDevice {
	[self refreshButtons];
	[self refreshInsideAirQuality];
}

- (void)scheduleDeviceOver {
	_leftTimerLabel.hidden = YES;
}

- (void)refreshInsideAirQuality {
	NSMutableString *insideAirQuality = [NSMutableString stringWithString:[_device displayName]];
	[insideAirQuality appendFormat:@"\n%@", [_device displayPM25]];
	if ([_device hasTVOC]) {
		[insideAirQuality appendFormat:@"\n%@", [_device displayTVOC]];
	}
	_airQualityLabel.text = insideAirQuality;
}

- (void)refreshWeather
{
	_weatherLabel.text = [NSString stringWithFormat:@"%@ %@\n室外 PM:2.5 %@ug/m³ %@", _weather.cityName, _weather.temperateStrings, _weather.pm25, _weather.airQualityString];
	
	if(_weather.airQualityLevel.floatValue >= 4) {
		self.view.backgroundColor = [UIColor colorAirPolluted];
	} else {
		self.view.backgroundColor = [UIColor greenColor];
	}
}

- (void)deviceOn:(BOOL)on
{
	NSString *onOrOff = on ? @"power_on_1" : @"power_off";
	NSString *highlighted = on ? @"power_on_press" : @"power_off_press";
	[_switchButton setImage:[UIImage imageNamed:onOrOff] forState:UIControlStateNormal];
	[_switchButton setImage:[UIImage imageNamed:highlighted] forState:UIControlStateHighlighted];
	_switchButton.selected = on;
}

- (void)deviceAutoOn:(BOOL)on
{
	NSString *onOrOff = on ? @"auto_on" : @"hand_on";
	NSString *highlighted = on ? @"auto_on_press" : @"hand_on_press";
	[_handOrAutoButton setImage:[UIImage imageNamed:onOrOff] forState:UIControlStateNormal];
	[_handOrAutoButton setImage:[UIImage imageNamed:highlighted] forState:UIControlStateHighlighted];
	_handOrAutoButton.selected = on;
	NSString *title = on ? NSLocalizedString(@"Automatic", nil) : NSLocalizedString(@"Manual", nil);
	[_handOrAutoButton setTitle:title forState:UIControlStateNormal];
}

- (void)deviceSleepOn:(BOOL)on
{
	NSString *onOrOff = on ? @"night_on" : @"night_off";
	NSString *highlighted = on ? @"night_on_press" : @"night_off_press";
	[_sleepButton setImage:[UIImage imageNamed:onOrOff] forState:UIControlStateNormal];
	[_sleepButton setImage:[UIImage imageNamed:highlighted] forState:UIControlStateHighlighted];
	_sleepButton.selected = on;
	NSString *title = on ? NSLocalizedString(@"SleepOn", nil) : NSLocalizedString(@"SleepOff", nil);
	[_sleepButton setTitle:title forState:UIControlStateNormal];
}

- (void)deviceChildLockOn:(BOOL)on
{
	NSString *onOrOff = on ? @"lock_on" : @"lock_off";
	NSString *highlighted = on ? @"lock_on_press" : @"lock_off_press";
	[_childLockButton setImage:[UIImage imageNamed:onOrOff] forState:UIControlStateNormal];
	[_childLockButton setImage:[UIImage imageNamed:highlighted] forState:UIControlStateHighlighted];
	_childLockButton.selected = on;
	NSString *title = on ? NSLocalizedString(@"TheChildLock", nil) : NSLocalizedString(@"TheChildLockOff", nil);
	[_childLockButton setTitle:title forState:UIControlStateNormal];
}

- (void)refreshButtons {
	[self hideHUD:YES];
	[self deviceAutoOn:[_device isAutoOn]];
	[self deviceChildLockOn:[_device isChildLockOn]];
	[self deviceOn:[_device isOn]];
	_airQualityLabel.hidden = ![_device isOn];
	[self deviceSleepOn:[_device isSleepOn]];
}

//弹出视图
-(void)popUpView:(UIButton *)button {
    //背景
    [_backView setHidden:NO];
    _backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [_backView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:_backView];
    //加载layer
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    backButton.backgroundColor = [UIColor lightGrayColor];
    backButton.alpha = 0.5;
    [backButton addTarget:self action:@selector(buttonBackClick) forControlEvents:UIControlEventTouchUpInside];
    [_backView addSubview:backButton];
    
    //弹出视图
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 200, self.view.frame.size.width, 200)];
    view.backgroundColor = [UIColor whiteColor];
    CGRect zeroRect = CGRectZero;
    //头部
	zeroRect.origin.x = 0;
	zeroRect.origin.y =20;
	zeroRect.size.width = self.view.frame.size.width;
	zeroRect.size.height = 30;
	UILabel *label = [[UILabel alloc] initWithFrame:zeroRect];
	label.backgroundColor = [UIColor clearColor];
	[label setText:NSLocalizedString(@"speedSelection", nil)];
	[label setTextAlignment:NSTextAlignmentCenter];
	[label setTextColor:RGB(38, 154, 252)];
	[label setBackgroundColor:[UIColor clearColor]];
	[view addSubview:label];
	
	//加热
	UIImage *image = [UIImage imageNamed:@"point3"];
	UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(40, label.frame.size.height+label.frame.origin.y, self.view.frame.size.width - 80, 120)];
	[slider setBackgroundColor:[UIColor clearColor]];
	[slider setMaximumTrackTintColor:[UIColor grayColor]];
	[slider setMinimumTrackTintColor:RGB(0x13, 0xb3, 0x5c)];
	[slider setMaximumValue:[_device windSpeedStepperNumber]];
	[slider setMinimumValue:1.0f];
	[slider setValue:[_device windSpeed]];
	image = [UIImage imageNamed:@"seekbar_btn"];
	[slider setThumbImage:image forState:UIControlStateNormal];
	[slider setTag:3];
	[slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventTouchUpInside];
	UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)];
	[slider addGestureRecognizer:gr];
	[view addSubview:slider];
	
	CATransition *animation = [CATransition animation];
	animation.duration = 0.3f;   //时间间隔
	animation.timingFunction = UIViewAnimationCurveEaseInOut;
	animation.fillMode = kCAFillModeForwards;
	animation.type = kCATransitionMoveIn;         //动画效果
	animation.subtype = kCATransitionFromTop;   //动画方向
	[view.layer addAnimation:animation forKey:@"animation"];
	
	CGFloat gap = 110;
	if ([_device windSpeedStepperNumber] == 5) {
		gap = 55;
	}
	for (int i = 0; i < [_device windSpeedStepperNumber]; i++) {
		label = [[UILabel alloc] initWithFrame:CGRectMake(40 + i * gap, slider.frame.origin.y + 85, 70, 30)];
		[label setText:[NSString stringWithFormat:@"%@%@", @(i+1), NSLocalizedString(@"档", nil)]];
		[label setBackgroundColor:[UIColor clearColor]];
		[label setFont:[UIFont systemFontOfSize:13.f]];
		[view addSubview:label];
	}
	[_backView addSubview:view];
}

//阴影点击
-(void)buttonBackClick
{
    //点击阴影的情况
    [_backView removeFromSuperview];
    [_backView setHidden:YES];
}

//定时任务点击
-(void)timerButtonClick
{
    //定时界面
    BLFilterViewController *filterInfoViewController = [[BLFilterViewController alloc] initWithNibName:nil bundle:nil];
//	filterInfoViewController.receivedData = self.receivedData;
//	filterInfoViewController.device = self.device;
    [self.navigationController pushViewController:filterInfoViewController animated:YES];
}

//风速按钮点击
-(void)speedButtonClick:(UIButton *)button
{
    //如果儿童锁按钮点击，那么提示信息
    if(_childLockButton.selected) {
        //提示信息
		[self displayHUDTitle:NSLocalizedString(@"childMessage", nil) message:nil duration:3];
        return;
    }
    //如果自动按钮点击，那么提示信息
   else if(_handOrAutoButton.selected) {
        //提示信息
	   [self displayHUDTitle:NSLocalizedString(@"autoMessage", nil) message:nil duration:3];
        return;
    } else {
          //弹出选择框
        [self popUpView:button];
    }
}

//返回按钮
-(void)leftButtonClick
{
    [self.navigationController popViewControllerAnimated:YES];
}

//进入关于页面
-(void)rightButtonClick:(UIButton *)button
{
    BLAboutViewController *aboutViewControl = [[BLAboutViewController alloc] init];
    [self.navigationController pushViewController:aboutViewControl animated:YES];
}

- (void)allButtonClicked:(UIButton *)button
{
	if (!_switchButton.selected && button != _switchButton) {
		[self displayHUDTitle:nil message:@"设备已关机，不能进行其他操作" duration:3];
		return;
	}
	
	if (_childLockButton.selected && button != _childLockButton) {
		[self displayHUDTitle:nil message:NSLocalizedString(@"childMessage", nil) duration:3];
		return;
	}
	
	NSString *base64 = nil;
	if (button == _switchButton) {
		base64 = [_device commandOn:!button.selected];
	} else if (button == _handOrAutoButton) {
		base64 = [_device commandAutoOn:!button.selected];
	} else if (button == _sleepButton) {
		base64 = [_device commandSleepOn:!button.selected];
	} else if (button == _childLockButton) {
		base64 = [_device commandChildLockOn:!button.selected];
	}

	if (base64) {
		[self displayHUD:NSLocalizedString(@"加载中...", nil)];
		[[BLAPIClient shared] command:_device.ID value:base64 withBlock:^(NSString *value, NSError *error) {
			[self hideHUD:YES];
			if (!error) {
				_device.value = value;
				[self refreshButtons];
			} else {
				[self displayHUDTitle:@"错误" message:error.userInfo[BL_ERROR_MESSAGE_IDENTIFIER]];
			}
		}];
	}
	return;
}

- (void)sliderValueChanged:(UISlider *)slider
{
    int index = (int)(slider.value + 0.5); // Round the number.
    [slider setValue:index animated:YES];
    [self setWindSpeed:index];
}

- (void)sliderTapped:(UIGestureRecognizer *)g
{
    UISlider *s = (UISlider *)g.view;
    if (s.highlighted)
        return; // tap on thumb, let slider deal with it
    CGPoint pt = [g locationInView: s];
    CGFloat percentage = pt.x / s.bounds.size.width;
    CGFloat delta = percentage * (s.maximumValue - s.minimumValue);
    CGFloat value = s.minimumValue + delta + 0.5f;
	NSLog(@"value: %@", @(value));
    [s setValue:(int)value animated:YES];
    [self setWindSpeed:(int)value];
}

- (void)setWindSpeed:(int)speed
{
    static int old = 0;
    if (old == speed)
        return;
    old = speed;
	[self displayHUD:NSLocalizedString(@"加载中...", nil)];
	
	NSLog(@"set wind speed: %d", speed);
	
	NSString *base64 = [_device commandWindSpeed:speed];
	[[BLAPIClient shared] command:_device.ID value:base64 withBlock:^(NSString *value, NSError *error) {
		
	}];
}

- (void)share
{
	_shareViewController = [[BLShareViewController alloc] init];
	[_shareViewController shareWithImage:[self.view captureIntoImage]];
}

#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	_currentLocation = locations[0];
	[[[CLGeocoder alloc] init] reverseGeocodeLocation:_currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
		if (!error && placemarks.count) {
			CLPlacemark *placemark = placemarks[0];
			_weather.cityName = [[[placemark.addressDictionary objectForKey:@"City"] componentsSeparatedByString:@"市"] objectAtIndex:0];
			_weather.cityCode = [[[NSString citiesCodeString] objectFromJSONString] objectForKey:[[_weather.cityName componentsSeparatedByString:@"市"] objectAtIndex:0]];
			//如果名称不相同则一般为英文
			if(_weather.cityCode.length) {
				[self getWeather];
			} else {
				[self getCityInfo];
			}
		} else {
			NSLog(@"No results were returned.");
		}
	}];
	[manager stopUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"location manager error: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	if (status == kCLAuthorizationStatusDenied) {
		[manager stopUpdatingLocation];
	} else {
		[manager startUpdatingLocation];
	}
}

-(void)getCityInfo
{
    dispatch_async(_httpQueue, ^{
        //百度接口取得地图上面的点
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://api.map.baidu.com/geocoder?output=json&location=%f,%f&key=37492c0ee6f924cb5e934fa08c6b1676", _currentLocation.coordinate.latitude, _currentLocation.coordinate.longitude]];
        NSError *error;
        NSString *jsonString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
        SBJsonParser *parser = [[SBJsonParser alloc]init];
        NSDictionary *rootDic = [parser objectWithString:jsonString error:&error];
        NSDictionary *weatherInfo = [rootDic objectForKey:@"result"];
		_weather.cityName = [[[[weatherInfo objectForKey:@"addressComponent"] objectForKey:@"city"] componentsSeparatedByString:@"市"] objectAtIndex:0];
		_weather.cityCode = [[[NSString citiesCodeString] objectFromJSONString] objectForKey:[[_weather.cityName componentsSeparatedByString:@"市"] objectAtIndex:0]];
		if(_weather.cityCode.length) {
			[self getWeather];
		}
    });
}

//天气接口
- (void)getWeather
{
    dispatch_async(_httpQueue, ^{
		NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://tqapi.mobile.360.cn/app/meizu/city/%@", _weather.cityCode]];
		NSError *error;
		NSString *jsonString = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];
		SBJsonParser *parser = [[SBJsonParser alloc]init];
		NSDictionary *rootDic = [parser objectWithString:jsonString error:&error];
		
		NSMutableString *temperature = [NSMutableString stringWithString:@""];
		NSDictionary *weatherOfToday = rootDic[@"weather"][0];
		NSArray *nightInfomation = weatherOfToday[@"info"][@"night"];
		NSArray *dayInfomation = weatherOfToday[@"info"][@"day"];
		if (nightInfomation.count >= 3 && dayInfomation.count >= 3) {
			[temperature appendString:nightInfomation[2]];
			[temperature appendString:@"~"];
			[temperature appendString:dayInfomation[2]];
			[temperature appendString:@"℃"];
		}
		_weather.temperateStrings = temperature;
		
		NSDictionary *pm25Information = rootDic[@"pm25"];
		if (pm25Information) {
			NSString *pm25 = [NSString stringWithFormat:@"%@", pm25Information[@"pm25"]];
			_weather.pm25 = pm25;
			_weather.airQualityString = pm25Information[@"quality"];
			_weather.airQualityLevel = [NSString stringWithFormat:@"%@", pm25Information[@"level"]];
			_weather.airQualityColorHexString = pm25Information[@"color"];
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			[self refreshWeather];
		});
    });
}
@end
