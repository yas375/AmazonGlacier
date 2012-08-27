//
//  AGAppDelegate.m
//  AmazonGlacier
//
//  Created by Victor Ilyukevich on 8/25/12.
//  Copyright (c) 2012 Open Source Community. All rights reserved.
//

#import "AGAppDelegate.h"
#import "AGGlacierEngine.h"
#import "AGCredentials.h"

@interface AGAppDelegate ()
@property (nonatomic, strong) AGGlacierEngine *engine;

@end

@implementation AGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.engine = [[AGGlacierEngine alloc] initWithRegion:@"us-east-1"
                                                accountID:kAmazonAccountID
                                                accessKey:kAmazonAccessKey
                                                secretKey:kAmazonSecretKey];
    [self.engine listOfVaultsWithLimit:30
                                marker:nil
                          onCompletion:^(NSDictionary *items, NSString *marker) {
                              NSLog(@"ARRRR!!");
                          } onError:^(NSError *error) {
                              NSLog(@"Error: %@", error);
                          }];
    
}

@end
