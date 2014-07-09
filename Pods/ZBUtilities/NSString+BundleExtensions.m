//
//  NSString+BundleExtensions.m
//  CoreTextWrapper
//
//  Created by Adrian on 4/28/10.
//  Copyright 2010 akosma software. All rights reserved.
//

#import "NSString+BundleExtensions.h"

@implementation NSString (BundleExtensions)

+ (NSString *)stringFromFileNamed:(NSString *)bundleFileName
{
//    NSString *documentDir = [[NSBundle mainBundle] pathForResource:bundleFileName ofType:@"txt"];
//    return [[NSString alloc] initWithContentsOfFile:documentDir encoding:NSUTF8StringEncoding error:nil];

    NSBundle *thisBundle = [NSBundle bundleForClass:self];
    if ([thisBundle pathForResource:bundleFileName ofType:nil])  {
        NSString *path = [[NSBundle mainBundle] pathForResource:bundleFileName ofType:nil];
        return [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    }
    return @"";
}

@end
