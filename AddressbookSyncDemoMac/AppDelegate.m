//
//  AppDelegate.m
//  AddressbookSyncDemoMac
//
//  Created by Tom Fewster on 27/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "Contact.h"
#import "NSObject+BlockExtensions.h"
#import "TFABAddressBook.h"
#import "AmbigousContactResolverViewController.h"
#import "UnresolvedContactResolverViewController.h"

@implementation AppDelegate

@synthesize window = _window;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize personView;
@synthesize contactSelectionIndex;
@synthesize arrayController;
@synthesize searchFilter;
@synthesize ambigousContactResolver;
@synthesize unresolvedContactResolver;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveAction:) name:NSApplicationWillResignActiveNotification object:nil];
	[TFAddressBook sharedAddressBook];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactUpdated:) name:kTFDatabaseChangedExternallyNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contactUpdated:) name:kTFDatabaseChangedNotification object:nil];
}

/**
    Returns the directory the application uses to store the Core Data store file. This code uses a directory named "AddressbookSyncDemoMac" in the user's Library directory.
 */
- (NSURL *)applicationFilesDirectory {

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *libraryURL = [[fileManager URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    return [libraryURL URLByAppendingPathComponent:@"AddressbookSyncDemo"];
}

/**
    Creates if necessary and returns the managed object model for the application.
 */
- (NSManagedObjectModel *)managedObjectModel {
    if (__managedObjectModel) {
        return __managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AddressbookSyncDemo" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return __managedObjectModel;
}

/**
    Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (__persistentStoreCoordinator) {
        return __persistentStoreCoordinator;
    }

    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:[NSArray arrayWithObject:NSURLIsDirectoryKey] error:&error];
        
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    else {
        if ([[properties objectForKey:NSURLIsDirectoryKey] boolValue] != YES) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]]; 
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"AddressbookSyncDemo.sqlite"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __persistentStoreCoordinator = coordinator;

    return __persistentStoreCoordinator;
}

/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
- (NSManagedObjectContext *)managedObjectContext {
    if (__managedObjectContext) {
        return __managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    __managedObjectContext = [[NSManagedObjectContext alloc] init];
    [__managedObjectContext setPersistentStoreCoordinator:coordinator];

    return __managedObjectContext;
}

/**
    Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
 */
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}

/**
    Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
 */
- (IBAction)saveAction:(id)sender {
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }

    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    // Save changes in the application's managed object context before the application terminates.

    if (!__managedObjectContext) {
        return NSTerminateNow;
    }

    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }

    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

- (void)resolveMissingContact:(Contact *)contact {
	if (contact.addressbookCacheState == kAddressbookCacheLoadFailed) {
		NSLog(@"Contact not found");
		[unresolvedContactResolver resolveConflict:contact];
		[personView setPerson:nil];
	} else if (contact.addressbookCacheState == kAddressbookCacheLoadAmbigous) {
		NSLog(@"Contact Ambigous");
		[ambigousContactResolver resolveConflict:contact];
		[personView setPerson:nil];
	} else if (contact.addressbookCacheState == kAddressbookCacheLoaded) {
		NSLog(@"Or contact has probably been deleted since we cached it");
		[contact updateManagedObjectWithAddressbookRecordDetails];
	} else if (contact.addressbookCacheState == kAddressbookCacheCurrentlyLoading) {
		// lets try again in a 1/2 a second
		[self performBlock:^{
			[self resolveMissingContact:contact];	
		} afterDelay:0.5];
	} else if (contact.addressbookCacheState == kAddressbookCacheLoaded && contact.addressbookRecord != NULL) {
		[personView setPerson:(ABPerson *)contact.addressbookRecord];
	}
}

- (void)setContactSelectionIndex:(NSIndexSet *)value {
	contactSelectionIndex = value;
	if ([contactSelectionIndex count] != 0) {
		Contact *contact = [[arrayController arrangedObjects] objectAtIndex:[contactSelectionIndex firstIndex]];
		if (contact.addressbookRecord == NULL) {
			// Somthing is wrong, lets try to resolve it
			[self resolveMissingContact:contact];
		} else {
			[personView setPerson:(ABPerson *)contact.addressbookRecord];
		}
	}
}

- (NSArray *)sortDescriptors {
	return [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sortTag2" ascending:YES]];
}

- (IBAction)toggelEdit:(NSButton *)button {
	if (personView.editing) {
		personView.editing = NO;
		if ([[Contact sharedAddressBook] hasUnsavedChanges]) {
			[[Contact sharedAddressBook] save];
		}
		button.title = @"Edit";
	} else {
		personView.editing = YES;
		button.title = @"Done";
	}
}

-(void)contactUpdated:(NSNotification *)notification {
	
	for (NSString *recordId in [[notification userInfo] objectForKey:kTFUpdatedRecords]) {
		Contact *contact = (Contact *)[Contact findContactForRecordId:recordId];
		if (contact) {
			NSLog(@"Our contact has been updated");
			[contact updateManagedObjectWithAddressbookRecordDetails];
		}
	}
	
	for (NSString *recordId in [[notification userInfo] objectForKey:kTFDeletedRecords]) {
		Contact *contact = (Contact *)[Contact findContactForRecordId:recordId];
		if (contact) {
			NSLog(@"Our contact has been removed from the addressbook");
			[contact updateManagedObjectWithAddressbookRecordDetails];
		}
	}
}


@end
