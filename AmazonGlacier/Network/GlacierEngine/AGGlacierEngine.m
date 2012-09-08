//
//  AGGlacierEngine.m
//  AmazonGlacier
//
//  Created by Victor Ilyukevich on 8/25/12.
//  Copyright (c) 2012 Open Source Community. All rights reserved.
//

#import "AGGlacierEngine.h"
#import "AGCredentials.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

#define LIST_VAULTS_URL(__ACCOUNT_ID__) [NSString stringWithFormat:@"%@/vaults", __ACCOUNT_ID__]

@interface AGGlacierEngine ()

// Signature Version 4
// http://docs.amazonwebservices.com/general/latest/gr/signature-version-4.html
- (void)signOperation:(MKNetworkOperation *)operation;
@property (nonatomic, copy) NSString *accountID;
@property (nonatomic, copy) NSString *accessKey;
@property (nonatomic, copy) NSString *secretKey;
@property (nonatomic, copy) NSString *regionName;
@end

@implementation AGGlacierEngine

+ (id)sharedEngine {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] initWithRegion:@"us-east-1"
                                           accountID:kAmazonAccountID
                                           accessKey:kAmazonAccessKey
                                           secretKey:kAmazonSecretKey];
    });
    return _sharedObject;
}

- (id)initWithRegion:(NSString *)region
           accountID:(NSString *)accountID
           accessKey:(NSString *)accessKey
           secretKey:(NSString *)secretKey {
    NSDictionary *headers = @{ @"x-amz-glacier-version" : @"2012-06-01" };
    self = [super initWithHostName:[NSString stringWithFormat:@"glacier.%@.amazonaws.com", region]
                customHeaderFields:headers];
    if (self) {
        self.regionName = region;
        self.accountID = accountID;
        self.accessKey = accessKey;
        self.secretKey = secretKey;
    }
    return self;
}

#pragma mark - Requests

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
        completionBlock([json objectForKey:@"VaultList"], [json objectForKey:@"marker"]);
    } onError:errorBlock];
    [self signOperation:op];

    [self enqueueOperation:op];
    return op;
}

#pragma mark - Signing

- (void)signOperation:(MKNetworkOperation *)operation {
    NSDate *date = [NSDate date];

    // set date header
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];

    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *dateStamp = [dateFormatter stringFromDate:date];

    [dateFormatter setDateFormat:@"yyyyMMdd'T'HHmmss'Z'"];
    NSString *dateTime = [dateFormatter stringFromDate:date];


    [operation addHeaders:@{ @"X-Amz-Date" : dateTime,
                             @"Host" : operation.readonlyRequest.URL.host }];

    // Task 1: Create a Canonical Request
    NSString *canonicalRequest = [AGGlacierEngine canonicalRequestForOperation:operation];
    DLog(@"Canonical request: %@", canonicalRequest);
    // Task 2: Create a String to Sign

    NSString *scope = [NSString stringWithFormat:
                       @"%@/%@/glacier/aws4_request",
                       dateStamp,
                       self.regionName];
    NSString *stringToSign = [NSString stringWithFormat:
                              @"AWS4-HMAC-SHA256\n%@\n%@\n%@",
                              dateTime,
                              scope,
                              [[self class] hexEncode:[[self class] hashString:canonicalRequest]]];
    DLog(@"String to sign: %@", stringToSign);

    // Task 3: Create a Signature
    // AWS4 uses a series of derived keys, formed by hashing different pieces of data
    NSString *kSecret   = [NSString stringWithFormat:@"%@%@", @"AWS4", self.secretKey];
    NSData   *kDate     = [[self class] sha256HMacWithData:[dateStamp dataUsingEncoding:NSUTF8StringEncoding] withKey:[kSecret dataUsingEncoding:NSUTF8StringEncoding]];
    NSData   *kRegion   = [[self class] sha256HMacWithData:[self.regionName dataUsingEncoding:NSASCIIStringEncoding] withKey:kDate];
    NSData   *kService  = [[self class] sha256HMacWithData:[@"glacier" dataUsingEncoding:NSUTF8StringEncoding] withKey:kRegion];
    NSData   *kSigning  = [[self class] sha256HMacWithData:[@"aws4_request" dataUsingEncoding:NSUTF8StringEncoding] withKey:kService];

    NSData *signature = [[self class] sha256HMacWithData:[stringToSign dataUsingEncoding:NSUTF8StringEncoding] withKey:kSigning];
    NSString *signingCredentials = [NSString stringWithFormat:@"%@/%@", self.accessKey, scope];
    NSString *credentialsAuthorizationHeader   = [NSString stringWithFormat:@"Credential=%@", signingCredentials];
    NSString *signedHeadersAuthorizationHeader = [NSString stringWithFormat:
                                                  @"SignedHeaders=%@",
                                                  [[self class] getSignedHeadersForOperation:operation]];
    NSString *signatureAuthorizationHeader = [NSString stringWithFormat:@"Signature=%@",
                                              [[self class] hexEncode:[[NSString alloc] initWithData:signature
                                                                                            encoding:NSASCIIStringEncoding]]];
    NSString *authorization = [NSString stringWithFormat:
                               @"AWS4-HMAC-SHA256 %@, %@, %@",
                               credentialsAuthorizationHeader,
                               signedHeadersAuthorizationHeader,
                               signatureAuthorizationHeader];
    [operation addHeaders:@{ @"Authorization" : authorization }];
}


+ (NSString *)canonicalRequestForOperation:(MKNetworkOperation *)operation {
    /*
     CanonicalRequest =
        HTTPRequestMethod + '\n' +
        CanonicalURI + '\n' +
        CanonicalQueryString + '\n' +
        CanonicalHeaders + '\n' +
        SignedHeaders + '\n' +
        HexEncode(Hash(Payload))
     */
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"%@\n", operation.readonlyRequest.HTTPMethod];
    [result appendFormat:@"%@\n", operation.readonlyRequest.URL.path];
     // TODO: should be canonical
    [result appendFormat:@"%@\n", operation.readonlyRequest.URL.query];
    /*
     CanonicalHeaders =
        CanonicalHeadersEntry0 + CanonicalHeadersEntry1 + ... + CanonicalHeadersEntryN

     CanonicalHeadersEntry =
        LOWERCASE(HeaderName) + ':' + TRIM(HeaderValue) + '\n'
     */
    NSDictionary *headers = operation.readonlyRequest.allHTTPHeaderFields;
    NSMutableArray *sortedHeaders = [NSMutableArray arrayWithArray:[headers allKeys]];
    [sortedHeaders sortUsingSelector:@selector(caseInsensitiveCompare:)];
    NSMutableString *headerString = [NSMutableString string];
    for (NSString *header in sortedHeaders) {
        [headerString appendString:[header lowercaseString]];
        [headerString appendString:@":"];
        [headerString appendString:[headers valueForKey:header]];
        [headerString appendString:@"\n"];
    }
    [result appendFormat:@"%@\n", headerString];

    // SignedHeaders
    [result appendFormat:@"%@\n", [[self class] getSignedHeadersForOperation:operation]];

    // HexEncode(Hash(Payload))
    NSString *bodyString = [[NSString alloc] initWithData:operation.readonlyRequest.HTTPBody
                                                 encoding:NSUTF8StringEncoding];
    NSString* hashString = [[self class] hexEncode:[[self class] hashString:bodyString]];
    [result appendFormat:@"%@", hashString];

    return result;
}

+ (NSString *)getSignedHeadersForOperation:(MKNetworkOperation *)operation {
    NSDictionary *headers = operation.readonlyRequest.allHTTPHeaderFields;
    NSMutableArray *sortedHeaders = [NSMutableArray arrayWithArray:[headers allKeys]];
    [sortedHeaders sortUsingSelector:@selector(caseInsensitiveCompare:)];

    return [[sortedHeaders componentsJoinedByString:@";"] lowercaseString];
}


#pragma mark -

+ (NSString *)hexEncode:(NSString *)string {
    NSUInteger len    = [string length];
    unichar    *chars = malloc(len * sizeof(unichar));

    [string getCharacters:chars];

    NSMutableString *hexString = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i < len; i++) {
        if ((int)chars[i] < 16) {
            [hexString appendString:@"0"];
        }
        [hexString appendString:[NSString stringWithFormat:@"%x", chars[i]]];
    }
    free(chars);

    return hexString;
}

+(NSString *)hashString:(NSString *)stringToHash {
    return [[NSString alloc] initWithData:[self hash:[stringToHash dataUsingEncoding:NSUTF8StringEncoding]] encoding:NSASCIIStringEncoding];
}

+ (NSData *)hash:(NSData *)dataToHash {
    const void    *cStr = [dataToHash bytes];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];

    CC_SHA256(cStr, [dataToHash length], result);

    return [[NSData alloc] initWithBytes:result length:CC_SHA256_DIGEST_LENGTH];
}

+ (NSData *)sha256HMacWithData:(NSData *)data withKey:(NSData *)key {
    CCHmacContext context;

    CCHmacInit(&context, kCCHmacAlgSHA256, [key bytes], [key length]);
    CCHmacUpdate(&context, [data bytes], [data length]);

    unsigned char digestRaw[CC_SHA256_DIGEST_LENGTH];
    NSInteger     digestLength = CC_SHA256_DIGEST_LENGTH;

    CCHmacFinal(&context, digestRaw);

    return [NSData dataWithBytes:digestRaw length:digestLength];
}


@end
