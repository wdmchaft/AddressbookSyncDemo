//
//  SelectContactSheetController.h
//  AddressbookSyncDemo
//
//  Created by Tom Fewster on 28/11/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/ABPeoplePickerView.h>

@interface SelectContactSheetController : NSObject

@property (nonatomic, strong) IBOutlet NSWindow *documentWindow;
@property (nonatomic, strong) IBOutlet NSPanel *objectSheet;
@property (nonatomic, strong) IBOutlet ABPeoplePickerView *peoplePicker;

- (IBAction)addContact:(id)sender;
- (IBAction)cancelOperation:sender;
- (IBAction)complete:sender;

@end
