//
//  AGGlacierEngine.m
//  AmazonGlacier
//
//  Created by Victor Ilyukevich on 8/25/12.
//  Copyright (c) 2012 Open Source Community. All rights reserved.
//

#import "AGGlacierEngine.h"
#import "AmazonAuthUtils.h"
#import "AmazonCredentials.h"

#define LIST_VAULTS_URL(__ACCOUNT_ID__) [NSString stringWithFormat:@"%@/vaults", __ACCOUNT_ID__]

@interface AGGlacierEngine ()

// Signature Version 4
// http://docs.amazonwebservices.com/general/latest/gr/signature-version-4.html
- (void)signOperation:(MKNetworkOperation *)operation;
@property (nonatomic, copy) NSString *accountID;
@property (nonatomic, strong) AmazonCredentials *amazonCredentials;
@end

@implementation AGGlacierEngine


- (id)initWithHostName:(NSString *)hostName apiPath:(NSString *)apiPath customHeaderFields:(NSDictionary *)headers {
    self = [super initWithHostName:hostName apiPath:apiPath customHeaderFields:headers];
#warning remove creadentials before commit
    self.accountID = @"6114-1956-6122";
    self.amazonCredentials = [[AmazonCredentials alloc] initWithAccessKey:@"AKIAJUQQW4VKDV4LLK3Q"
                                                            withSecretKey:@"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"]
    return self;
}

- (MKNetworkOperation *)listOfVaultsWithLimit:(NSUInteger)limit
                                       marker:(NSString *)marker
                                 onCompletion:(VaultsResponseBlock)completionBlock
                                      onError:(MKNKErrorBlock)errorBlock {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (limit) [params setObject:[NSNumber numberWithUnsignedInteger:limit]
                          forKey:@"limit"];
    if (marker) [params setObject:marker forKey:@"marker"];
    MKNetworkOperation *op = [self operationWithPath:LIST_VAULTS_URL(self.accountID)
                                              params:params];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        id json = [completedOperation responseJSON];
        DLog(@"List of vaults: \n%@", json);
        completionBlock([json objectForKey:@"VaultList"], [json objectForKey:@"marker"]);
    } onError:errorBlock];
    [self signOperation:op];

    [self enqueueOperation:op];
    return op;
}

#pragma mark - Signing

- (void)signOperation:(MKNetworkOperation *)operation {
//    [AmazonAuthUtils signOperationV4:operation withCredentials:self.amazonCredentials];

    // Task 1: Create a Canonical Request
    NSString *canonicalRequest = [AGGlacierEngine canonicalRequestForOperation:operation];
    DLog(@"Canonical request: %@", canonicalRequest);
    // Task 2: Create a String to Sign

    // Task 3: Create a Signature

}

+ (NSString *)canonicalRequestForOperation:(MKNetworkOperation *)operation {
    NSMutableString *result;

    return result;
}

@end
