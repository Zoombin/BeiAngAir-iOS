//
//  BeiAngReceivedDataInfo.m
//  BeiAngAir
//
//  Created by zhangbin on 7/10/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BeiAngReceivedData.h"

@implementation BeiAngReceivedData

- (instancetype)initWithData:(NSArray *)data
{
	self = [super init];
	if (self) {
		//设置开关状态: 00 关机  01 打开
		[self setSwitchStatus:[data[4] intValue]];
		//手动自动状态: 00 手动状态  01 自动状态
		[self setAutoOrHand:[data[5] intValue]];
		//净化器运行档位状态: 00 0档位 01 1档 0x02 02 2档 03 3档
		[self setGearState:[data[6] intValue]];
		//睡眠状态: 00 不在睡眠状态  01睡眠状态
		[self setSleepState:[data[7] intValue]];
		//儿童锁状态: 00 不在儿童锁状态 01儿童锁状态
		[self setChildLockState:[data[8] intValue]];
		//设备类型: 01：280B。02：280C.03:车载04:AURA100.
		[self setDeviceType:[data[2] intValue]];
		//电极运行时间: 第一位为小时数
		[self setRunHours:[data[9] intValue]];
		//电极运行时间:第二位为分钟数(0x13,0x18:19小时24分钟)
		[self setRunMinutes:[data[10] intValue]];
		//空气质量档位: 01：一档，好。02：二档，中。03：三档，差
		[self setAirQualityGear:[data[11] intValue]];
		//空气质量原始数据: 数据
		[self setAirQualityData:[data[12] intValue]];
		[self setAirQualityDataB:[data[13] intValue]];
		//光照状态: 01：亮，02：昏暗，03：黑
		[self setLightCondition:[data[14] intValue]];
		//维护状态: 01：清洗电极，02：需要检查电极状态并断电重启
		[self setMaintenancesState:[data[15] intValue]];
		//温度: 带符号数：-127~127(0x8c:-12℃,0x12:18℃)
		[self setTemperature:[data[16] intValue]];
		//湿度: 不带符号数，0~100(0x39:57%)
		[self setHumidity:[data[17] intValue]];
	}
	return self;
}

- (NSNumber *)airQuality
{
	//这个1500, 30,20是贝昂给的系数
	NSInteger quality = _airQualityData * 256 + _airQualityDataB;
	if (quality > 1500) {
		return @(quality / 30);
	} else {
		return @(quality / 20);
	}
}

- (NSString *)airQualityDisplayString {
	//这个也是参照贝昂安卓的公式
	if ([self airQuality].floatValue >= 200) {
		return NSLocalizedString(@"严重", nil);
	} else if ([self airQuality].floatValue >= 150) {
		return NSLocalizedString(@"差", nil);
	} else if ([self airQuality].floatValue >= 100) {
		return NSLocalizedString(@"中", nil);
	} else if ([self airQuality].floatValue >= 50) {
		return NSLocalizedString(@"良", nil);
	}
	return NSLocalizedString(@"优", nil);
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"< switchState: %d, airQualityData: %d, airQualityDataB: %d >", self.switchStatus, _airQualityData, _airQualityDataB];
}

@end
