//
//  BLUserInfo.h
//  BeiAngAir
//
//  Created by zhangbin on 1/5/15.
//  Copyright (c) 2015 BroadLink. All rights reserved.
//

#import "ZBModel.h"

@interface BLUserInfo : ZBModel

@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *nickname;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *sex;

@end
