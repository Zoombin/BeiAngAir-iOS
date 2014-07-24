//
//  BLQRCodeViewController.m
//  BeiAngAir
//
//  Created by zhangbin on 7/23/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BLQRCodeViewController.h"

@interface BLQRCodeViewController ()

@end

@implementation BLQRCodeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"二维码", nil);
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.view.backgroundColor = [UIColor whiteColor];
	
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss)];
	[self.view addGestureRecognizer:tapGestureRecognizer];

	UIImage *image = [UIImage imageNamed:@"qrcode"];
	UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
	imageView.userInteractionEnabled = YES;
	imageView.frame = CGRectMake((self.view.frame.size.width - image.size.width) / 2, 150, image.size.width, image.size.height);
	[self.view addSubview:imageView];
	[imageView addGestureRecognizer:tapGestureRecognizer];
	[self.view addGestureRecognizer:tapGestureRecognizer];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(imageView.frame) + 25, self.view.frame.size.width, 60)];
	label.textAlignment = NSTextAlignmentCenter;
	label.numberOfLines = 0;
	label.text = NSLocalizedString(@"扫描二维码关注我们\n即可享受我们的微客服哦!", nil);
	[self.view addSubview:label];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismiss
{
	[self dismissModalViewControllerAnimated:YES];
}

@end
