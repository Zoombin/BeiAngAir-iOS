//
//  ZBModel.h
//  Joy
//
//  Created by zhangbin on 7/5/14.
//  Copyright (c) 2014 颜超. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (NotNull)

- (instancetype)notNull;

@end

@implementation NSObject (NotNull)

- (instancetype)notNull {
	return self;
}

@end

@implementation NSNull (NotNull)

- (instancetype)notNull {
	return nil;
}

@end

@interface ZBModel : NSObject

- (instancetype)initWithAttributes:(NSDictionary *)attributes;
+ (NSArray *)multiWithAttributesArray:(NSArray *)array;

//遵守<NSCoding>协议后才能用的方法
+ (NSString *)archivePath;
+ (instancetype)unarchive;
- (void)archive;

@end
