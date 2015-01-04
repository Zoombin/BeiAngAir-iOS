//
//  BLDeviceListViewController.m
//  TCLAir
//
//  Created by yang on 4/11/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BLDeviceListViewController.h"
#import "GlobalDefine.h"
#import "BLSmartConfigViewController.h"
#import "BLDeviceControlViewController.h"
#import "BLDeviceEditViewController.h"
#import "BLAPIClient.h"
#import "ELDevice.h"

@interface BLDeviceListViewController () <UIAlertViewDelegate>

@property (readwrite) NSArray *devices;

@end

@implementation BLDeviceListViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = NSLocalizedString(@"设备列表", nil);
	self.navigationController.navigationBarHidden = NO;
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
	
	self.refreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 100.0f)];
	[self.refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
	[self.tableView.tableHeaderView addSubview:self.refreshControl];
	
	//背景颜色
    [self.view setBackgroundColor:RGB(246.0f, 246.0f, 246.0f)];
    
    //底部的添加设备
	CGRect viewFrame = CGRectZero;
    UIButton *btnAddDevice = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 49 - 43, self.view.frame.size.width, 43)];
    //button(ALL,Senior,Ordinary)显示数据
    //背景颜色
    btnAddDevice.backgroundColor = [UIColor whiteColor];
    //button增加方法
    [btnAddDevice addTarget:self action:@selector(addNewDevice) forControlEvents:UIControlEventTouchUpInside];
    viewFrame.origin.x = self.view.frame.size.width / 2.f - 70;
    viewFrame.origin.y = 0;
    viewFrame.size.width = 80;
    viewFrame.size.height = 43;
    UILabel *label = [[UILabel alloc] initWithFrame:viewFrame];
    [label setText:NSLocalizedString(@"DeviceListViewControllerAddText", nil)];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setNumberOfLines:1];
    [label setTextColor:RGB(0x13, 0xb3, 0x5c)];
    CGSize size = [NSLocalizedString(@"DeviceListViewControllerAddText", nil) sizeWithFont:label.font constrainedToSize:CGSizeMake(MAXFLOAT, label.frame.size.height) lineBreakMode:NSLineBreakByWordWrapping];
    viewFrame.origin.x = self.view.frame.size.width / 2.f - size.width / 2.f - 5.f;
    viewFrame.size.width = size.width;
    [label setFrame:viewFrame];
    [btnAddDevice addSubview:label];
    //图片
    UIImage *image = [UIImage imageNamed:@"enter"];
    viewFrame.origin.x = label.frame.size.width + label.frame.origin.x + 5;
    viewFrame.origin.y = (btnAddDevice.frame.size.height - image.size.height) / 2.f;
    viewFrame.size.width = image.size.width;
    viewFrame.size.height = image.size.height;
    UIImageView *addImageView = [[UIImageView alloc] initWithFrame:viewFrame];
    addImageView.image = image;
    [btnAddDevice addSubview:addImageView];
    //加入显示
    [self.view addSubview:btnAddDevice];
}

- (void)viewDidAppear:(BOOL)animated {
	[self refresh];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:BEIANG_NOTIFICATION_IDENTIFIER_ADDED_DEVICE object:nil];
}

- (void)refresh {
	[self displayHUD:NSLocalizedString(@"加载中...", nil)];
	[[BLAPIClient shared] getBindWithBlock:^(NSArray *multiAttributes, NSError *error) {
		[self hideHUD:YES];
		[self.refreshControl endRefreshing];
		if (!error) {
			_devices = [ELDevice multiWithAttributesArray:multiAttributes];
			[self.tableView reloadData];
		} else {
			NSLog(@"error: %@", error.userInfo[BL_ERROR_MESSAGE_IDENTIFIER]);
		}
	}];
}

- (void)back {
	[self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)addNewDevice {
	BLSmartConfigViewController *controller = [[BLSmartConfigViewController alloc] initWithNibName:nil bundle:nil];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)editDeviceAvatar:(UITapGestureRecognizer *)recognizer {
	ELDevice *device = _devices[recognizer.view.tag];
	BLDeviceEditViewController *controller = [[BLDeviceEditViewController alloc] init];
	controller.device = device;
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
	[self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - UITableView Datasource Delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _devices.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	ELDevice *device = _devices[indexPath.row];
	return [device isOnline];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"删除设备" message:@"确定要删除吗？" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
		alert.tag = indexPath.row;
		[alert show];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"TclAirDeviceListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
	cell.backgroundColor = [UIColor whiteColor];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	cell.detailTextLabel.numberOfLines = 0;
	
	ELDevice *device = _devices[indexPath.row];
	cell.imageView.image = [device avatar];
	cell.imageView.userInteractionEnabled = YES;
	cell.imageView.tag = indexPath.row;
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editDeviceAvatar:)];
	[cell.imageView addGestureRecognizer:tapGestureRecognizer];
	cell.textLabel.text = [device displayName];

	NSMutableString *details = [NSMutableString stringWithString:[device displayStatus]];
	if ([device isOnline]) {
		if ([device hours] && [device minutes]) {
			[details appendFormat:@"\n已运行%@小时%@分钟", [device hours], [device minutes]];
		}
	}
	
	NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:details];
	if ([[device hours] integerValue] >= 50) {
		NSAttributedString *subString = [[NSAttributedString alloc] initWithString:NSLocalizedString(@" 请清洗", nil) attributes:@{NSForegroundColorAttributeName : [UIColor redColor], NSFontAttributeName : [UIFont systemFontOfSize:13]}];
		[attributedString appendAttributedString:subString];
	}
	cell.detailTextLabel.attributedText = attributedString;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	ELDevice *device = _devices[indexPath.row];
	if ([device isOnline]) {
		BLDeviceControlViewController *controller = [[BLDeviceControlViewController alloc] init];
		controller.device = device;
		[self.navigationController pushViewController:controller animated:YES];
	} else {
		[self displayHUDTitle:nil message:NSLocalizedString(@"设备不在线", nil) duration:1];
	}
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != alertView.cancelButtonIndex) {
		ELDevice *device = _devices[alertView.tag];
		NSLog(@"role: %@", device.role);
		if ([device isOwner]) {
			[[BLAPIClient shared] getDeviceData:device.ID withBlock:^(BOOL validForReset, NSError *error) {
				if (!error) {
					if (validForReset) {
						[[BLAPIClient shared] resetDevice:device.ID withBlock:^(NSError *error) {
							if (!error) {
								[self displayHUDTitle:@"复位成功" message:@"该设备已与账号解绑"];
								_devices = nil;
								[self.tableView reloadData];
								[self refresh];
							} else {
								[self displayHUDTitle:@"复位失败" message:error.userInfo[BL_ERROR_MESSAGE_IDENTIFIER]];
								[self.tableView reloadData];
							}
						}];
					} else {
						[self displayHUDTitle:@"复位失败" message:@"该设备不支持复位"];
						[self.tableView reloadData];
					}
				} else {
					[self displayHUDTitle:@"复位失败" message:@"请重新尝试"];
					[self.tableView reloadData];
				}
			}];
		} else {
			[self displayHUD:@"解绑中..."];
			[[BLAPIClient shared] unbindDevice:device.ID withBlock:^(NSError *error) {
				if (!error) {
					[self displayHUDTitle:@"解绑成功" message:@"设备已经解绑"];
					_devices = nil;
					[self.tableView reloadData];
					[self refresh];
				} else {
					[self displayHUDTitle:@"解绑失败" message:@"请重新尝试"];
				}
			}];
		}
	}
}


@end
