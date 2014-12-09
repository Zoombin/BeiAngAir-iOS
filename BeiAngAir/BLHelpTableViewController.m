//
//  BLHelpTableViewController.m
//  BeiAngAir
//
//  Created by zhangbin on 12/9/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BLHelpTableViewController.h"
#import "UITableViewCell+ZBUtilities.h"
#import "BLAboutViewController.h"

const CGFloat heightOfHeader = 20;
const CGFloat heightOfCell = 35;
const NSString *sectionHeaderTitle = @"sectionHeaderTitle";
const NSString *sectionTitle = @"sectionTitle";
const NSString *sectionSelector = @"sectionSelector";

@interface BLHelpTableViewController ()

@property (readwrite) NSArray *data;

@end

@implementation BLHelpTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor themeBlue];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
	
	UIImage *image = [UIImage imageNamed:@"home_logo"];
	UIImageView *logoImageView = [[UIImageView alloc] initWithImage:image];
	logoImageView.frame = CGRectMake(0, 0, self.tableView.frame.size.width, image.size.height);
	logoImageView.contentMode = UIViewContentModeCenter;
	self.tableView.tableHeaderView = logoImageView;
	
	_data = @[@{sectionHeaderTitle : @"用户", sectionTitle : @"注销登录", sectionSelector : NSStringFromSelector(@selector(signout))},
			  @{sectionHeaderTitle : @"关于", sectionTitle : @"关于我们", sectionSelector : NSStringFromSelector(@selector(about))},
			  @{sectionHeaderTitle : @"系统", sectionTitle : @"检查更新", sectionSelector : NSStringFromSelector(@selector(checkVersion))}
			  ];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dismiss {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)signout {
	NSLog(@"signout");
}

- (void)about {
	BLAboutViewController *aboutViewController = [[BLAboutViewController alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:aboutViewController animated:YES];
}

- (void)checkVersion {
	NSLog(@"checkVersion");
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, heightOfHeader)];
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, view.frame.size.width, view.frame.size.height)];
	label.font = [UIFont systemFontOfSize:13];
	NSDictionary *dictionary = _data[section];
	label.text = dictionary[sectionHeaderTitle];
	[view addSubview:label];
	return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return heightOfHeader;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 1;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return heightOfCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[UITableViewCell identifier]];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[UITableViewCell identifier]];
	}
	NSDictionary *dictionary = _data[indexPath.section];
	cell.textLabel.text = dictionary[sectionTitle];
	
	UILabel *label = nil;
	if (indexPath.section == 0) {
		label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width - 15, heightOfCell)];
#warning TODO
	} else if (indexPath.section == 1) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else {
		
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSDictionary *dictionary = _data[indexPath.section];
	NSString *selectorString = dictionary[sectionSelector];
	SEL selector = NSSelectorFromString(selectorString);
	[self performSelector:selector withObject:nil];
}


@end
