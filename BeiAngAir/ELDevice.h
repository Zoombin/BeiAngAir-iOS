//
//  ELDevice.h
//  BeiAngAir
//
//  Created by zhangbin on 11/24/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "ZBModel.h"

@interface ELDevice : ZBModel

@property (nonatomic, strong) NSString *status;
@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) NSString *role;
@property (nonatomic, strong) NSString *value;

- (BOOL)isOnline;
- (NSString *)deviceName;
- (UIImage *)avatar;
- (NSString *)displayStatus;
- (NSString *)displayName;
- (NSNumber *)hours;
- (NSNumber *)minutes;
- (BOOL)isOn;
- (BOOL)isAutoOn;
- (BOOL)isSleepOn;
- (BOOL)isChildLockOn;
- (BOOL)is280E;
- (BOOL)isJY300;
- (BOOL)isJY500;
- (BOOL)hasTVOC;
- (NSInteger)windSpeedStepperNumber;
- (NSInteger)windSpeed;
- (NSString *)displayTVOC;
- (NSString *)displayPM25;
- (NSString *)commandOn:(BOOL)on;
- (NSString *)commandAutoOn:(BOOL)on;
- (NSString *)commandSleepOn:(BOOL)on;
- (NSString *)commandChildLockOn:(BOOL)on;
- (NSString *)commandWindSpeed:(NSInteger)speed;
- (BOOL)isOwner;

@end
