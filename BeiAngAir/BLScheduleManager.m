//
//  BLScheduleManager.m
//  BeiAngAir
//
//  Created by zhangbin on 7/28/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BLScheduleManager.h"
#import "JSONKit.h"

static NSString *_MAC;

@implementation BLScheduleManager

+ (instancetype)shared
{
	static BLScheduleManager *instance;
	if (!instance) {
		instance = [[BLScheduleManager alloc] init];
	}
	return instance;
}

- (NSString *)scheduleNotificationIdentity
{
	return @"scheduleDeviceOver";
}

- (void)scheduleOnOrOff:(BOOL)onOrOff afterDelay:(NSTimeInterval)timeInterval MAC:(NSString *)MAC;
{
	_MAC = MAC;
	[self performSelector:@selector(onOrOff:) withObject:onOrOff ? @(1) : @(0) afterDelay:timeInterval];
}

- (void)onOrOff:(NSNumber *)switchStatus
{
//	dispatch_queue_t networkQueue = dispatch_queue_create("BLAppDelegateNetworkQueue", DISPATCH_QUEUE_SERIAL);
//	dispatch_async(networkQueue, ^{
//		NSDictionary *dictionary = [NSDictionary dictionaryPassthroughWithMAC:_MAC switchStatus:switchStatus];
//		NSData *sendData = [dictionary JSONData];
//		int code = [[[response objectFromJSONData] objectForKey:@"code"] intValue];
//		if (code == 0) {
//			[[NSNotificationCenter defaultCenter] postNotificationName:[self scheduleNotificationIdentity] object:nil];
//			NSLog(@"控制机器定时%@成功", [switchStatus boolValue] ? @"开启" : @"关闭");
//		}
//	});
}


@end
