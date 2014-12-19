//
//  BLFilterViewController.m
//  TableAir
//
//  Created by hqb on 14-5-27.
//  Copyright (c) 2014年 BroadLink. All rights reserved.
//

#import "BLFilterViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "BLAppDelegate.h"
#import "iCarousel.h"
#import "BLZSIndicatorProgress.h"
#import "JSONKit.h"
#import "BLScheduleManager.h"

@interface BLFilterViewController () <iCarouselDataSource, iCarouselDelegate> {
    iCarousel *iMinPickerFrom;
    iCarousel *iHourPickerFrom;
    dispatch_queue_t networkQueue;
    BLAppDelegate *appDelegate;
    //两个选择的
    BLZSIndicatorProgress *countDownHourIndicator;
    BLZSIndicatorProgress *countDownMiniteIndicator;
}
@property(nonatomic, strong) UIButton *buttonCancel;
@property(nonatomic, strong) UIButton *buttonClose;
@property(nonatomic, strong) UIImageView *imageViewCancel;
@property(nonatomic, strong) UIImageView *imageViewClose;
@property(nonatomic, strong) UIView *selectedView;
@property(nonatomic, strong) UIButton *lastSelectedButton;
@property(nonatomic, strong) UILabel *labelCancel;
@property(nonatomic, strong) UILabel *labelClose;
@property(nonatomic, strong) UILabel *labelSelected;
@property (assign, nonatomic) int tmpTimerCount;
@property (nonatomic, strong) NSTimer *refreshInfoTimer;
@end

@implementation BLFilterViewController


- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = NSLocalizedString(@"timerTitle", nil);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonClick)];
	self.view.backgroundColor = [UIColor whiteColor];
	// Do any additional setup after loading the view.
    networkQueue = dispatch_queue_create("BLFilterViewController", DISPATCH_QUEUE_SERIAL);
    appDelegate = (BLAppDelegate *)[[UIApplication sharedApplication] delegate];
    _tmpTimerCount = 0;
    
    //页面设置
    [self.mm_drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeNone];
    [self.navigationController setToolbarHidden:YES];
    CGRect viewFrame = CGRectZero;

    //定时取消
	viewFrame.origin.x = 0;
	viewFrame.origin.y = 100;
    viewFrame.size.width = self.view.frame.size.width;
    viewFrame.size.height = 60.f;
    _buttonCancel = [[UIButton alloc] initWithFrame:viewFrame];
    [_buttonCancel setBackgroundColor:[UIColor whiteColor]];
    [_buttonCancel setTag:1];
    //定时取消图标
    UIImage *image = [UIImage imageNamed:@"btn_check"];
    //定时取消文字
    viewFrame.origin.x = 10;
    viewFrame.origin.y = (60 - image.size.height) / 2.f;
    viewFrame.size.width = 120;
    viewFrame.size.height = image.size.height;
    _labelCancel = [[UILabel alloc] initWithFrame:viewFrame];
    [_labelCancel setText:NSLocalizedString(@"timeOpen", nil)];
    [_labelCancel setBackgroundColor:[UIColor clearColor]];
    [_buttonCancel addSubview:_labelCancel];
    //右边的图片
    viewFrame.origin.x = self.view.frame.size.width - image.size.width - 10;
    viewFrame.origin.y = (_buttonCancel.frame.size.height - image.size.height) / 2.f;
    viewFrame.size.width = image.size.width;
    viewFrame.size.height = image.size.height;
    _imageViewCancel = [[UIImageView alloc] initWithFrame:viewFrame];
    _imageViewCancel.image = image;
    [_buttonCancel addSubview:_imageViewCancel];
    [_buttonCancel addTarget:self action:@selector(cancelOrCloseClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_buttonCancel];
    
    //定时关机
    viewFrame.origin.x = 0;
    viewFrame.origin.y = _buttonCancel.frame.size.height + _buttonCancel.frame.origin.y + 1.f;
    viewFrame.size.width = self.view.frame.size.width;
    viewFrame.size.height = 60.f;
    _buttonClose = [[UIButton alloc] initWithFrame:viewFrame];
    [_buttonClose setBackgroundColor:[UIColor whiteColor]];
    //定时关机文字
    viewFrame.origin.x = 10;
    viewFrame.origin.y = (60 - image.size.height) / 2.f;
    viewFrame.size.width =120;
    viewFrame.size.height = image.size.height;
    _labelClose= [[UILabel alloc] initWithFrame:viewFrame];
    [_labelClose setText:NSLocalizedString(@"timeClose", nil)];
    [_labelClose setBackgroundColor:[UIColor clearColor]];
    [_buttonClose addSubview:_labelClose];
    [_buttonClose setTag:2];
    //定时关机图标
    image = [UIImage imageNamed:@"btn_point"];
    viewFrame.origin.x = self.view.frame.size.width - image.size.width - 10;
    viewFrame.origin.y = (_buttonClose.frame.size.height - image.size.height) / 2.f;
    viewFrame.size.width = image.size.width;
    viewFrame.size.height = image.size.height;
    _imageViewClose = [[UIImageView alloc] initWithFrame:viewFrame];
    _imageViewClose.image = image;
    [_buttonClose addSubview:_imageViewClose];
    [_buttonClose addTarget:self action:@selector(cancelOrCloseClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_buttonClose];
    
    //其余空白部分
    viewFrame.origin.x = 30;
    viewFrame.origin.y = _buttonClose.frame.size.height + _buttonClose.frame.origin.y + 20;
    viewFrame.size.width = self.view.frame.size.width - 30;
    viewFrame.size.height = self.view.frame.size.height - (_buttonClose.frame.size.height + _buttonClose.frame.origin.y + 20);
    _selectedView = [[UIView alloc] initWithFrame:viewFrame];
    _selectedView.backgroundColor = [UIColor clearColor];
    // 标签标题
    viewFrame.origin.x=0;
    viewFrame.origin.y=_labelClose.frame.origin.y+_labelClose.frame.size.height+20.f;
    viewFrame.size.width=self.view.frame.size.width - 60;
    viewFrame.size.height=20;
    _labelSelected = [[UILabel alloc] initWithFrame:viewFrame];
    [_labelSelected setBackgroundColor:[UIColor clearColor]];
    [_labelSelected setTextAlignment:NSTextAlignmentCenter];
    [_labelSelected setTextColor:[UIColor blackColor]];
    [_labelSelected setFont:[UIFont systemFontOfSize:11.f]];
    [_selectedView addSubview:_labelSelected];
    //选取
    viewFrame.origin.x=0;
    viewFrame.origin.y=_labelSelected.frame.origin.y+_labelSelected.frame.size.height+10.f;
    viewFrame.size.width=80;
    viewFrame.size.height=120;
    iHourPickerFrom = [[iCarousel alloc] initWithFrame:viewFrame];
    [iHourPickerFrom setBackgroundColor:[UIColor clearColor]];
    [iHourPickerFrom setDelegate:self];
    [iHourPickerFrom setDataSource:self];
    [iHourPickerFrom setType:iCarouselTypeLinear];
    [iHourPickerFrom setVertical:YES];
    [iHourPickerFrom setClipsToBounds:YES];
    [iHourPickerFrom setDecelerationRate:.91f];
    [iHourPickerFrom scrollToItemAtIndex:0 animated:NO];
    [_selectedView addSubview:iHourPickerFrom];
    //分隔符
    viewFrame.origin.x=iHourPickerFrom.frame.origin.x+iHourPickerFrom.frame.size.width+10.f;
    viewFrame.origin.y=iHourPickerFrom.frame.origin.y+(iHourPickerFrom.frame.size.height)/2.0f-8.f;
    viewFrame.size.width=40;
    viewFrame.size.height=20;
    UILabel *label = [[UILabel alloc]initWithFrame:viewFrame];
    [label setTextColor:[UIColor colorWithRed:61.f/255.f green:57.f/255.f blue:53.f/255.f alpha:1]];
    [label setText:NSLocalizedString(@"hour", nil)];
    [label setBackgroundColor:[UIColor clearColor]];
    [_selectedView addSubview:label];
    
    //选取
    viewFrame.origin.x=label.frame.size.width+label.frame.origin.x+1.f;
    viewFrame.origin.y=iHourPickerFrom.frame.origin.y;
    viewFrame.size.width=iHourPickerFrom.frame.size.width;
    viewFrame.size.height=iHourPickerFrom.frame.size.height;
    iMinPickerFrom = [[iCarousel alloc] initWithFrame:viewFrame];
    [iMinPickerFrom setBackgroundColor:[UIColor clearColor]];
    [iMinPickerFrom setDelegate:self];
    [iMinPickerFrom setDataSource:self];
    [iMinPickerFrom setType:iCarouselTypeLinear];
    [iMinPickerFrom setVertical:YES];
    [iMinPickerFrom setClipsToBounds:YES];
    [iMinPickerFrom setDecelerationRate:.99f];
    [iMinPickerFrom scrollToItemAtIndex:0 animated:NO];
    [_selectedView addSubview:iMinPickerFrom];
    //分隔符
    viewFrame.origin.x=iMinPickerFrom.frame.origin.x+iHourPickerFrom.frame.size.width+10.f;
    viewFrame.origin.y=label.frame.origin.y;
    viewFrame.size=label.frame.size;
    label = [[UILabel alloc]initWithFrame:viewFrame];
    [label setTextColor:[UIColor colorWithRed:61.f/255.f green:57.f/255.f blue:53.f/255.f alpha:1]];
    [label setText:NSLocalizedString(@"minute", nil)];
    [label setBackgroundColor:[UIColor clearColor]];
    [_selectedView addSubview:label];
    [self.view addSubview:_selectedView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIImage *imageCheck = [UIImage imageNamed:@"btn_check"];
    UIImage *imageUnCheck = [UIImage imageNamed:@"btn_point"];
    //判断当前是那个按钮选择s
    if(self.receivedData.switchStatus) {
        _lastSelectedButton = _buttonClose;
        //有定时
        _selectedView.hidden = NO;
        _labelSelected.text = [NSString stringWithFormat:@"%d%@%d%@%@",iHourPickerFrom.currentItemIndex,NSLocalizedString(@"hour", nil),iMinPickerFrom.currentItemIndex,NSLocalizedString(@"minute", nil),NSLocalizedString(@"close", nil)];
        [_labelCancel setTextColor:[UIColor blackColor]];
		_labelCancel.textColor = [UIColor themeBlue];
        //取消按钮
        _imageViewClose .image = imageCheck;
        CGRect viewFrame =_imageViewClose.frame;
        viewFrame.origin.x = self.view.frame.size.width - imageCheck.size.width - 10;
        viewFrame.size = imageCheck.size;
        [_imageViewClose setFrame:viewFrame];
        
        //关闭按钮
        _imageViewCancel.image = imageUnCheck;
        viewFrame =_imageViewCancel.frame;
        viewFrame.origin.x = self.view.frame.size.width - imageUnCheck.size.width - 10;
        viewFrame.size = imageUnCheck.size;
        [_imageViewCancel setFrame:viewFrame];
    } else {
        _lastSelectedButton = _buttonCancel;
        //无定时
        _selectedView.hidden = NO;
        _labelSelected.text = [NSString stringWithFormat:@"%d%@%d%@%@",iHourPickerFrom.currentItemIndex,NSLocalizedString(@"hour", nil),iMinPickerFrom.currentItemIndex,NSLocalizedString(@"minute", nil),NSLocalizedString(@"open", nil)];
        [_labelClose setTextColor:[UIColor blackColor]];
		_labelCancel.textColor = [UIColor themeBlue];
        //取消按钮
        _imageViewCancel .image = imageCheck;
        CGRect viewFrame =_imageViewCancel.frame;
        viewFrame.origin.x = self.view.frame.size.width - imageCheck.size.width - 10;
        viewFrame.size = imageCheck.size;
        [_imageViewCancel setFrame:viewFrame];
        
        //关闭按钮
        _imageViewClose.image = imageUnCheck;
        viewFrame =_imageViewClose.frame;
        viewFrame.origin.x = self.view.frame.size.width - imageUnCheck.size.width - 10;
        viewFrame.size = imageUnCheck.size;
        [_imageViewClose setFrame:viewFrame];
    }
}

//保存按钮点击
-(void)saveButtonClick {
    //判断点击事件
	if(iMinPickerFrom.currentItemIndex == 0 && iHourPickerFrom.currentItemIndex == 0) {
		return;
	} else {
        double second = iMinPickerFrom.currentItemIndex * 60 + iHourPickerFrom.currentItemIndex * 3600;
        NSLog(@"second = %f",second);
		
		BOOL on = YES;
        BLTimerInfomation *timerInfomation = [[BLTimerInfomation alloc] init];
        timerInfomation.secondCount = second;//定时秒数
        //开机状态
        if(_lastSelectedButton == _buttonCancel) {
            //定时开机
            timerInfomation.switchState = 1;
			on = YES;
        }
        else if (_lastSelectedButton == _buttonClose)
        {
            timerInfomation.switchState = 0;
			on = NO;
        }
		[[BLScheduleManager shared] scheduleOnOrOff:on afterDelay:second MAC:_device.mac];
		
        //当前时间戳
        NSDate *datenow = [NSDate date];
        timerInfomation.secondSince = (long)[datenow timeIntervalSince1970];
        NSLog(@"timerInfomation.secondSince = %ld",timerInfomation.secondSince);
		[timerInfomation persistence];
        [self returnButtonClick];
    }
}

//返回按钮点击事件
-(void)returnButtonClick {
    [self.navigationController popViewControllerAnimated:YES];
}

//取消按钮点击
-(void)cancelOrCloseClick:(UIButton *)button {
    //判断没有点击
    if(_lastSelectedButton.tag == button.tag)
        return;
    UIImage *imageCheck = [UIImage imageNamed:@"btn_check"];
    UIImage *imageUnCheck = [UIImage imageNamed:@"btn_point"];
    //判断点击的按钮
    if(button.tag == 1) {
        //选择的隐藏
        _selectedView.hidden = NO;
        [_labelClose setTextColor:[UIColor blackColor]];
		_labelCancel.textColor = [UIColor themeBlue];
        //取消按钮
        _imageViewCancel .image = imageCheck;
        CGRect viewFrame =_imageViewCancel.frame;
        viewFrame.origin.x = self.view.frame.size.width - imageCheck.size.width - 10;
        viewFrame.size = imageCheck.size;
        [_imageViewCancel setFrame:viewFrame];
        
        //关闭按钮
        _imageViewClose.image = imageUnCheck;
        viewFrame =_imageViewClose.frame;
        viewFrame.origin.x = self.view.frame.size.width - imageUnCheck.size.width - 10;
        viewFrame.size = imageUnCheck.size;
        [_imageViewClose setFrame:viewFrame];
    } else if (button.tag == 2) {
         //选择的显示
        _selectedView.hidden = NO;
        [_labelCancel setTextColor:[UIColor blackColor]];
		_labelCancel.textColor = [UIColor themeBlue];
        //取消按钮
        _imageViewClose .image = imageCheck;
        CGRect viewFrame =_imageViewClose.frame;
        viewFrame.origin.x = self.view.frame.size.width - imageCheck.size.width - 10;
        viewFrame.size = imageCheck.size;
        [_imageViewClose setFrame:viewFrame];
        
        //关闭按钮
        _imageViewCancel.image = imageUnCheck;
        viewFrame =_imageViewCancel.frame;
        viewFrame.origin.x = self.view.frame.size.width - imageUnCheck.size.width - 10;
        viewFrame.size = imageUnCheck.size;
        [_imageViewCancel setFrame:viewFrame];
    }
    //选择按钮隐藏
    _lastSelectedButton = button;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel {
    return 3;
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel {
    return 3;
}

- (void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel {
    int index2 = carousel.currentItemIndex;
    int index3 = carousel.currentItemIndex + 1;
    NSMutableArray *itemArray = (NSMutableArray *)carousel.visibleItemViews;
    UILabel *label1 = [itemArray objectAtIndex:0];
    UILabel *label2 = [itemArray objectAtIndex:1];
    UILabel *label3 = [itemArray objectAtIndex:2];
    if ([carousel isEqual:iHourPickerFrom]) {
        if (index3 > 15) {
            label1.textColor = [UIColor lightGrayColor];
            label1.font = [UIFont systemFontOfSize:20.0f];
            label2.textColor = [UIColor lightGrayColor];
            label2.font = [UIFont systemFontOfSize:20.0f];
            label3.textColor = [UIColor blackColor];
            label3.font = [UIFont systemFontOfSize:45.0f];
        } else if (index2 == 0) {
            label1.textColor = [UIColor blackColor];
            label1.font = [UIFont systemFontOfSize:45.0f];
            label2.textColor = [UIColor lightGrayColor];
            label2.font = [UIFont systemFontOfSize:20.0f];
            label3.textColor = [UIColor lightGrayColor];
            label3.font = [UIFont systemFontOfSize:20.0f];
        } else {
            label1.textColor = [UIColor lightGrayColor];
            label1.font = [UIFont systemFontOfSize:20.0f];
            label2.textColor = [UIColor blackColor];
            label2.font = [UIFont systemFontOfSize:45.0f];
            label3.textColor = [UIColor lightGrayColor];
            label3.font = [UIFont systemFontOfSize:20.0f];
        }
    }
    
    if ([carousel isEqual:iMinPickerFrom]) {
        if (index3 > 59) {
            label1.textColor = [UIColor lightGrayColor];
            label1.font = [UIFont systemFontOfSize:20.0f];
            label2.textColor = [UIColor lightGrayColor];
            label2.font = [UIFont systemFontOfSize:20.0f];
            label3.textColor = [UIColor blackColor];
            label3.font = [UIFont systemFontOfSize:45.0f];
        } else if (index2 == 0) {
            label1.textColor = [UIColor blackColor];
            label1.font = [UIFont systemFontOfSize:45.0f];
            label2.textColor = [UIColor lightGrayColor];
            label2.font = [UIFont systemFontOfSize:20.0f];
            label3.textColor = [UIColor lightGrayColor];
            label3.font = [UIFont systemFontOfSize:20.0f];
        } else {
            label1.textColor = [UIColor lightGrayColor];
            label1.font = [UIFont systemFontOfSize:20.0f];
            label2.textColor = [UIColor blackColor];
            label2.font = [UIFont systemFontOfSize:45.0f];
            label3.textColor = [UIColor lightGrayColor];
            label3.font = [UIFont systemFontOfSize:20.0f];
        }
    }
    
    //-- 获取每个iCarousel的值
    [countDownHourIndicator setPercent:iHourPickerFrom.currentItemIndex maxPercent:24 animated:YES];
    [countDownMiniteIndicator setPercent:iMinPickerFrom.currentItemIndex maxPercent:60 animated:YES];
    if(!self.receivedData.switchStatus)
        _labelSelected.text = [NSString stringWithFormat:@"%d%@%d%@%@",iHourPickerFrom.currentItemIndex,NSLocalizedString(@"hour", nil),iMinPickerFrom.currentItemIndex,NSLocalizedString(@"minute", nil),NSLocalizedString(@"open", nil)];
    else
        _labelSelected.text = [NSString stringWithFormat:@"%d%@%d%@%@",iHourPickerFrom.currentItemIndex,NSLocalizedString(@"hour", nil),iMinPickerFrom.currentItemIndex,NSLocalizedString(@"minute", nil),NSLocalizedString(@"close", nil)];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view {
    if (view == nil) {
        view = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, carousel.frame.size.width, carousel.frame.size.height / 3.f)];
    }
    
    ((UILabel *)view).textAlignment = NSTextAlignmentCenter;
    ((UILabel *)view).font = [UIFont systemFontOfSize:11.0f];
    ((UILabel *)view).textColor = [UIColor lightGrayColor];
    ((UILabel *)view).backgroundColor = [UIColor clearColor];
    ((UILabel *)view).text = [NSString stringWithFormat:@"%02i", index];
    return view;
}

- (CGFloat)carouselItemWidth:(iCarousel *)carousel {
    //usually this should be slightly wider than the item views
    return carousel.frame.size.width / 2.f;
}

//必须的方法
- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel {
    NSUInteger count = 0;
    if ([carousel isEqual:iHourPickerFrom]) {
        count = 16;
    } else if ([carousel isEqual:iMinPickerFrom]) {
        count = 60;
    }
    return count;
}

- (CGFloat)carousel:(iCarousel *)carousel itemAlphaForOffset:(CGFloat)offset {
	//set opacity based on distance from camera
    return 1.0f - fminf(fmaxf(offset, 0.0f), 1.0f);
}

- (CATransform3D)carousel:(iCarousel *)_carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform {
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * _carousel.itemWidth);
}

- (BOOL)carouselShouldWrap:(iCarousel *)carousel {
    return YES;
}

- (BOOL)carousel:(iCarousel *)carousel shouldSelectItemAtIndex:(NSInteger)index {
    return YES;
}

@end
