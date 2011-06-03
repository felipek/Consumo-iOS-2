 //
//  SetupAccountViewController.m
//  Consumo-iOS
//
//  Created by Felipe Kellermann on 1/4/11.
//  Copyright 2011 Nyvra Software. All rights reserved.
//

#import "SetupAccountViewController.h"
#import "Accounts.h"
#import "Services.h"
#import "RegexKitLite.h"

@implementation SetupAccountViewController

@synthesize delegate;

- (id)initWithAccount:(NSDictionary *)anAccount
{
    self = [super init];
	if (self != nil) {
		account = [anAccount retain];
	}

	return self;
}

#pragma mark View

- (void)loadView
{
	[super loadView];

	serviceCurrent = [[[Services singleton] allServices] objectAtIndex:0];

	buttonSave = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", @"")
												  style:UIBarButtonItemStyleDone
												 target:self
												 action:@selector(buttonSaveTouched)];
	
	buttonCancel = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"")
													style:UIBarButtonItemStyleBordered
												   target:self
												   action:@selector(buttonCancelTouched)];
	
	textUsername = [[UITextField alloc] initWithFrame:CGRectMake(100, 10, 185, 23)];
	[textUsername setTextAlignment:UITextAlignmentRight];
	[textUsername setKeyboardType:UIKeyboardTypePhonePad];
	[textUsername setPlaceholder:[NSLocalizedString(@"5198581234", @"") stringByAppendingString:@" "]];
	[textUsername setDelegate:self];
        [textUsername setTag:50];

	textPassword = [[UITextField alloc] initWithFrame:CGRectMake(100, 10, 185, 23)];
	[textPassword setTextAlignment:UITextAlignmentRight];
	[textPassword setKeyboardType:UIKeyboardTypePhonePad];
	[textPassword setSecureTextEntry:YES];
	[textPassword setDelegate:self];
	[textPassword setTag:50];
	
	textLabel = [[UITextField alloc] initWithFrame:CGRectMake(100, 10, 185, 23)];
	[textLabel setTextAlignment:UITextAlignmentRight];
	[textLabel setPlaceholder:[NSLocalizedString(@"Conta Pessoal", @"") stringByAppendingString:@" "]];
	[textLabel setReturnKeyType:UIReturnKeyDone];
	[textLabel setDelegate:self];
	[textLabel setTag:50];
	
	switchRefresh = [[UISwitch alloc] initWithFrame:CGRectMake(195, 8, 0, 0)];
	[switchRefresh setOn:YES];
	[switchRefresh setTag:50];
	
	[tableView setContentInset:UIEdgeInsetsMake(0, 0, 215, 0)];
	[tableView setScrollIndicatorInsets:tableView.contentInset];
	
	if (account != nil) {
        serviceCurrent = [account objectForKey:@"Carrier"];

		[textUsername setText:[account objectForKey:@"Username"]];
		[textPassword setText:[account objectForKey:@"Password"]];
		[textLabel setText:[account objectForKey:@"Label"]];

		// Compatibility.
		if ([account objectForKey:@"AutoRefresh"] != nil)
			[switchRefresh setOn:[[account objectForKey:@"AutoRefresh"] boolValue]];
		else
			[switchRefresh setOn:YES];
	}
}

- (void)viewDidLoad
{
	[self setTitle:NSLocalizedString(@"Account", @"")];
	
	[self.navigationItem setLeftBarButtonItem:buttonCancel];
	[self.navigationItem setRightBarButtonItem:buttonSave];
	
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	[textUsername becomeFirstResponder];
    
    if (account == nil)
        [self presentServiceSheet];
    
	[super viewDidAppear:animated];
}

- (BOOL)save
{
	if ([textUsername.text length] == 0) {
		[self.navigationItem setPrompt:NSLocalizedString(@"Username must be specified", @"")];
		[textUsername becomeFirstResponder];
		return NO;
	} else if ([textPassword.text length] == 0) {
		[self.navigationItem setPrompt:NSLocalizedString(@"Password must be specified", @"")];
		[textPassword becomeFirstResponder];
		return NO;
	}

	// Yeah, users... ;-)
	NSString *username = [textUsername.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	username = [username stringByReplacingOccurrencesOfRegex:@"[ )(.-]" withString:@""];
	if ([username hasPrefix:@"0"])
		username = [username substringFromIndex:1];
	
	if (account == nil && [[Accounts singleton] accountWithUsername:username] != nil) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Aviso", @"")
														 message:NSLocalizedString(@"This is already an account with this username. Please edit the account instead of overriding it.", @"")
														delegate:nil
											   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
											   otherButtonTitles:nil] autorelease];
		[alert show];
		return NO;
	}
	
	NSString *password = [textPassword.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

	NSString *passwordRE = [[self service] objectForKey:@"PasswordRE"];
	if (passwordRE != nil && ! [password isMatchedByRegex:passwordRE]) {
		NSString *passwordWarning = [[self service] objectForKey:@"PasswordWarning"];
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"")
														 message:passwordWarning
														delegate:nil
											   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
											   otherButtonTitles:nil] autorelease];
		[alert show];
		[textPassword becomeFirstResponder];
		return NO;
	}

	if (account == nil) {
		NSDictionary *newAccount = [[Accounts singleton] newAccountWithLabel:textLabel.text
																	 carrier:serviceCurrent
																	username:username
																 andPassword:password];

		[newAccount setValue:[NSNumber numberWithBool:switchRefresh.on] forKey:@"AutoRefresh"];

		[delegate didCreateAccount:newAccount];
		[newAccount release];
	} else {
		[account setValue:username forKey:@"Username"];
		[account setValue:password forKey:@"Password"];
		[account setValue:textLabel.text forKey:@"Label"];
		[account setValue:serviceCurrent forKey:@"Carrier"];
		[account setValue:[NSNumber numberWithBool:switchRefresh.on] forKey:@"AutoRefresh"];

		[delegate didChangeAccount:account];
	}

	[[Accounts singleton] commit];

	return YES;
}

- (void)buttonCancelTouched
{
	[self dismissModalViewControllerAnimated:YES];
}

- (void)buttonSaveTouched
{
	if ([self save] == YES)
		[self dismissModalViewControllerAnimated:YES];
}

- (NSDictionary *)service
{
	return [[Services singleton] metaWithName:serviceCurrent];
}

- (void)presentServiceSheet
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Select a service", @"")
                                                             delegate:self
                                                    cancelButtonTitle:nil
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:nil];
    
    for (NSString *service in [[Services singleton] allServices])
        [actionSheet addButtonWithTitle:[[[Services singleton] metaWithName:service] objectForKey:@"Title"]];
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"I Want Others!", @"")];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    [actionSheet setCancelButtonIndex:[[[Services singleton] allServices] count] + 1];
    
    [actionSheet showFromToolbar:self.navigationController.toolbar];
    [actionSheet release];
}

#pragma mark Table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table
{
	return 3;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 1;
	else if (section == 1)
		return 2;
	else if (section == 2)
		return 2;
	else
		return 0;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = nil;
	
	cell = [table dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil)
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"] autorelease];
	
	UIView *tempView = [cell.contentView viewWithTag:50];
	[tempView removeFromSuperview];
	
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	[cell.detailTextLabel setText:@""];

	switch (indexPath.section) {
		case 0:
			[cell setSelectionStyle:UITableViewCellSelectionStyleBlue];
			[cell.textLabel setText:NSLocalizedString(@"Service", @"")];
            NSDictionary *serv = [self service];

			[cell.detailTextLabel setText:[serv objectForKey:@"Title"]];
			break;
			
		case 1:
			switch (indexPath.row) {
				case 0:
					[cell.textLabel setText:NSLocalizedString(@"Username", @"")];
					[cell.contentView addSubview:textUsername];
					break;
					
				case 1:
					[cell.textLabel setText:NSLocalizedString(@"Password", @"")];
					[cell.contentView addSubview:textPassword];
					[textPassword setPlaceholder:[[[self service] objectForKey:@"PasswordSample"] stringByAppendingString:@" "]];
					break;
			}
			break;
			
		case 2:
			switch (indexPath.row) {
				case 0:
					[cell.textLabel setText:NSLocalizedString(@"Label", @"")];
					[cell.contentView addSubview:textLabel];
					break;
					
				case 1:
					[cell.textLabel setText:NSLocalizedString(@"Auto Refresh", @"")];
					[cell.contentView addSubview:switchRefresh];
					break;
			}
			break;
	}
	
	// I feel bad :-)
	UITextField *field = (UITextField *) [cell.contentView viewWithTag:50];
	if ([field isKindOfClass:[UITextField class]])
		[field setTextColor:cell.detailTextLabel.textColor];

	return cell;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case 0:
			[table deselectRowAtIndexPath:indexPath animated:YES];
			
            [self presentServiceSheet];
			break;
		case 1:
			switch (indexPath.row) {
				case 0:
					[textUsername becomeFirstResponder];
					break;
				case 1:
					[textPassword becomeFirstResponder];
					break;
				case 2:
					[textLabel becomeFirstResponder];
					break;
			}
	}
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section
{
	if (section	 == 2)
		return NSLocalizedString(@"Optionals", @"");
	else
		return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section == 0)
		return NSLocalizedString(@"Make sure you already have an account for the service. Create an account otherwise.", @"");
	else
		return nil;
}

#pragma mark Action sheet

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex > [[[Services singleton] allServices] count]) {
        return;
    } else if (buttonIndex == [[[Services singleton] allServices] count]) {
		[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Other services", @"")
                                     message:NSLocalizedString(@"We are working to add other services. Please stay tuned or contact us if you can help with something.", @"")
                                    delegate:nil
                           cancelButtonTitle:NSLocalizedString(@"Dismiss", @"")
                           otherButtonTitles:nil] autorelease] show];
        return;
	} else {
        serviceCurrent = [[[Services singleton] allServices] objectAtIndex:buttonIndex];
    }
	
	[tableView reloadData];
	
	if ([textUsername.text length] == 0)
		[textUsername becomeFirstResponder];
	else if ([textPassword.text length] == 0)
		[textPassword becomeFirstResponder];
	else if ([textLabel.text length] == 0)
		[textLabel becomeFirstResponder];
}

#pragma mark Text field

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self buttonSaveTouched];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if (textField == textPassword) {
		NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:1];
		[tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField != textUsername)
    {
        [textField.text stringByAppendingString:string];
        return YES;
    }
    else if (textField == textUsername && [textField.text length] < 10 || [string isEqualToString:@""])
    {
        [textField.text stringByAppendingString:string];
        return YES;
    }
    else
        return NO;
}

#pragma mark Memory management

- (void)dealloc
{
	self.delegate = nil;
	
	[textUsername release];
	[textPassword release];
	[textLabel release];
	[switchRefresh release];
	[buttonSave release];
	[services release];
	[account release];

	[super dealloc];
}

@end