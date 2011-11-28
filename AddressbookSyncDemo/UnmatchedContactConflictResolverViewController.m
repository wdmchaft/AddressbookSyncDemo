//
//  AmbigousContactConflictResolverTableViewController.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 26/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "UnmatchedContactConflictResolverViewController.h"
#import "Contact.h"
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <QuartzCore/QuartzCore.h>

@implementation UnmatchedContactConflictResolverViewController

@synthesize contactName1;
@synthesize contactName2;
@synthesize contact;
@synthesize tableView;
@synthesize titleView;

- (IBAction)done:(id)sender {
	NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    NSString *key = [[[_contactSectionIndexDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section];
	ABRecordRef record = (__bridge ABRecordRef)[[_contactSectionIndexDictionary objectForKey:key] objectAtIndex:indexPath.row];

	[contact resolveConflictWithAddressbookRecord:record];
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)cancel:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	//self.tableView.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	titleView.layer.masksToBounds = NO;
	titleView.layer.shadowOffset = CGSizeMake(0, 5);
	titleView.layer.shadowRadius = 5;
	titleView.layer.shadowOpacity = 0.5;
	[self.view bringSubviewToFront:titleView];
	
	_addressbook = ABAddressBookCreate();
	NSArray *allContacts = (__bridge_transfer NSArray *)ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(_addressbook, nil, ABPersonGetSortOrdering());
	
	NSMutableDictionary *sectionIndexLetter = [NSMutableDictionary dictionary];
	
	for (NSUInteger i = 0; i < [allContacts count]; i++) {
		ABRecordRef record = (__bridge ABRecordRef)[allContacts objectAtIndex:i];
		NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonFirstNameProperty);
		NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonLastNameProperty);
		NSString *company = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonOrganizationProperty);
		
		CFNumberRef personType = ABRecordCopyValue(record, kABPersonKindProperty);
		
		NSString *result = nil;
		if (personType == kABPersonKindOrganization) {
			if (company) {
				result = company;
			} else if (lastName) {
				result = lastName;
			} else if (firstName) {
				result = firstName;
			} else {
				result = @"N";
			}
		} else {
			if (lastName) {
				result = lastName;
			} else if (firstName) {
				result = firstName;
			} else if (company) {
				result = company;
			} else {
				result = @"N";
			}
		}

		result = [[result substringWithRange:NSMakeRange([result rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location, 1)] uppercaseString];
		NSMutableArray *array = [sectionIndexLetter objectForKey:result];
		if (!array) {
			array = [NSMutableArray array];
			[sectionIndexLetter setObject:array forKey:[result uppercaseString]];
		}
		
		[array addObject:(__bridge id)record];
		
		CFRelease(personType);
	}

	_contactSectionIndexDictionary = [NSDictionary dictionaryWithDictionary:sectionIndexLetter];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	CFRelease(_addressbook);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	self.contactName1.text = contact.compositeName;
	self.contactName2.text = contact.secondaryCompositeName;
	
	self.navigationItem.rightBarButtonItem.enabled = ([self.tableView indexPathForSelectedRow] != nil);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Table view data source

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return [[_contactSectionIndexDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [[[_contactSectionIndexDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tv
{
    // Return the number of sections.
    return [[_contactSectionIndexDictionary allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    NSString *key = [[[_contactSectionIndexDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:section];
	return [[_contactSectionIndexDictionary objectForKey:key] count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
	
    NSString *key = [[[_contactSectionIndexDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section];
	ABRecordRef record = (__bridge ABRecordRef)[[_contactSectionIndexDictionary objectForKey:key] objectAtIndex:indexPath.row];
	
	NSString *firstName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonFirstNameProperty);
	NSString *lastName = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonLastNameProperty);
	NSString *company = (__bridge_transfer NSString *)ABRecordCopyValue(record, kABPersonOrganizationProperty);
	
	CFNumberRef personType = ABRecordCopyValue(record, kABPersonKindProperty);
	
	cell.textLabel.font = [UIFont boldSystemFontOfSize:18.0];

	if (personType == kABPersonKindOrganization) {
		if (company) {
			cell.textLabel.text = company;
			if (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst) {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@%@", firstName?firstName:@"", firstName?@" ":@"", lastName?lastName:@""];
			} else {
				cell.detailTextLabel.text = [NSString stringWithFormat:@"%@%@%@", lastName?lastName:@"", firstName?@" ":@"", firstName?firstName:@""];
			}
		} else if (firstName || lastName) {
			if (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst) {
				cell.textLabel.text = [NSString stringWithFormat:@"%@%@%@", firstName?firstName:@"", firstName?@" ":@"", lastName?lastName:@""];
			} else {
				cell.textLabel.text = [NSString stringWithFormat:@"%@%@%@", lastName?lastName:@"", firstName?@" ":@"", firstName?firstName:@""];
			}
		} else {
			cell.textLabel.text = @"No Name";
			cell.textLabel.font = [UIFont italicSystemFontOfSize:18.0];
		}
	} else {
		if (firstName || lastName) {
			if (ABPersonGetCompositeNameFormat() == kABPersonCompositeNameFormatFirstNameFirst) {
				cell.textLabel.text = [NSString stringWithFormat:@"%@%@%@", firstName?firstName:@"", firstName?@" ":@"", lastName?lastName:@""];
			} else {
				cell.textLabel.text = [NSString stringWithFormat:@"%@%@%@", lastName?lastName:@"", firstName?@" ":@"", firstName?firstName:@""];
			}
			cell.detailTextLabel.text = (company != nil)?company:@"";
			//			cell.detailTextLabel.font = (company != nil)?[UIFont systemFontOfSize:14.0]:[UIFont italicSystemFontOfSize:14.0];
		} else if (company) {
			cell.textLabel.text = company;
		} else {
			cell.textLabel.text = @"No Name";
			cell.textLabel.font = [UIFont italicSystemFontOfSize:18.0];
		}
	}
	
	CFRelease(personType);
	
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.navigationItem.rightBarButtonItem.enabled = ([self.tableView indexPathForSelectedRow] != nil);
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    NSString *key = [[[_contactSectionIndexDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] objectAtIndex:indexPath.section];
	ABRecordRef record = (__bridge ABRecordRef)[[_contactSectionIndexDictionary objectForKey:key] objectAtIndex:indexPath.row];
	ABPersonViewController *picker = [[ABPersonViewController alloc] init];
	picker.displayedPerson = record;
	// Allow users to edit the person’s information
	picker.allowsEditing = NO;
	
	[self.navigationController pushViewController:picker animated:YES];
}

@end
