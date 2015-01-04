//
//  BLAPIClient.m
//  BeiAngAir
//
//  Created by zhangbin on 11/24/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BLAPIClient.h"
#import "CocoaSecurity.h"

NSString * const BL_ERROR_DOMAIN = @"BL_ERROR_DOMAIN";
NSString * const BL_ERROR_MESSAGE_IDENTIFIER = @"BL_ERROR_MESSAGE_IDENTIFIER";
NSString * const EASY_LINK_USER_ID_IDENTIFIER = @"EASY_LINK_USER_ID_IDENTIFIER";
NSString * const EASY_LINK_USER_NAME_IDENTIFIER = @"EASY_LINK_USER_NAME_IDENTIFIER";
NSString * const EASY_LINK_TOKEN_IDENTIFIER = @"EASY_LINK_TOKEN_IDENTIFIER";
NSString * const EASY_LINK_API_KEY = @"34b9a684f1fd61194026d92b7cf2a11c";
NSString * const EASY_LINK_API_SECRET = @"dc52bdb7601eafb7fa580e000f8d293f";

@interface BLAPIClient ()

@property (readwrite) NSInteger apiRequestCount;

@end

@implementation BLAPIClient

+ (instancetype)shared;
{
	static BLAPIClient *_shared = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *baseURLString = @"http://p.smart.99.com/v1/";
		NSURL *url = [NSURL URLWithString:baseURLString];
		_shared = [[BLAPIClient alloc] initWithBaseURL:url];
		NSMutableSet *types = [_shared.responseSerializer.acceptableContentTypes mutableCopy];
		[types addObject:@"text/plain"];
		[types addObject:@"text/html"];
		_shared.responseSerializer.acceptableContentTypes = types;
		_shared.securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
	});
	return _shared;
}

- (NSString	*)appVersion {
	NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
	return [infoDictionary objectForKey:@"CFBundleShortVersionString"];
}

- (BOOL)isSessionValid {
	return [self userID].length > 0;
}

- (void)saveUserID:(NSString *)userID {
	if (userID) {
		[[NSUserDefaults standardUserDefaults] setObject:userID forKey:EASY_LINK_USER_ID_IDENTIFIER];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (void)saveUsername:(NSString *)username {
	if (username) {
		[[NSUserDefaults standardUserDefaults] setObject:username forKey:EASY_LINK_USER_NAME_IDENTIFIER];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (NSString *)userID {
	NSString *userID = [[NSUserDefaults standardUserDefaults] objectForKey:EASY_LINK_USER_ID_IDENTIFIER];
	return userID ?: @"";
}

- (NSString *)username {
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:EASY_LINK_USER_NAME_IDENTIFIER];
	return username ?: @"";
}

- (void)logout {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:EASY_LINK_USER_ID_IDENTIFIER];
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:EASY_LINK_USER_NAME_IDENTIFIER];
}

- (void)saveToken:(NSString *)token {
	if (token) {
		[[NSUserDefaults standardUserDefaults] setObject:token forKey:EASY_LINK_TOKEN_IDENTIFIER];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (NSString *)token {
	NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:EASY_LINK_TOKEN_IDENTIFIER];
	return token ?: @"";
}

- (NSString *)dataTOJSONString:(id)object {
	NSString *string = nil;
	NSError *error;
	NSData *data = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:&error];
	if (!data) {
		NSLog(@"dataTOJSONString error: %@", error);
	} else {
		string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	}
	return string;
}

- (NSError *)handleResponse:(id)responseObject {
	NSError *error = nil;
	NSDictionary *result = [responseObject valueForKeyPath:@"result"];
	NSInteger code = [result[@"code"] integerValue];
	NSDictionary *errorCodes = @{@(5000) : @"发送短信失败",
//								 @(5001) : @"短信已发送",
								 @(5002) : @"手机号码格式不对",
								 @(5003) : @"token错误",
								 @(5004) : @"用户名错误",
								 @(5005) : @"密码错误",
								 @(5006) : @"用户名不存在",
								 @(1002) : @"参数不足",
								 @(5007) : @"用户未登录",
								 @(5008) : @"请求有误",
								 @(5009) : @"系统错误",
								 @(5010) : @"未绑定手机",
								 @(5011) : @"密码格式错误",
								 @(5012) : @"手机与账号不符合",
								 @(5013) : @"密码相同，无需修改",
								 @(5014) : @"手机号码已经绑定",
								 @(5015) : @"验证码未发出",
								 @(5016) : @"验证码不对",
								 @(5017) : @"用户已经登入",
								 @(5018) : @"用户名格式不对",
								 @(5019) : @"方法未实现",
								 @(5020) : @"用户名已经存在",
								 @(5021) : @"设备不存在",
								 @(5022) : @"第三方接口未开放",
								 @(5023) : @"第三方登入失败",
								 @(6000) : @"控制超时",
								 @(6002) : @"token过期",
								 @(6001) : @"设备不在线",
								 @(611) : @"该设备已和其它账号绑定",
								 @(2102) : @"已绑定过该设备"
								 };
	
	
	if (code != 0 && code != 200) {
		NSString *message = result[@"message"];
		if (!message || [message isEqual:[NSNull null]]) {
			message = NSLocalizedString(@"未知错误", nil);
		}
		
		NSString *errorMessage = errorCodes[@(code)];
		if (errorMessage) {
			message = errorMessage;
		}
		
		error = [NSError errorWithDomain:BL_ERROR_DOMAIN code:1 userInfo:@{BL_ERROR_MESSAGE_IDENTIFIER : message}];
	}
	return error;
}

- (NSDictionary *)addSystemParametersRequestEmpty:(BOOL)empty signUserID:(BOOL)signIncludingUserID {
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	parameters[@"id"] = @(++_apiRequestCount);
	
	NSInteger timestamp = (NSInteger)[[NSDate date] timeIntervalSince1970];
	NSString *sign = nil;
	sign = [self signWithTimestamp:timestamp signUserID:signIncludingUserID];
	parameters[@"system"] = @{@"time" : [NSString stringWithFormat:@"%d", timestamp],
							  @"jsonrpc" : @(2.0),
							  @"version" : @(1.0),
							  @"key" : EASY_LINK_API_KEY,
							  @"sign" : sign
							  };
	
	parameters[@"request"] = @{@"token" : empty ? @"" : [self token],
							   @"user_id" : empty ? @"" : [self userID]
							   };
	return parameters;
}

- (NSString *)signWithTimestamp:(NSInteger)timestamp signUserID:(BOOL)signIncludingUserID {
	NSMutableString *string = [NSMutableString stringWithFormat:@"%@%@%@", EASY_LINK_API_KEY, @(timestamp), EASY_LINK_API_SECRET];
	if (signIncludingUserID) {
		string = [NSMutableString stringWithFormat:@"%@%@%@%@%@", EASY_LINK_API_KEY, @(timestamp), [self userID], [self token], EASY_LINK_API_SECRET];
	}
	CocoaSecurityResult *md5 = [CocoaSecurity md5:string];
	return md5.hexLower;
}

- (void)registerAccount:(NSString *)account password:(NSString *)password withBlock:(void (^)(NSError *error))block {
	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:YES signUserID:NO] mutableCopy];
	parameters[@"method"] = @"register";
	CocoaSecurityResult *md5 = [CocoaSecurity md5:password];
	parameters[@"params"] = @{@"password" : md5.hexLower,
							  @"user_name" : account,
							  };
	NSString *JSONString = [self dataTOJSONString:parameters];
	[self POST:@"account" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = [self handleResponse:responseObject];
		if (block) block(error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(error);
	}];
}

- (void)signinAccount:(NSString *)account password:(NSString *)password withBlock:(void (^)(NSError *error))block {
	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:YES signUserID:NO] mutableCopy];
	parameters[@"method"] = @"login";
	CocoaSecurityResult *md5 = [CocoaSecurity md5:password];
	parameters[@"params"] = @{@"password" : md5.hexLower,
							  @"user_name" : account,
							  };
	NSString *JSONString = [self dataTOJSONString:parameters];
	[self POST:@"account" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = [self handleResponse:responseObject];
		NSDictionary *result = [responseObject valueForKeyPath:@"result"];
		if (!error) {
			[self saveUserID:result[@"data"][@"user_id"]];
			[self saveUsername:account];
			[self saveToken:result[@"data"][@"token"]];
		}
		if (block) block(error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(error);
	}];
}

- (void)getBindWithBlock:(void (^)(NSArray *multiAttributes, NSError *error))block {
	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:NO signUserID:YES] mutableCopy];
	parameters[@"method"] = @"getBind";
	parameters[@"params"] = @{@"user_id" : [self userID]};
	NSString *JSONString = [self dataTOJSONString:parameters];
	[self POST:@"homer" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = [self handleResponse:responseObject];
		NSDictionary *result = [responseObject valueForKeyPath:@"result"];
		NSArray *multiAttributes = nil;
		if (!error) {
			multiAttributes = result[@"data"];
		}
		if (block) block(multiAttributes, error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(nil, error);
	}];
}

- (void)getDeviceStatus:(NSString *)deviceID withBlock:(void (^)(NSDictionary *attributes, NSError *error))block {
	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:NO signUserID:YES] mutableCopy];
	parameters[@"method"] = @"getDeviceStatus";
	parameters[@"params"] = @{@"ndevice_id" : deviceID, @"ndevice_sn" : @""};
							  
	NSString *JSONString = [self dataTOJSONString:parameters];
	[self POST:@"homer" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = [self handleResponse:responseObject];
		NSDictionary *result = [responseObject valueForKeyPath:@"result"];
		NSDictionary *attributes = nil;
		if (!error) {
			if (result[@"data"] && [result[@"data"] count]) {
				attributes = result[@"data"][0];
			}
		}
		if (block) block(attributes, error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(nil, error);
	}];
}

- (void)command:(NSString *)deviceID value:(NSString *)value withBlock:(void (^)(NSString *value, NSError *error))block {
	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:NO signUserID:YES] mutableCopy];
	parameters[@"method"] = @"command";
	parameters[@"params"] = @{@"ndevice_id" : deviceID, @"ndevice_sn" : @"", @"command" : value};
	
	NSString *JSONString = [self dataTOJSONString:parameters];
	[self POST:@"homer" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = [self handleResponse:responseObject];
		NSDictionary *result = [responseObject valueForKeyPath:@"result"];
		NSString *value = nil;
		if (!error) {
			value = result[@"data"][@"reply"];
		}
		if (block) block(value, error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(nil, error);
	}];
}

- (void)getBindResultWithBlock:(void (^)(BOOL newDeviceFound, NSError *error))block {
	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:NO signUserID:YES] mutableCopy];
	parameters[@"method"] = @"getBindResult";
	parameters[@"params"] = @{@"user_id" : [self userID], @"bind_code" : @"0"};//0 default
	
	NSString *JSONString = [self dataTOJSONString:parameters];
	[self POST:@"homer" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		BOOL newDeviceFound = NO;
		NSError *error = [self handleResponse:responseObject];
		NSDictionary *result = [responseObject valueForKeyPath:@"result"];
		NSString *deviceID = nil;
		if (!error) {
			deviceID = result[@"data"][@"ndevice_id"];
			if (deviceID.length) {
				newDeviceFound = YES;
			}
		}
		if (block) block(newDeviceFound, error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(NO, error);
	}];
}

- (void)updateAuthorize:(NSString *)deviceID role:(NSString *)role nickename:(NSString *)nickname withBlock:(void (^)(NSError *error))block {
	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:NO signUserID:YES] mutableCopy];
	parameters[@"method"] = @"updateAuthorize";
	parameters[@"params"] = @{@"ndevice_id" : deviceID,
							  @"role" : role,
							  @"nick_name" : nickname,
							  @"user_id" : [self userID],
							  };
	
	NSString *JSONString = [self dataTOJSONString:parameters];
	[self POST:@"homer" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = [self handleResponse:responseObject];
		if (block) block(error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(error);
	}];
}

- (void)unbindDevice:(NSString *)deviceID withBlock:(void (^)(NSError *error))block {
	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:NO signUserID:YES] mutableCopy];
	parameters[@"method"] = @"unbind";
	parameters[@"params"] = @{@"ndevice_id" : deviceID,
							  };
	
	NSString *JSONString = [self dataTOJSONString:parameters];
	[self POST:@"homer" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = [self handleResponse:responseObject];
		if (block) block(error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(error);
	}];
}

- (void)authorizeDevice:(NSString *)deviceID role:(NSString *)role withBlock:(void (^)(NSError *error))block {	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:NO signUserID:YES] mutableCopy];
	parameters[@"method"] = @"authorize";
	parameters[@"params"] = @{@"ndevice_id" : deviceID,
							  @"role" : role,
							  @"code" : @"0",
							  @"ndevice_sn" : @"",
							  @"nick_name" : @"贝昂",
							  @"device_info" : @"贝昂",
							  };
	
	NSString *JSONString = [self dataTOJSONString:parameters];
	NSLog(@"auth: %@", JSONString);
	[self POST:@"homer" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = [self handleResponse:responseObject];
		if (block) block(error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(error);
	}];
}

- (void)getDeviceData:(NSString *)deviceID withBlock:(void (^)(BOOL validForReset, NSError *error))block {
	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:NO signUserID:YES] mutableCopy];
	parameters[@"method"] = @"getDeviceData";
	parameters[@"params"] = @{@"ndevice_id" : deviceID,
							  @"ndevice_sn" : @"",
							  @"key" : @"beiang_firmware",
							  };
	
	NSString *JSONString = [self dataTOJSONString:parameters];
	[self POST:@"homer" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = [self handleResponse:responseObject];
		BOOL validForReset = NO;
		if (!error) {
			NSDictionary *result = [responseObject valueForKeyPath:@"result"];
			NSString *value = result[@"data"][@"value"];
//			value = @"eyJ2ZXJzaW9uY29kZSI6InRvdWNodWFuX3YyLjUiLCJyZWxlYXNlbm90ZSI6InRvdWNodWFuIiwidXBkYXRlYWN0aW9uIjoibm93IiwiaGFyZHdhcmVtb2RlbCI6IjIwMDEwIiwidXNlcmRlZmluZWQiOiJyZWxhc2UifQ==";
			if (value.length) {
				CocoaSecurityDecoder *decoder = [[CocoaSecurityDecoder alloc] init];
				NSData *data = [decoder base64:value];
				NSDictionary *JSON = [NSJSONSerialization JSONObjectWithData:data options: NSJSONReadingMutableContainers error:&error];
				if (!error) {
					if (JSON[@"versioncode"]) {
						validForReset = YES;
					}
				}
			}
		}
		if (block) block(validForReset, error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(NO, error);
	}];
}

- (void)resetDevice:(NSString *)deviceID withBlock:(void (^)(NSError *error))block {
	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:NO signUserID:YES] mutableCopy];
	parameters[@"method"] = @"resetDevice";
	parameters[@"params"] = @{@"ndevice_id" : deviceID};
	
	NSString *JSONString = [self dataTOJSONString:parameters];
	[self POST:@"homer" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = [self handleResponse:responseObject];
		if (block) block(error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(error);
	}];
}

- (void)logoutWithBlock:(void (^)(NSError *error))block {
	NSMutableDictionary *parameters = [[self addSystemParametersRequestEmpty:NO signUserID:YES] mutableCopy];
	parameters[@"method"] = @"logout";
	parameters[@"params"] = @{};
	
	NSString *JSONString = [self dataTOJSONString:parameters];
	[self POST:@"account" parameters:JSONString success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = [self handleResponse:responseObject];
		if (!error) {
			[self logout];
		}
		if (block) block(error);
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		if (block) block(error);
	}];
}

@end
