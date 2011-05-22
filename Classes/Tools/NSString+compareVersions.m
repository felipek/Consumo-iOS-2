//
//  NSString+compareVersions.m
//  Consumo-iOS
//
//  Created by Felipe Kellermann on 4/2/11.
//  Copyright 2011 Nyvra. All rights reserved.
//

#import "NSString+compareVersions.h"

@implementation NSString (NSString_compareVersions)

- (NSComparisonResult)compareToVersion:(NSString *)other
{
    int i;
    
	NSMutableArray *leftFields  = [[NSMutableArray alloc] initWithArray:[self  componentsSeparatedByString:@"."]];
	NSMutableArray *rightFields = [[NSMutableArray alloc] initWithArray:[other componentsSeparatedByString:@"."]];
	
	if ([leftFields count] < [rightFields count]) {
		while ([leftFields count] != [rightFields count]) {
			[leftFields addObject:@"0"];
		}
	} else if ([leftFields count] > [rightFields count]) {
		while ([leftFields count] != [rightFields count]) {
			[rightFields addObject:@"0"];
		}
	}
	
	for(i = 0; i < [leftFields count]; i++) {
		NSComparisonResult result = [[leftFields objectAtIndex:i] compare:[rightFields objectAtIndex:i] options:NSNumericSearch];
		if (result != NSOrderedSame) {
			[leftFields release];
			[rightFields release];
			return result;
		}
	}
	
	[leftFields release];
	[rightFields release];

	return NSOrderedSame;
}

@end