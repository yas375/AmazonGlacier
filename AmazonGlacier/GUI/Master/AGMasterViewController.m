//
//  AGMasterViewController.m
//  AmazonGlacier
//
//  Created by Victor Ilyukevich on 9/7/12.
//  Copyright (c) 2012 Open Source Community. All rights reserved.
//

#import "AGMasterViewController.h"

static NSString *const kAGColumnName = @"VaultNameColumn";

@interface AGMasterViewController ()
@property (nonatomic, strong) NSMutableArray *vaults;

@property (weak) IBOutlet NSTableView *tableView;
@end

@implementation AGMasterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self ) {
        self.vaults = [NSMutableArray array];
        [[AGGlacierEngine sharedEngine] listOfVaultsWithLimit:30
                                                       marker:nil
                                                 onCompletion:^(NSArray *items, NSString *marker)
         {
             [self.vaults addObjectsFromArray:items];
             [self.tableView reloadData];
         } onError:^(NSError *error) {
             [NSAlert showWithError:error];
         }];
    }
    return self;
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.vaults count];
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];

    NSDictionary *vault = [self.vaults objectAtIndex:row];
    if ([tableColumn.identifier isEqualToString:kAGColumnName]) {
        cellView.textField.stringValue = [vault valueForKey:@"VaultName"];
        return cellView;
    }
    return cellView;
}

#pragma mark - NSTableViewDelegate


@end
