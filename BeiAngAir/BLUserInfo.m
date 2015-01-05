//
//  BLUserInfo.m
//  BeiAngAir
//
//  Created by zhangbin on 1/5/15.
//  Copyright (c) 2015 BroadLink. All rights reserved.
//

#import "BLUserInfo.h"

@implementation BLUserInfo

- (instancetype)initWithAttributes:(NSDictionary *)attributes {
	self = [super initWithAttributes:attributes];
	if (self) {
		_email = [attributes[@"email"] notNull];
		_nickname = [attributes[@"nick_name"] notNull];
		_phone = [attributes[@"phone"] notNull];
		_sex = [attributes[@"sex"] notNull];
	}
	return self;
}

@end
