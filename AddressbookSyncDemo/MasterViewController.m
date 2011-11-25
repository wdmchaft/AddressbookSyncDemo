//
//  MasterViewController.m
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 23/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"
#import "Contact.h"
#import "AppDelegate.h"
#import "ShowContactDetails.h"
#import "UIAlertView+BlockExtensions.h"

///////// START PRIVATE API //////////
// This is really a private API store in the Contact class
@interface ContactMappingCache : NSObject {
@private
    NSDictionary *_mappings;
}
+ (ContactMappingCache *)sharedInstance;
- (NSString *)identifierForContact:(Contact *)contact;
- (void)setIdentifier:(NSString *)identifier forContact:(Contact *)contact;
- (void)removeIdentifierForContact:(Contact *)contact;
@end

///////// END PRIVATE API //////////

@interface MasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;
@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize managedObjectContext = __managedObjectContext;


- (IBAction)showPeoplePickerController:(id)sender {
	ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
    picker.peoplePickerDelegate = self;
	// Display only a person's phone, email, and birthdate
	NSArray *displayedItems = [NSArray arrayWithObjects:[NSNumber numberWithInt:kABPersonPhoneProperty], 
							   [NSNumber numberWithInt:kABPersonEmailProperty],
							   [NSNumber numberWithInt:kABPersonBirthdayProperty], nil];
	
	
	picker.displayedProperties = displayedItems;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		picker.modalPresentationStyle = UIModalPresentationFormSheet;
	}
	// Show the picker 
	[self presentModalViewController:picker animated:YES];
}

- (IBAction)destroyCache:(id)sender {
	for (Contact *contact in [[self fetchedResultsController] fetchedObjects]) {
		[[ContactMappingCache sharedInstance] removeIdentifierForContact:contact];
#warning We should probably be able to do this?
//		contact.addressbookIdentifier = nil;
	}
	
	[self.tableView reloadData];
	NSLog(@"Cache cleared");
}

- (void)reloadFetchedResults:(NSNotification*)note {
    NSError *error = nil;
	if (![[self fetchedResultsController] performFetch:&error]) {
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}		
    
	[self.tableView reloadData];
}

- (void)awakeFromNib
{
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
	    self.clearsSelectionOnViewWillAppear = NO;
	    self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
	}
    [super awakeFromNib];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];
	
	[self reloadFetchedResults:nil];
	// observe the app delegate telling us when it's finished asynchronously setting up the persistent store
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFetchedResults:) name:@"RefetchAllDatabaseData" object:[[UIApplication sharedApplication] delegate]];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
	return [sectionInfo numberOfObjects];
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	[self configureCell:cell atIndexPath:indexPath];
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the managed object for the given index path
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        // Save the context.
        NSError *error = nil;
        if (![context save:&error]) {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Contact *selectedObject = [[self fetchedResultsController] objectAtIndexPath:indexPath];
	
	if (selectedObject.addressbookRecord == NULL) {
		// Somthing is wrong, lets try to resolve it
		if (selectedObject.addressbookCacheState == kAddressbookCacheLoadFailed) {
			[[[UIAlertView alloc] initWithTitle:@"Unmatched contact Details" message:@"The contact failed to match with address book entry" completionBlock:^(NSUInteger buttonIndex) {
				switch(buttonIndex) {
					case 0: // Cancelled
						NSLog(@"Button 1");
						break;
					case 1: // Resolve Now
						NSLog(@"Button 2");
						break;
				}
			} cancelButtonTitle:@"Later" otherButtonTitles:@"Resolve Now"] show];
		} else if (selectedObject.addressbookCacheState == kAddressbookCacheLoadAmbigous) {
			[[[UIAlertView alloc] initWithTitle:@"Ambigous Contact Details" message:@"The details for this contact are ambigous" completionBlock:^(NSUInteger buttonIndex) {
				switch(buttonIndex) {
					case 0: // Cancelled
						NSLog(@"Button 1");
						break;
					case 1: // Resolve Now
						NSLog(@"Button 2");
						break;
				}
			} cancelButtonTitle:@"Later" otherButtonTitles:@"Resolve Now"] show];
		}
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
 	} else {
		UIViewController *personViewController = [ShowContactDetails viewControllerForDisplayingContact:selectedObject];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			//self.detailViewController
			UINavigationController *detailNavigationController = (UINavigationController *)[self.splitViewController.viewControllers lastObject];
			detailNavigationController.viewControllers = [NSArray arrayWithObject:personViewController];
		} else {
			[self.navigationController pushViewController:personViewController animated:YES];
		}
	}
/*
	if ([selectedObject findAddressbookRecord] != NULL) {
		UIViewController *personViewController = [ShowContactDetails viewControllerForDisplayingContact:selectedObject];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			//self.detailViewController
			UINavigationController *detailNavigationController = (UINavigationController *)[self.splitViewController.viewControllers lastObject];
			detailNavigationController.viewControllers = [NSArray arrayWithObject:personViewController];
		} else {
			[self.navigationController pushViewController:personViewController animated:YES];
		}
	} else {
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			//self.detailViewController
			UINavigationController *detailNavigationController = (UINavigationController *)[self.splitViewController.viewControllers lastObject];
			detailNavigationController.viewControllers = [NSArray arrayWithObject:self.detailViewController];
	        self.detailViewController.detailItem = selectedObject;
		} else {
	        self.detailViewController.detailItem = selectedObject;
			[self performSegueWithIdentifier:@"noDetails" sender:self];
		}
    }
 */
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"noDetails"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Contact *selectedObject = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:selectedObject];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    // Set up the fetched results controller.
    // Create the fetch request for the entity.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Contact" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastName" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObjects:sortDescriptor, nil];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    /*
	     Replace this implementation with code to handle the error appropriately.

	     abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	     */
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return __fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Contact *contact = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [contact compositeName];
	cell.detailTextLabel.text = contact.addressbookIdentifier?[NSString stringWithFormat:@"%d", contact.addressbookIdentifier]:@"Contact not found";
}

#pragma mark -
#pragma mark ABPeoplePickerNavigationControllerDelegate methods
// Displays the information of a selected person
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person
{
	[self dismissModalViewControllerAnimated:YES];
	
	// Check if we already have this contact in out object tree
	if ([Contact findContactForRecordId:ABRecordGetRecordID(person)] != nil) {
		[self performBlock:^{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Add Contact Failed" message:@"Contact already exists" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
			[alert show];
		} afterDelay:0.0f];
		return YES;
	}
	
	// Add this contact to the Object Graph
	Contact *contact = [Contact initContactWithAddressbookRecord:person];
	NSLog(@"Adding %@", [contact compositeName]);
	
	[(AppDelegate *)[UIApp delegate] saveContext];
	
	return NO;
}


// Does not allow users to perform default actions such as dialing a phone number, when they select a person property.
- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person 
								property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
	return NO;
}


// Dismisses the people picker and shows the application when users tap Cancel. 
- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
	[self dismissModalViewControllerAnimated:YES];
}
@end
