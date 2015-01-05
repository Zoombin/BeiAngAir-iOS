//
//  ZBModel.m
//  Joy
//
//  Created by zhangbin on 7/5/14.
//  Copyright (c) 2014 颜超. All rights reserved.
//

#import "ZBModel.h"

@implementation ZBModel

- (instancetype)initWithAttributes:(NSDictionary *)attributes
{
    self = [super init];
    if (!self) {
        return nil;
    }
    return self;
}

+ (NSArray *)multiWithAttributesArray:(NSArray *)array
{
	NSMutableArray *multi = [NSMutableArray array];
	if ([array isKindOfClass:[NSNull class]]) {
		return multi;
	}
	for (NSDictionary *attributes in array) {
		[multi addObject:[[[self class] alloc] initWithAttributes:attributes]];
	}
	return multi;
}

+ (NSString *)archivePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *archivePath = [paths[0] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.model", NSStringFromClass([self class])]];
	return archivePath;
}

- (void)archive {
	[NSKeyedArchiver archiveRootObject:self toFile:[[self class] archivePath]];
}

+ (instancetype)unarchive {
	return [NSKeyedUnarchiver unarchiveObjectWithFile:[self archivePath]];
}

@end
