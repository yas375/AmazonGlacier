//
//  AGAppDelegate.m
//  AmazonGlacier
//
//  Created by Victor Ilyukevich on 8/25/12.
//  Copyright (c) 2012 Open Source Community. All rights reserved.
//

#import "AGAppDelegate.h"
#import "AGGlacierEngine.h"
#import "AGMasterViewController.h"

@interface AGAppDelegate ()
@property (nonatomic,strong) IBOutlet AGMasterViewController *masterViewController;
@property (nonatomic, strong) AGGlacierEngine *engine;
@end

@implementation AGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.masterViewController = [[AGMasterViewController alloc] initWithNibName:@"AGMasterViewController"
                                                                         bundle:nil];
    [self.window.contentView addSubview:self.masterViewController.view];
    self.masterViewController.view.frame = [(NSView *)self.window.contentView bounds];
}

@end
