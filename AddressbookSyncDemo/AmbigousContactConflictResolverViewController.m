//
//  AmbigousContactConflictResolverTableViewController.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 26/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AmbigousContactConflictResolverViewController.h"
#import "Contact.h"
#import <AddressBookUI/AddressBookUI.h>
#import <QuartzCore/QuartzCore.h>
#import "TFABAddressBook.h"

@implementation AmbigousContactTableViewCell 
@synthesize text;
@synthesize detailText;
@synthesize lastModified;
@end

@implementation AmbigousContactConflictResolverViewController

@synthesize contactName1;
@synthesize contactName2;
@synthesize contact;
@synthesize tableView;
@synthesize titleView;

- (IBAction)done:(id)sender {
	TFRecord *record = [contact.ambigousContactMatches objectAtIndex:[self.tableView indexPathForSelectedRow].row];
	[contact resolveConflictWithAddressbookRecordId:[record uniqueId]];
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [contact.ambigousContactMatches count];
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    AmbigousContactTableViewCell *cell = [tv dequeueReusableCellWithIdentifier:@"ContactCell"];
	
	TFRecord *record = [contact.ambigousContactMatches objectAtIndex:indexPath.row];
	
	NSString *firstName = [record valueForProperty:kTFFirstNameProperty];
	NSString *lastName = [record valueForProperty:kTFLastNameProperty];
	NSString *company = [record valueForProperty:kTFOrganizationProperty];
	NSDate *modificationDate = [record valueForProperty:kTFModificationDateProperty];
	
	NSUInteger personType = [[record valueForProperty:kTFPersonFlags] integerValue];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.dateStyle = NSDateFormatterShortStyle;
	dateFormatter.timeStyle = NSDateFormatterShortStyle;
	
	if (personType == (personType & kTFShowAsCompany)) {
		if (company) {
			cell.text.text = company;
			if ([[TFAddressBook sharedAddressBook] defaultNameOrdering] == kTFFirstNameFirst) {
				cell.detailText.text = [NSString stringWithFormat:@"%@%@%@", firstName?firstName:@"", firstName?@" ":@"", lastName?lastName:@""];
			} else {
				cell.detailText.text = [NSString stringWithFormat:@"%@%@%@", lastName?lastName:@"", firstName?@" ":@"", firstName?firstName:@""];
			}
		} else if (firstName || lastName) {
			if ([[TFAddressBook sharedAddressBook] defaultNameOrdering] == kTFFirstNameFirst) {
				cell.text.text = [NSString stringWithFormat:@"%@%@%@", firstName?firstName:@"", firstName?@" ":@"", lastName?lastName:@""];
			} else {
				cell.text.text = [NSString stringWithFormat:@"%@%@%@", lastName?lastName:@"", firstName?@" ":@"", firstName?firstName:@""];
			}
		} else {
			cell.text.text = @"No Name";
			cell.text.font = [UIFont italicSystemFontOfSize:18.0];
		}
	} else {
		if (firstName || lastName) {
			if ([[TFAddressBook sharedAddressBook] defaultNameOrdering] == kTFFirstNameFirst) {
				cell.text.text = [NSString stringWithFormat:@"%@%@%@", firstName?firstName:@"", firstName?@" ":@"", lastName?lastName:@""];
			} else {
				cell.text.text = [NSString stringWithFormat:@"%@%@%@", lastName?lastName:@"", firstName?@" ":@"", firstName?firstName:@""];
			}
			cell.detailText.text = (company != nil)?company:@"No Company Specified";
			cell.detailText.font = (company != nil)?[UIFont systemFontOfSize:14.0]:[UIFont italicSystemFontOfSize:14.0];
		} else if (company) {
			cell.text.text = company;
		} else {
			cell.text.text = @"No Name";
			cell.text.font = [UIFont italicSystemFontOfSize:18.0];
		}
	}
	
	if (modificationDate) {
		cell.lastModified.text = [NSString stringWithFormat:@"Last Updated: %@", [dateFormatter stringFromDate:modificationDate]];
	} else {
		cell.lastModified.text = [NSString stringWithFormat:@"Last Updated: Unknown"];
	}
	
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.navigationItem.rightBarButtonItem.enabled = ([self.tableView indexPathForSelectedRow] != nil);
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	TFRecord *record = [contact.ambigousContactMatches objectAtIndex:indexPath.row];
	ABPersonViewController *picker = [[ABPersonViewController alloc] init];
	picker.displayedPerson = record.nativeObject;
	// Allow users to edit the person’s information
	picker.allowsEditing = NO;
	
	[self.navigationController pushViewController:picker animated:YES];
}

@end
