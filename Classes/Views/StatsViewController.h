//
//  StatsViewController.h
//  Consumo-iOS
//
//  Created by Felipe Kellermann on 1/4/11.
//  Copyright 2011 Nyvra Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "BaseViewController.h"
#import "ScraperMonkey.h"

@interface StatsViewController : BaseViewController <MFMailComposeViewControllerDelegate, UIAlertViewDelegate, ScraperMonkeyDelegate>
{
	NSString			*path;
	NSInteger			index;
	
	NSDictionary		*account;
	NSDictionary		*data;
	
	UIBarButtonItem		*buttonRefresh;
	UIBarButtonItem		*buttonEmail;
	UIBarButtonItem		*buttonReport;
	UIBarButtonItem		*buttonFlexible;
	UIBarButtonItem		*buttonStatus;
	
	NSArray				*sections;
	
	BOOL				appearRequested;
	
	ScraperMonkey		*_scraper;
}

- (void)cacheLoad;
- (void)cacheSave;
- (void)buttonRefreshTouched;
- (NSString *)formatData;
- (MFMailComposeViewController *)newMail;
- (void)buttonEmailTouched;
- (void)buttonIncorrectTouched;
- (void)refresh;
- (void)stopActivity;

@end
