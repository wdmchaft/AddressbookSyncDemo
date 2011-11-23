//
//  ShowContactDetails.h
//  ShootStudio
//
//  Created by Tom Fewster on 22/09/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@class Contact;

@interface ShowContactDetails : NSObject <ABPersonViewControllerDelegate, ABNewPersonViewControllerDelegate, ABUnknownPersonViewControllerDelegate> {
}

@property (nonatomic, strong) UIViewController *parentViewController;
@property (nonatomic, weak) Contact *contact;

+ (UIViewController *)viewControllerForDisplayingContact:(Contact *)contact;

@end
