//
//  ELDevice.m
//  BeiAngAir
//
//  Created by zhangbin on 11/24/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "ELDevice.h"
#import "CocoaSecurity.h"

NSInteger const onFlagIndex = 4;
NSInteger const autoOnFlagIndex = 5;
NSInteger const windSpeedFlagIndex = 6;
NSInteger const sleepFlagIndex = 7;
NSInteger const childLockFlagIndex = 8;
NSInteger const hoursFlagIndex = 9;
NSInteger const minutesFlagIndex = 10;
NSInteger const PM25FlagIndexHigh = 12;
NSInteger const PM25FlagIndexLow = 13;
NSInteger const TVOCFlagIndex = 18;

@implementation ELDevice

- (instancetype)initWithAttributes:(NSDictionary *)attributes {
	self = [super initWithAttributes:attributes];
	if (self) {
		if (attributes[@"devicestatus"]) {
			_status = [NSString stringWithFormat:@"%@", attributes[@"devicestatus"]];
		}
		if (attributes[@"ndevice_id"]) {
			_ID = [NSString stringWithFormat:@"%@", attributes[@"ndevice_id"]];
		}
		if (attributes[@"nick_name"]) {
			_nickname = [NSString stringWithString:attributes[@"nick_name"]];
		}
		if (!_nickname.length) {
			_nickname = NSLocalizedString(@"贝昂", nil);
		}
		if (attributes[@"role"]) {
			_role = [NSString stringWithFormat:@"%@", attributes[@"role"]];
		}
		if (attributes[@"value"]) {
			_value = [NSString stringWithFormat:@"%@", attributes[@"value"]];
		}
		
		if ([self isOnline]) {
			if (_value.length) {
				NSString *deviceName = [self deviceName];
				if (deviceName.length) {
					[[NSUserDefaults standardUserDefaults] setObject:deviceName forKey:[NSString stringWithFormat:@"%@", _ID]];
					[[NSUserDefaults standardUserDefaults] synchronize];
				}
			}
		}
	}
	return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<id:%@, value:%@>", _ID, _value];
}

- (BOOL)isOnline {
	return [_status isEqualToString:@"online"];
}

- (NSString *)deviceName {
	uint8_t flag = [self flagAtIndex:3];//第4位表示设备类型
	NSDictionary *names = @{@(1) : @"280B",
							@(2) : @"280E",
							@(3) : @"CAR",
							@(4) : @"AURA100",
							@(5) : @"JY300",
							@(6) : @"JY500",
							@(8) : @"JY300S",
							@(160) : @"Airdog",
							@(80) : @"TAir"
							};
	
	NSString *name = names[@(flag)];
	if (!name.length) {
		name = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@", _ID]];
	}
	return name;
}

- (UIImage *)avatar {
	NSString *imageName = @"item_icon_default";
	NSDictionary *names = @{
							@"280E" : @"item_icon_280e",
							@"CAR" : @"item_icon_car",
							@"JY300" : @"item_icon_jy300",
							@"JY300S" : @"item_icon_jy300",
							@"Airdog" : @"item_icon_airdog",
							@"AURA100" : @"item_icon_desktop"
							};
	
	NSString *name = names[[self deviceName]];
	if (name) {
		imageName = name;
	}
	return [UIImage imageNamed:imageName];
}

- (NSString *)displayStatus {
	if ([self isOnline]) {
		return NSLocalizedString(@"设备正在运行", nil);
	}
	return NSLocalizedString(@"设备不在线", nil);
}

- (NSString *)displayName {
	NSMutableString *displayName = [NSMutableString stringWithString:_nickname];
	if ([self deviceName].length) {
		[displayName appendFormat:@"  (%@)", [self deviceName]];
	}
	return displayName;
}

- (NSNumber *)hours {
	return @([self flagAtIndex:hoursFlagIndex]);
}

- (NSNumber *)minutes {
	return @([self flagAtIndex:minutesFlagIndex]);
}

- (uint8_t *)dataBuffer {
	CocoaSecurityDecoder *decoder = [[CocoaSecurityDecoder alloc] init];
	NSData *data = [decoder base64:_value];
	uint8_t *dataBuffer = (uint8_t *)[data bytes];
	return dataBuffer;
}

- (uint8_t)flagAtIndex:(NSInteger)index {
	if (!_value.length) return 0;
	uint8_t *dataBuffer = [self dataBuffer];
	uint8_t flag = dataBuffer[index];
	return flag;
}

- (NSString *)setValueFlag:(uint8_t)flag atIndex:(NSInteger)index {
	if (!_value.length) return nil;
	uint8_t *dataBuffer = [self dataBuffer];
	dataBuffer[index] = flag;
	dataBuffer[1] = 0x41;//0x41是控制机器的指令
	
	NSData *data = [[NSData alloc] initWithBytes:dataBuffer length:25];//TODO: hardcode length
	CocoaSecurityEncoder *encoder = [[CocoaSecurityEncoder alloc] init];
	NSString *base64 = [encoder base64:data];
	return base64;
}

- (BOOL)isOn {
	return [self flagAtIndex:onFlagIndex] > 0;
}

- (BOOL)isAutoOn {
	return [self flagAtIndex:autoOnFlagIndex] > 0;
}

- (BOOL)isSleepOn {
	return [self flagAtIndex:sleepFlagIndex] > 0;
}

- (BOOL)isChildLockOn {
	return [self flagAtIndex:childLockFlagIndex] > 0;
}

- (BOOL)is280E {
	if ([[self deviceName].uppercaseString isEqualToString:@"280E"]) {
		return YES;
	}
	return NO;
}

- (BOOL)isJY300 {
	if ([[self deviceName].uppercaseString isEqualToString:@"JY300"]) {
		return YES;
	}
	return NO;
}

- (BOOL)isJY500 {
	if ([[self deviceName].uppercaseString isEqualToString:@"JY500"]) {
		return YES;
	}
	return NO;
}

- (BOOL)hasTVOC {
	if ([self is280E]) return NO;
	return YES;
}

- (NSInteger)windSpeedStepperNumber {
	if ([self isJY500]) return 5;
	return 3;
}

- (NSInteger)windSpeed {
	return [self flagAtIndex:windSpeedFlagIndex];
}

- (NSString *)displayTVOC {
	uint8_t flag = [self flagAtIndex:TVOCFlagIndex];
	NSString *quanlity = NSLocalizedString(@"差", nil);
	
	if ([self isJY500]) {
		if (flag == 1) {
			quanlity = NSLocalizedString(@"优", nil);
		} else if (flag == 2) {
			quanlity = NSLocalizedString(@"良", nil);
		} else if (flag == 3) {
			quanlity = NSLocalizedString(@"中", nil);
		}
	} else {
		if (flag == 1) {
			quanlity = NSLocalizedString(@"优", nil);
		} else if (flag == 2) {
			quanlity = NSLocalizedString(@"良", nil);
		}
	}
	return [NSString stringWithFormat:@"TVOC %@", quanlity];
}

- (NSString *)displayPM25 {
	uint8_t	high = [self flagAtIndex:PM25FlagIndexHigh];//12
	uint8_t low = [self flagAtIndex:PM25FlagIndexLow];//13
	NSInteger flag = high * 256 + low;
	if ([self is280E]) {
		flag = (flag / 30.0f) + 8;
	}
	NSString *quanlity = NSLocalizedString(@"优", nil);
	if (flag >= 200) {
		quanlity = NSLocalizedString(@"严重", nil);
	} else if (flag >= 150) {
		quanlity = NSLocalizedString(@"差", nil);
	} else if (flag >= 100) {
		quanlity = NSLocalizedString(@"中", nil);
	} else if (flag >= 50) {
		quanlity = NSLocalizedString(@"良", nil);
	}
	return [NSString stringWithFormat:@"室内 PM2.5 %dug/m³ %@", flag, quanlity];
}

- (NSString *)commandOn:(BOOL)on {
	return [self setValueFlag:on ? 1 : 0 atIndex:onFlagIndex];
}

- (NSString *)commandAutoOn:(BOOL)on {
	return [self setValueFlag:on ? 1 : 0 atIndex:autoOnFlagIndex];
}

- (NSString *)commandSleepOn:(BOOL)on {
	return [self setValueFlag:on ? 1 : 0 atIndex:sleepFlagIndex];
}

- (NSString *)commandChildLockOn:(BOOL)on {
	return [self setValueFlag:on ? 1 : 0 atIndex:childLockFlagIndex];
}

- (NSString *)commandWindSpeed:(NSInteger)speed {
	return [self setValueFlag:speed atIndex:windSpeedFlagIndex];
}

- (BOOL)isOwner {
	return ([_role isEqualToString:@"owner"] || [_role isEqualToString:@"admin"]);
}

@end
