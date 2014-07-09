//
//  BLFilterViewController.m
//  TableAir
//
//  Created by hqb on 14-5-27.
//  Copyright (c) 2014年 BroadLink. All rights reserved.
//

#import "BLFilterViewController.h"
#import "UIViewController+MMDrawerController.h"
#import "CustomNaviBarView.h"
#import "BLAppDelegate.h"
#import "BLFMDBSqlite.h"
#import "Toast+UIView.h"
#import "MMProgressHUD.h"
#import "iCarousel.h"
#import "BLZSIndicatorProgress.h"
#import "BLNetwork.h"
#import "JSONKit.h"

@interface BLFilterViewController ()<iCarouselDataSource, iCarouselDelegate>
{
    //-- count time 事件选择器
    iCarousel *iMinPickerFrom;
    iCarousel *iHourPickerFrom;
    dispatch_queue_t networkQueue;
    BLNetwork *networkAPI;
    BLAppDelegate *appDelegate;
    //两个选择的
    BLZSIndicatorProgress *countDownHourIndicator;
    BLZSIndicatorProgress *countDownMiniteIndicator;
    BLFMDBSqlite *sqlite;
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
//定时器
@property (nonatomic, strong) NSTimer *refreshInfoTimer;
@end

@implementation BLFilterViewController

- (void)dealloc
{
    dispatch_release(networkQueue);
    _buttonCancel = nil;
    _buttonClose = nil;
    _imageViewCancel = nil;
    _imageViewClose = nil;
    _selectedView = nil;
    _lastSelectedButton = nil;
    _labelCancel = nil;
    _labelClose = nil;
    _labelSelected = nil;
    [_refreshInfoTimer invalidate];
    _labelSelected = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    networkQueue = dispatch_queue_create("BLFilterViewController", DISPATCH_QUEUE_SERIAL);
    networkAPI = [[BLNetwork alloc] init];
    appDelegate = (BLAppDelegate *)[[UIApplication sharedApplication] delegate];
    _tmpTimerCount = 0;
    sqlite = [BLFMDBSqlite sharedFMDBSqlite];
    
    //页面设置
    [self.mm_drawerController setCloseDrawerGestureModeMask:MMCloseDrawerGestureModeNone];
    [self.navigationController setToolbarHidden:YES];
    CGRect viewFrame = CGRectZero;
    
    //返回按钮
    NSString *path = [[NSBundle mainBundle] pathForResource:@"left@2x" ofType:@"png"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    viewFrame.origin.x = 0;
    viewFrame.origin.y = 20.f;
    viewFrame.size.width = image.size.width;
    viewFrame.size.height = image.size.height;
    UIButton *returnButton = [[UIButton alloc] initWithFrame:viewFrame];
    returnButton.backgroundColor = [UIColor clearColor];
    [returnButton setImage:image forState:UIControlStateNormal];
    [returnButton addTarget:self action:@selector(returnButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarLeftBtn:returnButton];
    
    //设置标题
    [self setNaviBarTitleFont:[UIFont systemFontOfSize:20.f]];
    [self setNaviBarTitle:NSLocalizedString(@"timerTitle", nil) color:RGB(0, 145, 241)];
    
    //保存
    viewFrame.origin.x = 0;
    viewFrame.origin.y = 20.f;
    viewFrame.size.width = self.view.frame.size.width;
    viewFrame.size.height = image.size.height;
    UIButton *rightButton = [[UIButton alloc] initWithFrame:viewFrame];
    [rightButton setBackgroundColor:[UIColor clearColor]];
    [rightButton setTitle:NSLocalizedString(@"save", nil) forState:UIControlStateNormal];
    [rightButton setTitleColor:RGB(0, 145, 241) forState:UIControlStateNormal];
    [rightButton setBackgroundColor:[UIColor clearColor]];
    [rightButton addTarget:self action:@selector(saveButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self setNaviBarRightBtn:rightButton];
    
    //定时取消
    viewFrame.origin.x = 0;
    viewFrame.origin.y = rightButton.frame.size.height + rightButton.frame.origin.y;
    viewFrame.size.width = self.view.frame.size.width;
    viewFrame.size.height = 60.f;
    _buttonCancel = [[UIButton alloc] initWithFrame:viewFrame];
    [_buttonCancel setBackgroundColor:[UIColor whiteColor]];
    [_buttonCancel setTag:1];
    //定时取消图标
    path = [[NSBundle mainBundle] pathForResource:@"btn_check@2x" ofType:@"png"];
    image = [UIImage imageWithContentsOfFile:path];
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
    path = [[NSBundle mainBundle] pathForResource:@"btn_point@2x" ofType:@"png"];
    image = [UIImage imageWithContentsOfFile:path];
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSString *pathCheck = [[NSBundle mainBundle] pathForResource:@"btn_check@2x" ofType:@"png"];
    UIImage *imageCheck = [UIImage imageWithContentsOfFile:pathCheck];
    NSString *pathUnCheck = [[NSBundle mainBundle] pathForResource:@"btn_point@2x" ofType:@"png"];
    UIImage *imageUnCheck = [UIImage imageWithContentsOfFile:pathUnCheck];
    //判断当前是那个按钮选择s
    if(appDelegate.currentAirInfo.switchStatus)
    {
        _lastSelectedButton = _buttonClose;
        //有定时
        _selectedView.hidden = NO;
        _labelSelected.text = [NSString stringWithFormat:@"%d%@%d%@%@",iHourPickerFrom.currentItemIndex,NSLocalizedString(@"hour", nil),iMinPickerFrom.currentItemIndex,NSLocalizedString(@"minute", nil),NSLocalizedString(@"close", nil)];
        [_labelCancel setTextColor:[UIColor blackColor]];
        [_labelClose setTextColor:RGB(0, 145, 241)];
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
    else
    {
        _lastSelectedButton = _buttonCancel;
        //无定时
        _selectedView.hidden = NO;
        _labelSelected.text = [NSString stringWithFormat:@"%d%@%d%@%@",iHourPickerFrom.currentItemIndex,NSLocalizedString(@"hour", nil),iMinPickerFrom.currentItemIndex,NSLocalizedString(@"minute", nil),NSLocalizedString(@"open", nil)];
        [_labelClose setTextColor:[UIColor blackColor]];
        [_labelCancel setTextColor:RGB(0, 145, 241)];
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
-(void)saveButtonClick
{
    //判断点击事件
    if(iMinPickerFrom.currentItemIndex == 0 && iHourPickerFrom.currentItemIndex == 0)
        return;
    else
    {
        double second = iMinPickerFrom.currentItemIndex * 60 + iHourPickerFrom.currentItemIndex * 3600;
        NSLog(@"second = %f",second);
         //插入数据库
        BLTimerInfomation *timerInfomation = [[BLTimerInfomation alloc] init];
        timerInfomation.secondCount = second;//定时秒数
        //开机状态
        if(_lastSelectedButton == _buttonCancel)
        {
            //定时开机
            timerInfomation.switchState = 1;
        }
        else if (_lastSelectedButton == _buttonClose)
        {
            timerInfomation.switchState = 0;
        }
        //当前时间戳
        NSDate *datenow = [NSDate date];
        timerInfomation.secondSince = (long)[datenow timeIntervalSince1970];
        NSLog(@"timerInfomation.secondSince = %ld",timerInfomation.secondSince);
        [sqlite insertOrUpdateTimerInfo:timerInfomation];
        //定时任务
        _refreshInfoTimer = [NSTimer  timerWithTimeInterval:second target:self selector:@selector(runTimer) userInfo:nil repeats:YES];
        [[NSRunLoop  currentRunLoop] addTimer:_refreshInfoTimer forMode:NSDefaultRunLoopMode];
        [_refreshInfoTimer fire];
        //返回按钮
        [self returnButtonClick];
    }
}

-(void)runTimer
{
    NSLog(@"_tmpTimerCount = %d",_tmpTimerCount);
    if(_tmpTimerCount == 0)
    {
        _tmpTimerCount ++;
        return;
    }
    //实例
    BeiAngSendDataInfo *tmpInfo = [[BeiAngSendDataInfo alloc] init];
    //判断点击的按钮
    if(_lastSelectedButton == _buttonCancel)
    {
        //定时开机
        NSLog(@"_buttonCancel");
        tmpInfo.switchStatus = 1;
    }
    else if (_lastSelectedButton == _buttonClose)
    {
        NSLog(@"_buttonClose");
        tmpInfo.switchStatus = 0;
    }
    //定时任务设置
    tmpInfo.childLockState = appDelegate.currentAirInfo.childLockState;
    [tmpInfo setAutoOrHand:appDelegate.currentAirInfo.autoOrHand];
    tmpInfo.sleepState = appDelegate.currentAirInfo.sleepState;
    tmpInfo.gearState = appDelegate.currentAirInfo.gearState;
    
    //发送数据
    dispatch_async(networkQueue, ^{
        [MMProgressHUD showWithTitle:NSLocalizedString(@"Network", nil) status:NSLocalizedString(@"Network", nil)];
        //数据透传
        NSData *response = [[NSData alloc] init];
        int code =[self sendDataCommon:tmpInfo response:response];
        if (code == 0)    //If success
        {
            [MMProgressHUD dismiss];
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *array = [[response objectFromJSONData] objectForKey:@"data"];
                BeiAngReceivedDataInfo *recvInfo = [[BeiAngReceivedDataInfo alloc] init];
                //数据转换
                recvInfo = [self turnArrayToBeiAngReceivedDataInfo:array];
                appDelegate.currentAirInfo = recvInfo;
                [_refreshInfoTimer invalidate];
                _refreshInfoTimer = nil;
                //更新数据库
                BLTimerInfomation *timerInfomation = [[BLTimerInfomation alloc] init];
                timerInfomation.switchState = recvInfo.switchStatus;
                timerInfomation.secondSince = 0;
                timerInfomation.secondCount = 0;//定时秒数
                [sqlite insertOrUpdateTimerInfo:timerInfomation];
            });
        }
        else    //Control failed
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MMProgressHUD dismiss];
                [self.view makeToast:[[response objectFromJSONData] objectForKey:@"msg"] duration:0.8f position:@"bottom"];
            });
        }
    });
}

//发送数据
-(int)sendDataCommon:(BeiAngSendDataInfo *)sendInfo response:(NSData *)response
{
    //数据透传
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:[NSNumber numberWithInt:9000] forKey:@"api_id"];
    [dic setObject:@"passthrough" forKey:@"command"];
    [dic setObject:appDelegate.deviceInfo.mac forKey:@"mac"];
    [dic setObject:@"bytes" forKey:@"format"];
    
    NSMutableArray *dataArray = [[NSMutableArray alloc ]init];
    for (int i = 0; i <= 24; i++)
    {
        if( i == 0)
            [dataArray addObject:[NSNumber numberWithInt:0xfe]];
        else if( i == 1)
            [dataArray addObject:[NSNumber numberWithInt:0x41]];
        else if( i == 4)
            [dataArray addObject:[NSNumber numberWithInt:sendInfo.switchStatus]];
        else if( i == 5)
            [dataArray addObject:[NSNumber numberWithInt:sendInfo.autoOrHand]];
        else if( i == 6)
            [dataArray addObject:[NSNumber numberWithInt:sendInfo.gearState]];
        else if( i == 7)
            [dataArray addObject:[NSNumber numberWithInt:sendInfo.sleepState]];
        else if( i == 8)
            [dataArray addObject:[NSNumber numberWithInt:sendInfo.childLockState]];
        else if( i == 23)
            [dataArray addObject:[NSNumber numberWithInt:0x00]];
        else if( i == 24)
            [dataArray addObject:[NSNumber numberWithInt:0xaa]];
        else
            [dataArray addObject:[NSNumber numberWithInt:0x00]];
    }
    [dic setObject:dataArray forKey:@"data"];
    
    NSData *sendData = [dic JSONData];
    NSLog(@"%@", [dic JSONString]);
    response = [networkAPI requestDispatch:sendData];
    int code = [[[response objectFromJSONData] objectForKey:@"code"] intValue];
    return code;
}

//根据传入的数组取得接受数据
-(BeiAngReceivedDataInfo *)turnArrayToBeiAngReceivedDataInfo:(NSArray *)array
{
    BeiAngReceivedDataInfo *recvInfo = [[BeiAngReceivedDataInfo alloc] init];
    //设置开关状态: 00 关机  01 打开
    [recvInfo setSwitchStatus:[array[4] intValue]];
    //手动自动状态: 00 手动状态  01 自动状态
    [recvInfo setAutoOrHand:[array[5] intValue]];
    //净化器运行档位状态: 00 0档位 01 1档 0x02 02 2档 03 3档
    [recvInfo setGearState:[array[6] intValue]];
    //睡眠状态: 00 不在睡眠状态  01睡眠状态
    [recvInfo setSleepState:[array[7] intValue]];
    //儿童锁状态: 00 不在儿童锁状态 01儿童锁状态
    [recvInfo setChildLockState:[array[8] intValue]];
    //设备类型: 01：280B。02：280C.03:车载04:AURA100.
    [recvInfo setDeviceType:[array[2] intValue]];
    //电极运行时间: 第一位为小时数
    [recvInfo setRunHours:[array[9] intValue]];
    //电极运行时间:第二位为分钟数(0x13,0x18:19小时24分钟)
    [recvInfo setRunMinutes:[array[10] intValue]];
    //空气质量档位: 01：一档，好。02：二档，中。03：三档，差
    [recvInfo setAirQualityGear:[array[11] intValue]];
    //空气质量原始数据: 数据
    [recvInfo setAirQualityData:[array[12] intValue]];
    [recvInfo setAirQualityDataB:[array[13] intValue]];
    //光照状态: 01：亮，02：昏暗，03：黑
    [recvInfo setLightCondition:[array[14] intValue]];
    //维护状态: 01：清洗电极，02：需要检查电极状态并断电重启
    [recvInfo setMaintenancesState:[array[15] intValue]];
    //温度: 带符号数：-127~127(0x8c:-12℃,0x12:18℃)
    [recvInfo setTemperature:[array[16] intValue]];
    //湿度: 不带符号数，0~100(0x39:57%)
    [recvInfo setHumidity:[array[17] intValue]];
    return recvInfo;
}

//返回按钮点击事件
-(void)returnButtonClick
{
    [self.navigationController popViewControllerAnimated:YES];
}

//取消按钮点击
-(void)cancelOrCloseClick:(UIButton *)button
{
    //判断没有点击
    if(_lastSelectedButton.tag == button.tag)
        return;
    NSString *pathCheck = [[NSBundle mainBundle] pathForResource:@"btn_check@2x" ofType:@"png"];
    UIImage *imageCheck = [UIImage imageWithContentsOfFile:pathCheck];
    NSString *pathUnCheck = [[NSBundle mainBundle] pathForResource:@"btn_point@2x" ofType:@"png"];
    UIImage *imageUnCheck = [UIImage imageWithContentsOfFile:pathUnCheck];
    //判断点击的按钮
    if(button.tag == 1)
    {
        //选择的隐藏
        _selectedView.hidden = NO;
        [_labelClose setTextColor:[UIColor blackColor]];
        [_labelCancel setTextColor:RGB(0, 145, 241)];
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
    else if (button.tag == 2)
    {
         //选择的显示
        _selectedView.hidden = NO;
        [_labelCancel setTextColor:[UIColor blackColor]];
        [_labelClose setTextColor:RGB(0, 145, 241)];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSUInteger)numberOfVisibleItemsInCarousel:(iCarousel *)carousel
{
    return 3;
}

- (NSUInteger)numberOfPlaceholdersInCarousel:(iCarousel *)carousel
{
    return 3;
}

- (void)carouselCurrentItemIndexUpdated:(iCarousel *)carousel
{
    int index2 = carousel.currentItemIndex;
    int index3 = carousel.currentItemIndex + 1;
    NSMutableArray *itemArray = (NSMutableArray *)carousel.visibleItemViews;
    UILabel *label1 = [itemArray objectAtIndex:0];
    UILabel *label2 = [itemArray objectAtIndex:1];
    UILabel *label3 = [itemArray objectAtIndex:2];
    if ([carousel isEqual:iHourPickerFrom])
    {
        
        if (index3 > 15)
        {
            label1.textColor = [UIColor lightGrayColor];
            label1.font = [UIFont systemFontOfSize:20.0f];
            label2.textColor = [UIColor lightGrayColor];
            label2.font = [UIFont systemFontOfSize:20.0f];
            label3.textColor = [UIColor blackColor];
            label3.font = [UIFont systemFontOfSize:45.0f];
        }
        else if (index2 == 0)
        {
            label1.textColor = [UIColor blackColor];
            label1.font = [UIFont systemFontOfSize:45.0f];
            label2.textColor = [UIColor lightGrayColor];
            label2.font = [UIFont systemFontOfSize:20.0f];
            label3.textColor = [UIColor lightGrayColor];
            label3.font = [UIFont systemFontOfSize:20.0f];
        }
        else
        {
            label1.textColor = [UIColor lightGrayColor];
            label1.font = [UIFont systemFontOfSize:20.0f];
            label2.textColor = [UIColor blackColor];
            label2.font = [UIFont systemFontOfSize:45.0f];
            label3.textColor = [UIColor lightGrayColor];
            label3.font = [UIFont systemFontOfSize:20.0f];
        }
    }
    
    if ([carousel isEqual:iMinPickerFrom])
    {
        if (index3 > 59)
        {
            label1.textColor = [UIColor lightGrayColor];
            label1.font = [UIFont systemFontOfSize:20.0f];
            label2.textColor = [UIColor lightGrayColor];
            label2.font = [UIFont systemFontOfSize:20.0f];
            label3.textColor = [UIColor blackColor];
            label3.font = [UIFont systemFontOfSize:45.0f];
        }
        else if (index2 == 0)
        {
            label1.textColor = [UIColor blackColor];
            label1.font = [UIFont systemFontOfSize:45.0f];
            label2.textColor = [UIColor lightGrayColor];
            label2.font = [UIFont systemFontOfSize:20.0f];
            label3.textColor = [UIColor lightGrayColor];
            label3.font = [UIFont systemFontOfSize:20.0f];
        }
        else
        {
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
    if(!appDelegate.currentAirInfo.switchStatus)
        _labelSelected.text = [NSString stringWithFormat:@"%d%@%d%@%@",iHourPickerFrom.currentItemIndex,NSLocalizedString(@"hour", nil),iMinPickerFrom.currentItemIndex,NSLocalizedString(@"minute", nil),NSLocalizedString(@"open", nil)];
    else
        _labelSelected.text = [NSString stringWithFormat:@"%d%@%d%@%@",iHourPickerFrom.currentItemIndex,NSLocalizedString(@"hour", nil),iMinPickerFrom.currentItemIndex,NSLocalizedString(@"minute", nil),NSLocalizedString(@"close", nil)];
}

- (UIView *)carousel:(iCarousel *)carousel viewForItemAtIndex:(NSUInteger)index reusingView:(UIView *)view
{
    if (view == nil)
	{
        view = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, carousel.frame.size.width, carousel.frame.size.height / 3.f)];
    }
    
    ((UILabel *)view).textAlignment = NSTextAlignmentCenter;
    ((UILabel *)view).font = [UIFont systemFontOfSize:11.0f];
    ((UILabel *)view).textColor = [UIColor lightGrayColor];
    ((UILabel *)view).backgroundColor = [UIColor clearColor];
    
    ((UILabel *)view).text = [NSString stringWithFormat:@"%02i", index];
    
    return view;
}

- (CGFloat)carouselItemWidth:(iCarousel *)carousel
{
    //usually this should be slightly wider than the item views
    return carousel.frame.size.width / 2.f;
}

//必须的方法
- (NSUInteger)numberOfItemsInCarousel:(iCarousel *)carousel
{
    NSUInteger count = 0;
    if ([carousel isEqual:iHourPickerFrom] )
    {
        count = 16;
    }
    else if ([carousel isEqual:iMinPickerFrom])
    {
        count = 60;
    }
    return count;
}

- (CGFloat)carousel:(iCarousel *)carousel itemAlphaForOffset:(CGFloat)offset
{
	//set opacity based on distance from camera
    return 1.0f - fminf(fmaxf(offset, 0.0f), 1.0f);
}

- (CATransform3D)carousel:(iCarousel *)_carousel itemTransformForOffset:(CGFloat)offset baseTransform:(CATransform3D)transform
{
    //implement 'flip3D' style carousel
    transform = CATransform3DRotate(transform, M_PI / 8.0f, 0.0f, 1.0f, 0.0f);
    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * _carousel.itemWidth);
    //    return CATransform3DTranslate(transform, 0.0f, 0.0f, offset * _carousel.itemWidth);
}

- (BOOL)carouselShouldWrap:(iCarousel *)carousel
{
    return YES;
}

- (BOOL)carousel:(iCarousel *)carousel shouldSelectItemAtIndex:(NSInteger)index
{
    return YES;
}
@end
