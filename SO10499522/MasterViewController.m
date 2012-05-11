//
//  MasterViewController.m
//  SO10499522
//
//  Created by Stig Brautaset on 05/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <SBJson/SBJson.h>
#import "MasterViewController.h"

#import "DetailViewController.h"

@interface MasterViewController () <SBJsonStreamParserAdapterDelegate, NSURLConnectionDataDelegate> {
    NSMutableArray *_objects;
    SBJsonStreamParser *parser;
    SBJsonStreamParserAdapter *adapter;
}

- (void)loadDataFromUrl:(NSURL*)url;
@end

@implementation MasterViewController

@synthesize detailViewController = _detailViewController;


- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}



- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;

    self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers lastObject] topViewController];

    NSURL *url = [NSURL URLWithString:@"http://www.kb.dk/tekst/mobil/aabningstider_en.json"];
    [self loadDataFromUrl:url];
}

- (void)loadDataFromUrl:(NSURL *)url {
    adapter = [[SBJsonStreamParserAdapter new] init];
    adapter.delegate = self;
    adapter.levelsToSkip = 1;

    parser = [[SBJsonStreamParser alloc] init];
    parser.delegate = adapter;

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [connection start];
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    _objects = nil;
    parser = nil;
    adapter = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

- (void)insertNewObject:(id)sender
{
    if (!_objects) {
        _objects = [[NSMutableArray alloc] init];
    }
    [_objects insertObject:[NSDate date] atIndex:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    NSDictionary *object = [_objects objectAtIndex:indexPath.row];
    cell.textLabel.text = [object objectForKey:@"name"];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        NSDate *object = [_objects objectAtIndex:indexPath.row];
        self.detailViewController.detailItem = object;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSDate *object = [_objects objectAtIndex:indexPath.row];
        [[segue destinationViewController] setDetailItem:object];
    }
}

#pragma mark SBJsonStreamParserAdapterDelegate

- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    NSLog(@"Unexpectedly called with array: %@", array);
}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
    if (!_objects) _objects = [[NSMutableArray alloc] init];
    [_objects addObject:dict];
    [(UITableView *)self.view reloadData];
}

#pragma mark NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"Got %u bytes of data", data.length);
    switch ([parser parse: data]) {
        case SBJsonStreamParserComplete:
            NSLog(@"Parsed a complete JSON document");
            break;
        case SBJsonStreamParserWaitingForData:
            NSLog(@"Didn't get all the JSON yet... still waiting for more");
            break;
        case SBJsonStreamParserError:
            NSLog(@"Error: %@ - cancelling download", parser.error);
            [connection cancel];
            break;
    }
}

@end