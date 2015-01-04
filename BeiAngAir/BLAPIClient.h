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
- (BOOL)phoneNumberSimpleValidation:(NSString *)string;
- (NSString	*)appVersion;
- (BOOL)isSessionValid;
- (NSString *)username;
- (NSString *)userID;
- (void)registerAccount:(NSString *)account password:(NSString *)password withBlock:(void (^)(NSError *error))block;
- (void)registerPhone:(NSString *)phone password:(NSString *)password code:(NSString *)code withBlock:(void (^)(NSError *))block;

- (void)authCodeWithPhone:(NSString *)phone withBlock:(void (^)(NSError *error))block;
- (void)signinAccount:(NSString *)account password:(NSString *)password withBlock:(void (^)(NSError *error))block;
- (void)resetPassword:(NSString *)password phone:(NSString *)phone code:(NSString *)code withBlock:(void (^)(NSError *error))block;

- (void)getBindWithBlock:(void (^)(NSArray *multiAttributes, NSError *error))block;
- (void)getDeviceStatus:(NSString *)deviceID withBlock:(void (^)(NSDictionary *attributes, NSError *error))block;
- (void)command:(NSString *)deviceID value:(NSString *)value withBlock:(void (^)(NSString *value, NSError *error))block;
- (void)getBindResultWithBlock:(void (^)(BOOL newDeviceFound, NSError *error))block;
- (void)updateAuthorize:(NSString *)deviceID role:(NSString *)role nickename:(NSString *)nickname withBlock:(void (^)(NSError *error))block;
- (void)unbindDevice:(NSString *)deviceID withBlock:(void (^)(NSError *error))block;
- (void)authorizeDevice:(NSString *)deviceID role:(NSString *)role withBlock:(void (^)(NSError *error))block;
- (void)getDeviceData:(NSString *)deviceID withBlock:(void (^)(BOOL validForReset, NSError *error))block;
- (void)resetDevice:(NSString *)deviceID withBlock:(void (^)(NSError *error))block;
- (void)logoutWithBlock:(void (^)(NSError *error))block;

@end
