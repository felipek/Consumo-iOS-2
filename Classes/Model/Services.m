//
//  Services.m
//  Consumo-iOS
//
//  Created by Felipe Kellermann on 1/22/11.
//  Copyright 2011 Nyvra Software. All rights reserved.
//

#import "Services.h"
#import "ASIHTTPRequest.h"

@implementation Services

- (id)init
{
	if (self = [super init]) {
		NSString *file = [[NSBundle mainBundle] pathForResource:@"Services" ofType:@"plist"];
		services = [[NSDictionary dictionaryWithContentsOfFile:file] retain];
		serviceDefinition = [[NSMutableDictionary alloc] init];
	}
	
	return self;
}

+ (Services *)singleton
{
	static Services *instance = nil;
	
	@synchronized(self) {
		if (instance == nil)
			instance = [[Services alloc] init];
	}
	
	return instance;
}

- (void)definitionLoad:(NSDictionary *)service
{
	NSString *name = [service objectForKey:@"Definition"];

	NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
	NSString *filePath = [documents stringByAppendingPathComponent:name];

	NSDictionary *serv = [NSDictionary dictionaryWithContentsOfFile:filePath];
	if (serv != nil && [serv count] > 0) {
	} else {
		NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
		filePath = [bundlePath stringByAppendingPathComponent:name];
		serv = [NSDictionary dictionaryWithContentsOfFile:filePath];
	}
	
	if (serv != nil && [serv count] > 0)
		[serviceDefinition setObject:serv forKey:[[service objectForKey:@"Name"] lowercaseString]];
}

- (void)definitionsLoad
{
	for (NSString *service in [services allKeys])		
		[self definitionLoad:[services objectForKey:service]];
}

- (NSDictionary *)serviceWithName:(NSString *)name
{
	return [serviceDefinition objectForKey:[name lowercaseString]];
}

- (void)definitionsUpdate
{
	// Update algorithm: search mirrors to detect definition updates.
	for (NSString *service in [services allKeys]) {
		NSDictionary *serv = [services objectForKey:service];
		NSDictionary *definition = [self serviceWithName:service];
		
		NSArray *mirrors = [serv objectForKey:@"Mirrors"];
		NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		
		for (NSString *mirror in mirrors) {
			NSURL *url = [NSURL URLWithString:mirror];
			ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
			NSString *filePath = [documents stringByAppendingPathComponent:@"temp.plist"];
			[request setDownloadDestinationPath:filePath];
			[request startSynchronous];

			NSDictionary *tmpDict = [NSDictionary dictionaryWithContentsOfFile:filePath];
			// Not a valid dictionary, skip.
			if (! [tmpDict isKindOfClass:[NSDictionary class]])
				continue;
			
			if (! [[tmpDict objectForKey:@"Version"] isEqualToString:[definition objectForKey:@"Version"]]) {
				// Wee, different version :-)
				filePath = [documents stringByAppendingPathComponent:[serv objectForKey:@"Definition"]];
				[tmpDict writeToFile:filePath atomically:YES];
				[serviceDefinition setObject:tmpDict forKey:service];
			}
			
			break;
		}
	}
}

- (NSArray *)allServices
{
	return [serviceDefinition allKeys];
}

- (void)dealloc
{
	[services release];
	[serviceDefinition release];
	[super dealloc];
}

@end
