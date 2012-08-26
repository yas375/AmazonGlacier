//
//  AGAppDelegate.m
//  AmazonGlacier
//
//  Created by Victor Ilyukevich on 8/25/12.
//  Copyright (c) 2012 Open Source Community. All rights reserved.
//

#import "AGAppDelegate.h"

#import "AGGlacierEngine.h"

@interface AGAppDelegate ()
@property (nonatomic, strong) AGGlacierEngine *engine;

@end

@implementation AGAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSDictionary *headers = @{ @"x-amz-glacier-version" : @"2012-06-01" };
    self.engine = [[AGGlacierEngine alloc] initWithHostName:@"glacier.us-east-1.amazonaws.com"
                                         customHeaderFields:headers];
    [self.engine listOfVaultsWithLimit:30
                                marker:nil
                          onCompletion:^(NSDictionary *items, NSString *marker) {
                              NSLog(@"ARRRR!!");
                          } onError:^(NSError *error) {
                              NSLog(@"Error: %@", error);
                          }];
    
}

@end
