//
//  Services.h
//  Consumo-iOS
//
//  Created by Felipe Kellermann on 1/22/11.
//  Copyright 2011 Nyvra Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Services : NSObject
{
	NSDictionary *services;
	NSMutableDictionary	*serviceDefinition;
}

+ (Services *)singleton;
- (void)definitionsLoad;
- (NSDictionary *)serviceWithName:(NSString *)name;
- (void)definitionsUpdate;
- (NSArray *)allServices;

@end