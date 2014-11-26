//
//  BLAPIClient.h
//  BeiAngAir
//
//  Created by zhangbin on 11/24/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

extern NSString * const BL_ERROR_MESSAGE_IDENTIFIER;

@interface BLAPIClient : AFHTTPRequestOperationManager

+ (instancetype)shared;
- (BOOL)isSessionValid;
- (NSString *)userID;
- (void)registerAccount:(NSString *)account password:(NSString *)password withBlock:(void (^)(NSError *error))block;

- (void)signinAccount:(NSString *)account password:(NSString *)password withBlock:(void (^)(NSError *error))block;

- (void)getBindWithBlock:(void (^)(NSArray *multiAttributes, NSError *error))block;
- (void)getDeviceStatus:(NSNumber *)deviceID withBlock:(void (^)(NSDictionary *attributes, NSError *error))block;
- (void)command:(NSNumber *)deviceID value:(NSString *)value withBlock:(void (^)(NSString *value, NSError *error))block;

@end
