//
//  BLDeviceInfoEditViewController.m
//  TCLAir
//
//  Created by yang on 4/15/14.
//  Copyright (c) 2014 BroadLink. All rights reserved.
//

#import "BLDeviceEditViewController.h"
#import "GlobalDefine.h"
#import "UIViewController+MMDrawerController.h"
#import "JSONKit.h"
#import "BLAPIClient.h"
#import "BLDeviceQRCodeViewController.h"

#define TOAST_DURATION  0.8f

@interface BLDeviceEditViewController () <UITextFieldDelegate,UIActionSheetDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (nonatomic, strong) UITextField *nameTextField;
@property (nonatomic, strong) UIButton *lockButton;
@property (nonatomic, strong) UIButton *addButton;

@end

@implementation BLDeviceEditViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.title = NSLocalizedString(@"DeviceInfoEditViewControllerTitle", nil);
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismiss)];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.navigationController.navigationBarHidden = NO;
    
    [self.view setBackgroundColor:RGB(246.0f, 246.0f, 246.0f)];
    
    CGRect viewFrame = CGRectZero;
    viewFrame.origin.x = 0.0f;
    viewFrame.origin.y = 0.0f;
    viewFrame.size.width = self.view.frame.size.width;
    viewFrame.size.height = 44.0f + ((IsiOS7Later) ? 20.0f : 0.0f);
    UIView *headerView = [[UIView alloc] initWithFrame:viewFrame];
    [headerView setBackgroundColor:[UIColor whiteColor]];
//    [self.view addSubview:headerView];
    
    viewFrame = headerView.frame;
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:viewFrame];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setFont:[UIFont systemFontOfSize:20.0f]];
    [titleLabel setTextColor:RGB(0x13, 0xb3, 0x5c)];
    [titleLabel setText:NSLocalizedString(@"DeviceInfoEditViewControllerTitle", nil)];
    viewFrame = [titleLabel textRectForBounds:viewFrame limitedToNumberOfLines:1];
    viewFrame.origin.x = (headerView.frame.size.width - viewFrame.size.width) * 0.5f;
    viewFrame.origin.y = (44.0f - viewFrame.size.height) * 0.5f + ((IsiOS7Later) ? 20.0f : 0.0f);
    [titleLabel setFrame:viewFrame];
    [titleLabel setTextAlignment:NSTextAlignmentCenter];
//    [headerView addSubview:titleLabel];//TODO: hide
	
	UIImage *image = [_device avatar];
    viewFrame = headerView.frame;
    viewFrame.origin.y += viewFrame.size.height + 20.0f;
    viewFrame.origin.x = (self.view.frame.size.width - 62.5) * 0.5f;
    viewFrame.size.width = 62.5;
    viewFrame.size.height = 62.5;
    _addButton = [[UIButton alloc] initWithFrame:viewFrame];
    [_addButton.layer setMasksToBounds:YES];
    [_addButton.layer setCornerRadius:_addButton.frame.size.width / 2.f];
    [_addButton setBackgroundColor:[UIColor clearColor]];
    [_addButton setImage:image forState:UIControlStateNormal];
    [_addButton addTarget:self action:@selector(logoButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_addButton];
    
    viewFrame = _addButton.frame;
    viewFrame.origin.y += viewFrame.size.height + 20.0f;
    viewFrame.origin.x = 20.0f;
    viewFrame.size.width = self.view.frame.size.width - 40.0f;
    viewFrame.size.height = 50.0f;
    UIView *nameView = [[UIView alloc] initWithFrame:viewFrame];
    [nameView setBackgroundColor:[UIColor whiteColor]];
    [nameView.layer setBorderColor:RGB(0x99, 0x99, 0x99).CGColor];
    [nameView.layer setBorderWidth:1.0f];
    [self.view addSubview:nameView];
    viewFrame = nameView.frame;
    viewFrame.origin.x = 3.0f;
    viewFrame.origin.y = 0.0f;
    viewFrame.size = CGSizeMake(80.0f, nameView.frame.size.height);
    UILabel *nameLabel = [[UILabel alloc] initWithFrame:viewFrame];
    [nameLabel setBackgroundColor:[UIColor clearColor]];
    [nameLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [nameLabel setTextColor:RGB(0x99, 0x99, 0x99)];
    [nameLabel setText:NSLocalizedString(@"DeviceInfoEditViewControllerNameLabel", nil)];
    [nameView addSubview:nameLabel];
    viewFrame = nameLabel.frame;
    viewFrame.origin.x += viewFrame.size.width + 5.0f;
    viewFrame.size = CGSizeMake(nameView.frame.size.width - 10.0f - viewFrame.origin.x, nameView.frame.size.height);
    _nameTextField = [[UITextField alloc] initWithFrame:viewFrame];
    [_nameTextField setBackgroundColor:[UIColor clearColor]];
    [_nameTextField setBorderStyle:UITextBorderStyleNone];
    [_nameTextField setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
    [_nameTextField setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [_nameTextField setFont:[UIFont systemFontOfSize:15.0f]];
    [_nameTextField setKeyboardType:UIKeyboardTypeDefault];
    [_nameTextField setDelegate:self];
    [_nameTextField setClearButtonMode:UITextFieldViewModeWhileEditing];
    [_nameTextField setPlaceholder:NSLocalizedString(@"DeviceInfoEditViewControllerNamePlaceholder", nil)];
    [_nameTextField setAutoresizesSubviews:YES];
    [_nameTextField setReturnKeyType:UIReturnKeyDone];
    [_nameTextField setText:_device.nickname];
    [_nameTextField addTarget:self action:@selector(keywindowHidden:) forControlEvents:UIControlEventEditingDidEndOnExit];
    [nameView addSubview:_nameTextField];
    
    viewFrame = nameView.frame;
    viewFrame.origin.y += viewFrame.size.height - 1.0f;
    UIView *lockView = [[UIView alloc] initWithFrame:viewFrame];
    [lockView setBackgroundColor:[UIColor whiteColor]];
    [lockView.layer setBorderColor:RGB(0x99, 0x99, 0x99).CGColor];
    [lockView.layer setBorderWidth:1.0f];
    [self.view addSubview:lockView];
	
    viewFrame = lockView.frame;
    viewFrame.origin.x = 3.0f;
    viewFrame.origin.y = 0.0f;
	viewFrame.size.width = self.view.frame.size.width - 40;
	viewFrame.size.height = lockView.frame.size.height;
    UILabel *qrCodeLabel = [[UILabel alloc] initWithFrame:viewFrame];
    [qrCodeLabel setBackgroundColor:[UIColor clearColor]];
    [qrCodeLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [qrCodeLabel setTextColor:RGB(0x99, 0x99, 0x99)];
    [qrCodeLabel setText:NSLocalizedString(@"二维码授权", nil)];
	qrCodeLabel.userInteractionEnabled = YES;
	
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(qrcodeAuth)];
	[qrCodeLabel addGestureRecognizer:tap];
    [lockView addSubview:qrCodeLabel];
	
	
    viewFrame = lockView.frame;
    viewFrame.origin = CGPointZero;
    image = [UIImage imageNamed:@"unlocked"];
    _lockButton = [[UIButton alloc] initWithFrame:viewFrame];
	_lockButton.hidden = YES;
    [_lockButton setBackgroundColor:[UIColor clearColor]];
    [_lockButton setImageEdgeInsets:UIEdgeInsetsMake((viewFrame.size.height - image.size.height) * 0.5f, viewFrame.size.width - image.size.width - 10.0f, (viewFrame.size.height - image.size.height) * 0.5f, 10.0f)];
    [_lockButton setImage:image forState:UIControlStateNormal];
    [_lockButton setImage:[UIImage imageNamed:@"locked"] forState:UIControlStateSelected];
    [lockView addSubview:_lockButton];
    
    viewFrame = lockView.frame;
    viewFrame.origin.y += viewFrame.size.height + 20.0f;
    UIView *deviceIDView = [[UIView alloc] initWithFrame:viewFrame];
    [deviceIDView setBackgroundColor:[UIColor whiteColor]];
    [deviceIDView.layer setBorderColor:RGB(0x99, 0x99, 0x99).CGColor];
    [deviceIDView.layer setBorderWidth:1.0f];
    [self.view addSubview:deviceIDView];
    viewFrame = lockView.frame;
    viewFrame.origin.x = 3.0f;
    viewFrame.origin.y = 0.0f;
    viewFrame.size = CGSizeMake(80.0f, lockView.frame.size.height);
    UILabel *deviceIDLabel = [[UILabel alloc] initWithFrame:viewFrame];
    [deviceIDLabel setBackgroundColor:[UIColor clearColor]];
    [deviceIDLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [deviceIDLabel setTextColor:RGB(0x99, 0x99, 0x99)];
    [deviceIDLabel setText:NSLocalizedString(@"设备ID:", nil)];
    [deviceIDView addSubview:deviceIDLabel];
    viewFrame = deviceIDLabel.frame;
    viewFrame.origin.x += viewFrame.size.width + 5.0f;
    viewFrame.size = CGSizeMake(deviceIDView.frame.size.width - 10.0f - viewFrame.origin.x, deviceIDView.frame.size.height);
    UILabel *deviceIDValueLabel = [[UILabel alloc] initWithFrame:viewFrame];
    [deviceIDValueLabel setBackgroundColor:[UIColor clearColor]];
    [deviceIDValueLabel setTextColor:[UIColor blackColor]];
    [deviceIDValueLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [deviceIDValueLabel setText:[NSString stringWithFormat:@"%@", _device.ID]];
    [deviceIDView addSubview:deviceIDValueLabel];
    
    //确定按钮
    viewFrame.origin.x = CGRectGetMinX(deviceIDView.frame);
    viewFrame.origin.y = 360;
    viewFrame.size.width = CGRectGetWidth(deviceIDView.frame);
	viewFrame.size.height = 50;
	UIButton *okButton = [UIButton buttonWithType:UIButtonTypeCustom];
	okButton.frame = viewFrame;
    [okButton setBackgroundColor:[UIColor themeBlue]];
    [okButton setTitle:NSLocalizedString(@"DeviceInfoEditViewControllerOKButton", nil) forState:UIControlStateNormal];
    [okButton addTarget:self action:@selector(okButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:okButton];
}

- (void)qrcodeAuth {
	BLDeviceQRCodeViewController *deviceQRCodeViewController = [[BLDeviceQRCodeViewController alloc] initWithNibName:nil bundle:nil];
	deviceQRCodeViewController.device = _device;
	[self.navigationController pushViewController:deviceQRCodeViewController animated:YES];
}

- (void)keywindowHidden:(UITextField *)field
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
}

-(void)logoButtonClick
{
    [[[UIApplication sharedApplication] keyWindow] endEditing:YES];
    
    UIActionSheet *chooseImageSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) \
                    destructiveButtonTitle:nil \
                            otherButtonTitles:NSLocalizedString(@"take_a_photo", nil),NSLocalizedString(@"choose_from_album", nil), nil];
    [chooseImageSheet showInView:self.view];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dismiss
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)okButtonClicked:(UIButton *)button {
	if (!_nameTextField.text.length) {
		[self displayHUDTitle:nil message:@"设备名称不能为空"];
	}
	
	if (![_nameTextField.text isEqualToString:_device.nickname]) {
		[[BLAPIClient shared] updateAuthorize:_device.ID role:_device.role nickename:_nameTextField.text withBlock:^(NSError *error) {
			if (!error) {
				[self displayHUDTitle:nil message:@"修改成功"];
			} else {
				[self displayHUDTitle:@"错误" message:error.userInfo[BL_ERROR_MESSAGE_IDENTIFIER]];
			}
		}];
	}
}

#pragma mark - UIImagePickerController Delegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.mm_drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeNone];
    [self.mm_drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    NSData *data = nil;
    
    if ([mediaType isEqualToString:@"public.image"]) {
        UIImage *originImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        UIImage *scaleImage = [self scaleImage:originImage toScale:250.0f/originImage.size.width];
        
		if (UIImagePNGRepresentation(scaleImage) == nil) {
            data = UIImageJPEGRepresentation(scaleImage, 1);
        } else {
            data = UIImagePNGRepresentation(scaleImage);
        }
        UIImage *image = [UIImage imageWithData:data];
        [_addButton setImage:image forState:UIControlStateNormal];
		NSString *imagePath = [NSString deviceAvatarPathWithMAC:[NSString stringWithFormat:@"%@", _device.ID]];
        [UIImagePNGRepresentation(image) writeToFile:imagePath atomically:YES];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    [self.mm_drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeNone];
    [self.mm_drawerController setOpenDrawerGestureModeMask:MMOpenDrawerGestureModeNone];
}

//添加图片
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
	imagePicker.delegate = self;
	if (buttonIndex == 0) {
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
			imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
		}
		else {
			[self displayHUDTitle:NSLocalizedString(@"DeviceInfoOpenCameraFailed", nil) message:nil duration:3];
		}
		[self presentViewController:imagePicker animated:YES completion:nil];
	} else if (buttonIndex == 1) {
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
			imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
		} else {
			[self displayHUDTitle:NSLocalizedString(@"DeviceInfoOpenCameraFailed", nil) message:nil duration:3];
		}
		[self presentViewController:imagePicker animated:YES completion:nil];
	}
}

#pragma mark - scaleImage

- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize
{
    UIGraphicsBeginImageContext(CGSizeMake(image.size.width * scaleSize,image.size.height * scaleSize));
    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height * scaleSize)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGRect rect = CGRectMake(0.0f, (scaledImage.size.height - scaledImage.size.width) * 0.5f, scaledImage.size.width, scaledImage.size.width);
    CGImageRef sourceImageRef = [scaledImage CGImage];
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    CGImageRelease(newImageRef);
    
    return newImage;
}


@end
