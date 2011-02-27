    //
//  StatsViewController.m
//  Consumo-iOS
//
//  Created by Felipe Kellermann on 1/4/11.
//  Copyright 2011 Nyvra Software. All rights reserved.
//

#import "StatsViewController.h"
#import "Accounts.h"
#import "Services.h"

@implementation StatsViewController

- (id)initWithIndex:(NSInteger)anIndex
{
	if (self = [super init]) {
		index = anIndex;
		account = [[Accounts singleton] accountAtIndex:index];
		NSString *ID = [NSString stringWithFormat:@"Cache-%@-%@-2.plist", [account objectForKey:@"Carrier"], [account objectForKey:@"Username"]];
		NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
		path = [[documents stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", ID]] retain];		
	}
	
	return self;
}

#pragma mark View

- (void)loadView
{
	[super loadView];
	
	buttonRefresh = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(buttonRefreshTouched)];
}

- (void)viewDidLoad
{
	[self.navigationController.toolbar setTintColor:self.navigationController.navigationBar.tintColor];
	
	if ([[account objectForKey:@"Label"] length] > 0)
		[self setTitle:[account objectForKey:@"Label"]];
	else
		[self setTitle:[account objectForKey:@"Username"]];
	
	buttonEmail = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"E-mail", @"")
												   style:UIBarButtonItemStyleBordered
												  target:self
												  action:@selector(buttonEmailTouched)];
	buttonReport = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Help?", @"")
													style:UIBarButtonItemStyleBordered
												   target:self
												   action:@selector(buttonIncorrectTouched)];
	buttonFlexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
																   target:nil
																   action:nil];

	buttonStatus = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Updating data...", @"")
													style:UIBarButtonItemStylePlain
												   target:nil
												   action:nil];

	NSDictionary *definition = [[Services singleton] serviceWithName:[account objectForKey:@"Carrier"]];
	
	sections = [definition objectForKey:@"Sections"];
	
	_scraper = [[ScraperMonkey alloc] initWithDefinition:definition];
	[_scraper setDelegate:self];
	
	NSString *ddd = [[account objectForKey:@"Username"] substringToIndex:2];
	NSString *linha = [[account objectForKey:@"Username"] substringFromIndex:2];
	NSString *senha = [account objectForKey:@"Password"];
	
	[_scraper setValue:ddd forKey:@"ddd"];
	[_scraper setValue:linha forKey:@"linha"];
	[_scraper setValue:senha forKey:@"senha"];

	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self.navigationController setToolbarHidden:NO animated:YES];
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[self.navigationController setToolbarHidden:YES animated:YES];
	[super viewWillDisappear:animated];
}

- (void)viewWillAppear:(BOOL)animated
{	
	BOOL autoRefresh = NO;

	if (appearRequested == YES)
		return;
	else
		appearRequested = YES;

	[self cacheLoad];
	
	if ([data count] > 0)
		[tableView reloadData];

	// Legacy.
	if ([account objectForKey:@"AutoRefresh"] == nil)
		autoRefresh = YES;
	else
		autoRefresh = [[account objectForKey:@"AutoRefresh"] boolValue];
	
	if (autoRefresh == YES || [data count] == 0)
		[self refresh];
	else
		[self performSelectorOnMainThread:@selector(stopActivity) withObject:nil waitUntilDone:YES];
	
	[super viewWillAppear:animated];
}

#pragma mark Tools and stuff

- (void)cacheLoad
{
	data = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
}

- (void)cacheSave
{
	[data writeToFile:path atomically:YES];
}

- (void)buttonRefreshTouched
{
	[self refresh];
}

- (void)label:(NSString **)label andValue:(NSString **)value forNode:(NSDictionary *)node
{
	NSString *rowTitle = [node objectForKey:@"Title"];
	NSString *rowVariable = [node objectForKey:@"Variable"];
	NSString *rowDefault = [node objectForKey:@"Default"];
	NSString *rowValue = nil;
	
	if ([rowTitle hasPrefix:@"@"])
		rowTitle = [data objectForKey:[rowTitle substringFromIndex:1]];
	
	if ([rowVariable hasPrefix:@"@"])
		rowValue = [data objectForKey:[rowVariable substringFromIndex:1]];
	
	if (rowTitle == nil && [rowVariable hasPrefix:@"@"])
		rowTitle = [[rowVariable substringFromIndex:1] capitalizedString];
	
	*label = rowTitle;
	if (rowValue != nil && [rowValue length] > 0)
		*value = rowValue;
	else
		*value = rowDefault;
}

- (NSString *)formatData
{
	NSMutableString *str = [[NSMutableString alloc] initWithString:@"\n"];
	
	for (NSDictionary *section in sections) {
		for (NSDictionary *node in [section objectForKey:@"Data"]) {
			NSString *label = nil, *value = nil;		
			[self label:&label andValue:&value forNode:node];
			[str appendFormat:@"%@: %@\n", label, value];
		}
	}
	
	[str appendString:@"\n"];

	return [str autorelease];
}

- (MFMailComposeViewController *)newMail
{
	MFMailComposeViewController *mailView = [[MFMailComposeViewController alloc] init];
	[mailView.navigationBar setTintColor:self.navigationController.navigationBar.tintColor];
	[mailView setMailComposeDelegate:self];

	return mailView;
}

- (void)buttonEmailTouched
{
	MFMailComposeViewController *mailView = [self newMail];
	
	// TODO FEK: Add account label.
	[mailView setSubject:[NSString stringWithFormat:@"%@ %@: %@",
						  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
						  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
						  [account objectForKey:@"Username"]]];
	[mailView setMessageBody:[self formatData] isHTML:NO];
	
	[self.navigationController presentModalViewController:mailView animated:YES];
	[mailView release];	
}

- (void)buttonIncorrectTouched
{
	MFMailComposeViewController *mailView = [self newMail];
	
	// TODO FEK: Add account label.
	[mailView setSubject:[NSString stringWithFormat:@"%@ %@: %@ - %@",
						  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
						  [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
						  [account objectForKey:@"Username"],
						  NSLocalizedString(@"Problem", @"")]];

	NSString *message = NSLocalizedString(@"Help us improve the service. Describe the problem and your data as much as you can. Thanks!", @"");
	[mailView setToRecipients:[NSArray arrayWithObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"SoftwareOwnerEmail"]]];
	[mailView setMessageBody:[NSString stringWithFormat:@"\n%@\n%@", message, [self formatData]] isHTML:NO];
	
	[self.navigationController presentModalViewController:mailView animated:YES];
	[mailView release];
}

- (void)refreshThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[_scraper start];
	[pool release];
}

- (void)refresh
{
	[self setToolbarItems:[NSArray arrayWithObjects:buttonFlexible, buttonStatus, buttonFlexible, nil] animated:YES];
	[self startActivity];
	
	NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(refreshThread) object:nil];
	[thread start];
	[thread release];
}

- (void)stopActivity
{
	[super stopActivity];
	
	if (data != nil)
		[self setToolbarItems:[NSArray arrayWithObjects:buttonEmail, buttonFlexible, buttonReport, nil] animated:YES];
	else {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"")
														 message:NSLocalizedString(@"Oops! We had problems interpreting your data. Please contact us to help improve the product.", @"")
														delegate:self
											   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
											   otherButtonTitles:nil] autorelease];
		[alert show];
	}
	
	[self.navigationItem setRightBarButtonItem:buttonRefresh animated:YES];
}

#pragma mark Alert view

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Scraper Monkey delegate

- (void)updateStatus:(NSDictionary *)node
{
	NSString *nodeTitle = [node objectForKey:@"Title"];
	[buttonStatus setTitle:[NSString stringWithFormat:@"%@...", nodeTitle]];
}

- (void)scraper:(ScraperMonkey *)scraper didStartNode:(NSDictionary *)node
{
	[self performSelectorOnMainThread:@selector(updateStatus:) withObject:node waitUntilDone:YES];
}

- (void)scraper:(ScraperMonkey *)scraper didEndNode:(NSDictionary *)node withError:(NSDictionary *)error
{
	if (error != nil) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"")
														 message:[error objectForKey:@"Error"]
														delegate:self
											   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
											   otherButtonTitles:nil] autorelease];
		[alert show];
	}
}

- (void)scraperDidEnd:(ScraperMonkey *)scraper
{
	if (data != nil) {
		[data release];
		data = nil;
	}
	
	data = [[scraper variables] retain];
	
	[self cacheSave];
	
	[self performSelectorOnMainThread:@selector(stopActivity) withObject:nil waitUntilDone:YES];
}


#pragma mark Message UI

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
	[controller dismissModalViewControllerAnimated:YES];
}

#pragma mark Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table
{
	if ([data count] == 0)
		return 0;
	else
		return [sections count];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
	NSDictionary *sectionDict = [sections objectAtIndex:section];
	return [[sectionDict objectForKey:@"Data"] count];
}

- (id)objectForIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *section = [sections objectAtIndex:indexPath.section];
	id object = [[section objectForKey:@"Data"] objectAtIndex:indexPath.row];
	return object;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
	NSDictionary	*row = [self objectForIndexPath:indexPath];
	NSString		*label = nil, *value = nil;
	
	cell = [table dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"] autorelease];
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	}
	
	[self label:&label andValue:&value forNode:row];
	
	[cell.textLabel setText:label];
	[cell.detailTextLabel setText:value];

	return cell;
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section
{
	NSDictionary *sect = [sections objectAtIndex:section];
	NSString *sTitle = [sect objectForKey:@"Header"];
	return sTitle;
}

- (NSString *)tableView:(UITableView *)table titleForFooterInSection:(NSInteger)section
{
	NSDictionary *sect = [sections objectAtIndex:section];
	NSString *sFooter = [sect objectForKey:@"Footer"];
	return sFooter;
}

#pragma mark Memory management

- (void)dealloc
{
	[_scraper setDelegate:nil];
	[_scraper release];

	[data release];

	[buttonRefresh release];
	[buttonEmail release];
	[buttonReport release];
	[buttonFlexible release];
	[buttonStatus release];

	[super dealloc];
}

@end