//
//  AGGlacierEngine.h
//  AmazonGlacier
//
//  Created by Victor Ilyukevich on 8/25/12.
//  Copyright (c) 2012 Open Source Community. All rights reserved.
//

#import "MKNetworkKit.h"

#pragma mark - Responses
/*
 marker
The vaultARN that represents where to continue pagination of the results. You use the marker in another List Vaults request to obtain more vaults in the list. If there are no more vaults, this value is null.

Type: String
 */
typedef void (^VaultsResponseBlock)(NSArray *items, NSString *marker);


@interface AGGlacierEngine : MKNetworkEngine

+ (id)sharedEngine;
/*
 Marker
 A string used for pagination. marker specifies the vault ARN after which the listing of vaults should begin. (The vault specified by marker is not included in the returned list.) Get the marker value from a previous List Vaults response. You need to include the marker only if you are continuing the pagination of results started in a previous List Vaults request. Specifying an empty value ("") for the marker returns a list of vaults starting from the first vault.

 Type: String
 */
- (MKNetworkOperation *)listOfVaultsWithLimit:(NSUInteger)limit
                                       marker:(NSString *)marker
                                 onCompletion:(VaultsResponseBlock)completionBlock
                                      onError:(MKNKErrorBlock)errorBlock;
@end
