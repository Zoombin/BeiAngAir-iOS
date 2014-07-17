//
//  WifiInfo.h
//  BeiAngAir
//
//  Created by zhangbin on 7/11/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Wifi : NSObject

@property (nonatomic, strong) NSString *SSID;
@property (nonatomic, strong) NSString *password;

- (void)persistence;
+ (instancetype)wifiWithSSID:(NSString *)SSID;

@end
