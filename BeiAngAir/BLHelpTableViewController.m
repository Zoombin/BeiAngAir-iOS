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
#import "BLAPIClient.h"
#import "BLBindPhoneViewController.h"
#import "BLUserInfo.h"

static CGFloat const heightOfHeader = 20;
static CGFloat const heightOfCell = 45;
static NSString * const sectionHeaderTitle = @"sectionHeaderTitle";
static NSString * const sectionTitle = @"sectionTitle";
static NSString * const sectionSelector = @"sectionSelector";

static NSString * const sectionHeaderTitleUser = @"用户";
static NSString * const sectionHeaderTitleBindPhone = @"绑定手机";
static NSString * const sectionHeaderTitleAbout = @"关于";
static NSString * const sectionHeaderTitleSystem = @"系统";

@interface BLHelpTableViewController ()

@property (readwrite) NSMutableArray *data;
@property (readwrite) BLUserInfo *userInfo;

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
	
	_data = [NSMutableArray array];
	
	if ([[BLAPIClient shared] isSessionValid]) {
		[_data insertObject:@{sectionHeaderTitle : sectionHeaderTitleUser, sectionTitle : @"注销登录", sectionSelector : NSStringFromSelector(@selector(signout))} atIndex:0];
		
		[[BLAPIClient shared] userInfoWithBlock:^(NSDictionary *attributes, NSError *error) {
			if (!error) {
				_userInfo = [[BLUserInfo alloc] initWithAttributes:attributes];
				SEL selector = @selector(bindPhone);
				if (_userInfo.phone.length) {
					selector = @selector(doNothing);
				}
				[_data insertObject:@{sectionHeaderTitle : sectionHeaderTitleBindPhone, sectionTitle : sectionHeaderTitleBindPhone, sectionSelector : NSStringFromSelector(selector)} atIndex:0];
				[self.tableView reloadData];
			}
			[self.tableView reloadData];
		}];
	}
	[_data addObject:@{sectionHeaderTitle : sectionHeaderTitleAbout, sectionTitle : @"关于我们", sectionSelector : NSStringFromSelector(@selector(about))}];
	[_data addObject:@{sectionHeaderTitle : sectionHeaderTitleSystem, sectionTitle : @"检查更新", sectionSelector : NSStringFromSelector(@selector(checkVersion))}];
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dismiss {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doNothing {
	
}

- (void)signout {
	if (![[BLAPIClient shared] isSessionValid]) return;
	[self displayHUD:@"注销中..."];
	[[BLAPIClient shared] logoutWithBlock:^(NSError *error) {
		[self hideHUD:YES];
		if (!error) {
			[self displayHUDTitle:nil message:@"注销成功" duration:1];
			[self performSelector:@selector(dismiss) withObject:nil afterDelay:1];
		} else {
			[self displayHUDTitle:nil message:error.userInfo[BL_ERROR_MESSAGE_IDENTIFIER]];
		}
	}];
}

- (void)about {
	BLAboutViewController *aboutViewController = [[BLAboutViewController alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:aboutViewController animated:YES];
}

- (void)bindPhone {
	BLBindPhoneViewController *bindPhoneViewController = [[BLBindPhoneViewController alloc] initWithNibName:nil bundle:nil];
	[self.navigationController pushViewController:bindPhoneViewController animated:YES];
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
	UITableViewCell	*cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[UITableViewCell identifier]];
	NSDictionary *dictionary = _data[indexPath.section];
	NSString *headerTitle = dictionary[sectionHeaderTitle];
	cell.textLabel.text = dictionary[sectionTitle];

	NSString *info = nil;
	if ([headerTitle isEqualToString:sectionHeaderTitleUser]) {
			info = [NSString stringWithFormat:@"当前用户:%@", [[BLAPIClient shared] username]];
	} else if ([headerTitle isEqualToString:sectionHeaderTitleAbout]) {
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	} else if ([headerTitle isEqualToString:sectionHeaderTitleSystem]) {
		info = [NSString stringWithFormat:@"当前版本:%@", [[BLAPIClient shared] appVersion]];
	} else if ([headerTitle isEqualToString:sectionHeaderTitleBindPhone]) {
		if (_userInfo.phone.length) {
			info = _userInfo.phone;
		} else {
			info = @"未绑定";
		}
	}
	
	if (info) {
		UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width - 15, heightOfCell)];
		label.textAlignment = NSTextAlignmentRight;
		label.text = info;
		label.font = [UIFont systemFontOfSize:13];
		[cell addSubview:label];
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
