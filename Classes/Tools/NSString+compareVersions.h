//
//  NSString+compareVersions.h
//  Consumo-iOS
//
//  Created by Felipe Kellermann on 4/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (NSString_compareVersions)

- (NSComparisonResult)compareToVersion:(NSString *)other;

@end
