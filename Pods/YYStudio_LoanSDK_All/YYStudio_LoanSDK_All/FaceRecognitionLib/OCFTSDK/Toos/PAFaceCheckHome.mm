//
//  PAFaceCheckHome.m
//  PAFaceCheck
//
//  Created by prliu on 16/2/18.
//  Copyright © 2016年 PingAN. All rights reserved.
//

#import "PAFaceCheckHome.h"
#import <OCFTFaceDetect/OCFTFaceDetector.h>
#import "PABottomView.h"
#import "PAPromptView.h"
#import "PACircularRing.h"
#import <sys/utsname.h>
#include <CoreGraphics/CGAffineTransform.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PAZCLDefineTool.h"
#import "PAZCLTools.h"


@interface PAFaceCheckHome () <OCFTFaceDetectProtocol,  AVAudioPlayerDelegate, PAPromptDelegate,AVSpeechSynthesizerDelegate>
{
    PAPromptView *promptView;
    NSString *soundStr;
    NSInteger _maxTime;
    int _timerTimeCount;
    
}

@property (nonatomic, weak) id <PACheckDelegate>delegate;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureStillImageOutput *output;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property(nonatomic, readwrite) AVCaptureVideoOrientation videoOrientation;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) AVCaptureDevice *device;

@property (nonatomic, strong) OCFTFaceDetector *livenessDetector;
@property (nonatomic, assign) BOOL starLiveness;            //表示是否开启活体检测
@property (nonatomic, strong) PABottomView *bottomView;

@property (nonatomic) BOOL soundContor;
@property (nonatomic) BOOL faceControl;
@property (nonatomic) BOOL simplificationContor;
@property (nonatomic) BOOL countDown;
@property (nonatomic) BOOL isOk;
@property (nonatomic) BOOL isEnvironmentOk;
@property (nonatomic) BOOL firstOk;
@property (nonatomic) BOOL glassesSwitch;
@property (nonatomic) BOOL advertisingSwitch;

@property (nonatomic, strong) UILabel *numLabel;
@property (nonatomic, strong) UILabel *advertising;
@property (nonatomic, strong) NSTimer *timerCoundDown;
@property (nonatomic, strong) UIImageView *rotationView;

@property (nonatomic, strong) UIImageView *faceCheckBackground;
@property (nonatomic, strong) UIView *menuView;;

@property (nonatomic, strong)NSString *advertisingStr;
@property (nonatomic, assign)NSString *number0fAction;

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;     //Text转语音
@property (nonatomic, strong) AVSpeechUtterance *utterance;
@property (nonatomic, strong) AVSpeechSynthesisVoice *voiceType;

@end

@implementation PAFaceCheckHome

- (id)initWithPAcheckWithTheCountdown :(BOOL)countDown andTheAdvertising:(NSString*)advertising  number0fAction:(NSString*)num voiceSwitch:(BOOL)voiceSwitch delegate:(id <PACheckDelegate>)faceDelegate
{
    self = [super init];
    if (self) {
        
        self.delegate = faceDelegate;
        if ( advertising && ![advertising isEqualToString:@""] && ![advertising isEqualToString:@"(nil)"]) {
            self.advertisingSwitch = YES;
            self.advertisingStr = advertising;
            
        }else{
            self.advertisingSwitch = NO;
        }
        self.number0fAction = num;
        self.countDown = countDown;
        self.soundContor = voiceSwitch;
    }
    return self;
}

- (void)viewDidLoad{
    
    [super viewDidLoad];
    
    [self initBar];             //初始化bar
    [self initAVSpeech];        //初始化语音
    [self.bottomView showPromtpView];//底部图片

    [self createFacecheck];     //FaceCheck初始化
    [self setUpCameraLayer];    //加载图层预览
    //埋点
    [[NSNotificationCenter defaultCenter] postNotificationName:kFCTrackNotification object:self userInfo:@{@"TrackLabel":@"人脸识别_开启"}];
}




#pragma  mark -- 处理图片数据

- (void)sendImage:(OCFTFaceDetectionFrame*)imageFrame{
    
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    dispatch_async(mainQueue, ^{
        
        
       
        //结束
        [self backToAppAnimated:NO];
        
        if (self.navigationController && self.navigationController.viewControllers.count > 1) {
            
            [self.navigationController popViewControllerAnimated:NO];
            
        } else {
            
            [self dismissViewControllerAnimated:NO completion:^{
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(getPacheckreportWithImage:andTheFaceImage:andTheFaceImageInfo:andTheResultCallBlacek:)]){
                    
                    [self.delegate getPacheckreportWithImage:imageFrame.originalImage andTheFaceImage:imageFrame.headImage andTheFaceImageInfo:imageFrame.locationInfo  andTheResultCallBlacek:^(NSDictionary *content) {
                        
                        if (content) {
                            
//                            [SVProgressHUD dismiss];
                            
                        }
                    }];
                }
                
                
            }];
        }
    });
    
}
- (BOOL)prefersStatusBarHidden {
    [super prefersStatusBarHidden];
    
    return self.navigationController.navigationBarHidden;
}


-(void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    //    [UIApplication sharedApplication].statusBarHidden = YES;//隐藏
    
}
-(void)viewWillDisappear:(BOOL)animated

{
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];
    //     [UIApplication sharedApplication].statusBarHidden = NO;//不隐藏
    
}


#pragma mark ---- 初始化bar

- (void)initBar{
    
    
    //采集框
    self.faceCheckBackground = [[UIImageView alloc] init];
    self.faceCheckBackground.translatesAutoresizingMaskIntoConstraints = NO;
    
//    if (kScreenWidth == 320) {
//        [self.faceCheckBackground setImage:kFaceImage(@"PAFace6401136@2x.png")];
//    }else if(kScreenWidth == 375){
//        [self.faceCheckBackground setImage:kFaceImage(@"PAFace7501334@2x.png")];
//    }else if(kScreenWidth == 414){
//        [self.faceCheckBackground setImage:kFaceImage(@"PAFace12422208@2x.png")];
//    }else{
//        [self.faceCheckBackground setImage:kFaceImage(@"PAFace12422208@2x.png")];
//    }
      [self.faceCheckBackground setImage:kFaceImage(@"facebgicon")];
    [self.view addSubview:self.faceCheckBackground];
//        bg.frame = CGRectMake(0, 0, 375 * [UIScreen mainScreen].bounds.size.width/375, kScaleHeight6(491));
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.faceCheckBackground attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:-10]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.faceCheckBackground attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:10]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.faceCheckBackground attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    if (kScreenHeight > 736 ) {
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.faceCheckBackground attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0.66 constant:0]];
    } else {
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.faceCheckBackground attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0.75 constant:0]];
    }
    
    
    //底层蒙板
    self.menuView = [[UIView alloc]init];
    self.menuView.translatesAutoresizingMaskIntoConstraints = NO;
    self.menuView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.menuView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.menuView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:-10]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.menuView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:10]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.menuView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.menuView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0.2 constant:0]];
    
    //广告语
    if (self.advertisingSwitch) {
        
        UIFont *fontName = [UIFont systemFontOfSize:16.0f];
        
        
        self.advertising = [[UILabel alloc]init];
        self.advertising.alpha = 0.6;
        [self.advertising setFont:fontName];
        [self.advertising setTextColor:[UIColor blackColor]];
        [self.advertising setText:self.advertisingStr];
        self.advertising.textAlignment  = NSTextAlignmentCenter;
        
        self.advertising.numberOfLines = 0;
        self.advertising.lineBreakMode = NSLineBreakByWordWrapping;
        
        NSDictionary *attribute = @{NSFontAttributeName: fontName};
        CGSize sizeName = [self.advertisingStr boundingRectWithSize:CGSizeMake(kScreenWidth,MAXFLOAT) options: NSStringDrawingTruncatesLastVisibleLine |NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attribute context:nil].size;
        
        [self.view addSubview:self.advertising];
        
        self.advertising.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.advertising attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.advertising attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
        
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.advertising attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:0.75 constant:0]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.advertising attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0 constant:sizeName.height]];
        
    }
    
    [self initFaceActionView];  //动作提示界面
    
    
    //返回按钮
    UIImage *butImage = kFaceImage(@"BarArrowLeftWhite");//Face_backBut
    UIButton *backButton = [[UIButton alloc]init];
    [backButton setBackgroundColor:[UIColor clearColor]];
    backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [backButton setBackgroundImage:butImage forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backToAppAnimatedWhenClickBlack:) forControlEvents:UIControlEventTouchDown];
    [self.menuView addSubview:backButton];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeRight multiplier:0.07 constant:0]];//0.1
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeHeight multiplier:0.15 constant:0]];//0.35
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:backButton attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeHeight multiplier:0.25 constant:0]];//0.35
    
}




#pragma mark ---- FaceCheck初始化

- (void)createFacecheck{
    
    NSDictionary *options = @{
                              OCFTFaceDetectorActionTypes:self.number0fAction,
                              OCFTFaceDetectorOuputLocation:@true
                              };
    self.livenessDetector = [OCFTFaceDetector getDetectorWithOptions:options delegate:self];
    NSString *version = [[OCFTFaceDetector getSDKInfo] version];
    NSLog(@"%------@", version);
    
}

#pragma mark ---- 活体动作提示界面

- (void)initFaceActionView{
    
    self.bottomView = [[PABottomView alloc] init];
    [self.bottomView initWithTheCountDown:self.countDown andTheFaceConter:self.faceControl];
    self.bottomView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.bottomView setBackgroundColor:[UIColor clearColor]];
    [self.menuView addSubview:self.bottomView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeWidth multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.bottomView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeHeight multiplier:1 constant:0]];
    
}

#pragma mark ---- 识别提示倒计时

- (void)createPAPromptView{
    
    promptView = [[PAPromptView alloc] initWithFrame:CGRectMake(kScaleWidth(20), kScaleHeight(80), kScreenWidth, kScaleHeight(200)) andTheSoundContor:self.soundContor];
    [promptView setBackgroundColor:[UIColor clearColor]];
    promptView.delegate = self;
    promptView.hidden = YES;
    [promptView showPrompt];
    [self.view addSubview:promptView];
    
}

#pragma mark --- 提示UI

- (void)promptViewFinish{
    
    [self createNoFaceContorTimeView:kActionTime];//不需要活体时的倒计时
    [self startcheckFace];
}

#pragma mark --- 启动活体检测

- (void)startcheckFace{
    
    //启动活体步骤
    [self startSession];
    //开启活体检测
    [self starLivenessWithBuff];
    //[self.bottomView closePromtpView];
    
    
}
#pragma mark --- 活体检测开启后，相应提示（界面）
/**
 *  开启活体检测（唯一入口，第一次进入后，转到“动作检测成功时”）
 */
-(void)starLivenessWithBuff{
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime,dispatch_get_main_queue(), ^(void){
        
        [self initHardCode:YES];
        [self startAnimation];
        
    });
    
}

/**
 *  停止活体检测步骤
 */
- (void)stopcheckFace{
    
    _starLiveness = NO;
    [promptView hidePrompt];
    [self.bottomView stopRollAnimation];
    
    if (self.session) {
        [self.session stopRunning];
        [self.session removeInput:self.videoInput];
        [self.session removeOutput:self.output];
        self.session = nil;
        if (self.videoInput) {
            self.videoInput = nil;
        }
        if (self.output) {
            self.output = nil;
        }
    }
    
    //停止语音
    [self playerStop];
}

/**
 *  开启相机
 */
- (void)startSession{
    if (self.session) {
        [self.session startRunning];
    }
}

/**
 *  加载相机图层预览
 */
- (void) setUpCameraLayer
{
    //判断是否允许用摄像头设备
    BOOL userAllow = [self toDetermineWhetherAuserAllowsCameraOperation];
    if (userAllow) {
        CALayer * viewLayer = [self.view layer];
        [viewLayer insertSublayer:[self.livenessDetector videoPreview] below:[[viewLayer sublayers] objectAtIndex:0]];
        [self.view bringSubviewToFront:self.bottomView];
    } else {
         NSError *err = [NSError errorWithDomain:@"摄像头不允许操作" code:OCFT_CAMERA_AUTH_FAIL userInfo:nil];
           [self checkFail:err];
    }
}


/**
 *  动作提示动画及声音
 */
- (void)starAnimation:(OCFTFaceDetectActionType)types{
    
    //换语音
    [self playerWith:types];
    //换图
    [self.bottomView willChangeAnimation:types outTime:kActionTime];
}

/**
 *  动作提示声音
 */
- (void)playerWith:(OCFTFaceDetectActionType)types{
    
    switch(types){
        case OCFT_COLLECTFACE:
        {
            //soundStr = @"2_eye";
            soundStr = @"缓慢眨眼";
            break;
        }
        case OCFT_MOUTH:
        {
            //soundStr = @"5_openMouth";
            soundStr = @"缓慢张嘴";
            break;
        }
        case OCFT_HEAD:
        {
            //soundStr = @"4_headshake";
            soundStr = @"缓慢摇头";
            break;
        }
        default:
        {
            return;
            break;
        }
    }
    [self playerStop];
    [self textToAudioWithStirng:soundStr];
    
}

/**
 *  播放活体动作类型声音
 */
- (void)playSound{
    
    [self textToAudioWithStirng:soundStr];
}

- (void)sendViewClickedButtonAtIndex:(NSInteger)index{}

/**
 *  Text转语音
 */
-(void)textToAudioWithStirng:(NSString*)textString{
    
    if (self.soundContor) {
        
        self.utterance = [AVSpeechUtterance speechUtteranceWithString:textString];
        //设置语言类别（不能被识别，返回值为nil） @"zh-CN"国语 @"zh-HK"粤语  @"zh-TW"台湾
        //self.voiceType = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
        //self.utterance.voice = self.voiceType;
        //设置语速快慢
        self.utterance.rate = 0.4;
        //语音合成器会生成音频
        [self.synthesizer speakUtterance:self.utterance];
    }
    
}

/**
 *  返回
 */
- (void)backToAppAnimated:(BOOL)animated{
    
    [self stopcheckFace];
    
    if (self.timerCoundDown) {
        [self stopAnimations];
        
    }
    
    if (self.livenessDetector) {
        
        self.livenessDetector = nil;
    }
    if (promptView) {
        
        [promptView removeFromSuperview];
        promptView = nil;
        [self.bottomView removeFromSuperview];
        self.bottomView = nil;
    }
//    [SVProgressHUD dismiss];
    
    
}
#pragma mark --- 判断用户是否允许操作摄像头
-(BOOL)toDetermineWhetherAuserAllowsCameraOperation{
    
     NSError *err = [NSError errorWithDomain:@"摄像头不允许操作" code:OCFT_CAMERA_AUTH_FAIL userInfo:nil];
    NSString *mediaType = AVMediaTypeVideo;// Or AVMediaTypeAudio
    
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    
    if(authStatus ==AVAuthorizationStatusRestricted){//拒绝访问
        
        //NSLog(@"拒绝访问");
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self checkFail:err];
            
        });
        return NO;
        
    }else if(authStatus == AVAuthorizationStatusDenied){
        
        //NSLog(@" 用户已经明确否认了这一照片数据的应用程序访问.");
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self checkFail:err];
            
        });
        return NO;
        
    }
    
    else if(authStatus == AVAuthorizationStatusAuthorized){//允许访问
        
        //NSLog(@"允许访问");
        return YES;
        
        
    }else if(authStatus == AVAuthorizationStatusNotDetermined){//不明确
        
        
        [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
            
            if(granted){//点击允许访问时调用
                
                //NSLog(@"不明确,点击允许访问时调用");
            }
            
            else {
                
                //NSLog(@"不明确,点击不允许访问时调用");
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self checkFail:err];
                    
                });
                
            }
            
        }];
        
    }
    return NO;
}

#pragma mark ----  初始化语音提示
/**
 *  初始化语音提示
 */
-(void)initAVSpeech{
    
    if (self.soundContor) {
        
        self.synthesizer = [[AVSpeechSynthesizer alloc] init];
        self.synthesizer.delegate = self;
        
    }
    
    
}
/**
 *  停止播放
 */
- (void)playerStop{
    
    if (self.synthesizer.speaking) {
        
        [self.synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        
    }
}


/**
 *  切换前后摄像头
 */
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

/**
 *  前置摄像头
 */
- (AVCaptureDevice *)frontCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

/**
 *  后置摄像头
 */
- (AVCaptureDevice *)backCamera {
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

//前后摄像头的切换
- (void)toggleCamera:(id)sender{
    NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
    if (cameraCount > 1) {
        NSError *error;
        AVCaptureDeviceInput *newVideoInput;
        AVCaptureDevicePosition position = [[_videoInput device] position];
        
        if (position == AVCaptureDevicePositionBack)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self frontCamera] error:&error];
        else if (position == AVCaptureDevicePositionFront)
            newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:&error];
        else
            return;
        
        if (newVideoInput != nil) {
            [self.session beginConfiguration];
            [self.session removeInput:self.videoInput];
            if ([self.session canAddInput:newVideoInput]) {
                [self.session addInput:newVideoInput];
                
                [self setVideoInput:newVideoInput];
                
            } else {
                [self.session addInput:self.videoInput];
            }
            [self.session commitConfiguration];
        } else if (error) {
            NSLog(@"toggle carema failed, error = %@", error);
        }
    }
}

#pragma  mark -- 不做活体检测时的倒计时

-(void)createNoFaceContorTimeView:(int)Maxtime{
    
    _maxTime = Maxtime;
    
    _timerTimeCount = 0;//累计时间
    self.timerCoundDown = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(theCounterDownWithCurrent:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timerCoundDown forMode:UITrackingRunLoopMode];
    [[NSRunLoop currentRunLoop] addTimer:self.timerCoundDown forMode:NSDefaultRunLoopMode];
    [self.timerCoundDown fire];
    
    self.rotationView = [[UIImageView alloc] initWithImage:kFaceImage(@"Face_timeAnimation")];
    
    self.numLabel = [[UILabel alloc] init];
    [self.numLabel setTextAlignment:NSTextAlignmentCenter];
    [self.numLabel setFont:[UIFont systemFontOfSize:kScaleWidth(18)]];
    [self.numLabel setTextColor:kTextColor];
    [self.numLabel setBackgroundColor:[UIColor clearColor]];
    self.numLabel.text = [NSString stringWithFormat:@"%ld", (long)_maxTime];
    
    //添加约束
    self.rotationView.translatesAutoresizingMaskIntoConstraints = NO;;
    self.numLabel.translatesAutoresizingMaskIntoConstraints = NO;;
    
    [self.menuView addSubview:self.numLabel];
    [self.menuView addSubview:self.rotationView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.rotationView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeRight multiplier:0.9 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.rotationView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.rotationView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeHeight multiplier:0.30 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.rotationView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeHeight multiplier:0.30 constant:0]];
    
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.numLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.rotationView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.numLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.rotationView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.numLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeHeight multiplier:0.30 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.numLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.menuView attribute:NSLayoutAttributeHeight multiplier:0.30 constant:0]];
    
    //是否隐藏
    [self.rotationView setHidden:YES];
    [self.numLabel setHidden:YES];
    
}
#pragma mark ---- 倒计时动画,开

- (void)startAnimation{
    
    if (self.countDown) {
        [self.rotationView setHidden:NO];
        [self.numLabel setHidden:NO];
    }else{
        [self.rotationView setHidden:YES];
        [self.numLabel setHidden:YES];
    }
    [self.view addSubview:self.rotationView];
    [self.view addSubview:self.numLabel];
    
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0];
    rotationAnimation.duration = 1.0f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = kActionTime;
    [self.rotationView.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    
    
}

#pragma mark ---- 倒计时动画-关

- (void)stopAnimations{

    [self.rotationView.layer removeAllAnimations];
    [self.timerCoundDown invalidate];
    self.timerCoundDown = nil;
    [self.rotationView setHidden:YES];
    [self.numLabel setHidden:YES];
    _timerCoundDown = 0;
}

/**
 * 设置
 */
- (void)initHardCode:(BOOL)check{
    _starLiveness = check;
}

#pragma mark - PromptDelegate
/**
 *  开始倒计时回调
 */
- (void)promptViewwillFinish{
    //停止指引语音提示
    [self playerStop];
}



#pragma mark - AVAudioPlayerDelegate
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{
    [player pause];
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    
}

//程序中断结束返回程序时，继续播放
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    [player play];
}


#pragma mark - PALivenessProtocolDelegate
/**
 *  @brief  倒计时
 *
 *  @return 剩余时间
 */
//- (void)PAPermissionOfCamer:(AVAuthorizationStatus)camerState{
-(void)onStartDetection:(NSDictionary *)info{
    [self promptViewFinish];
}

-(void)theCounterDownWithCurrent:(NSTimer *)timer{
    if (_timerTimeCount > _maxTime) {
        NSError *err = [NSError errorWithDomain:@"界面操作_超出倒计时时间" code:-1001 userInfo:nil];
        [self checkFail:err];
        //埋点
        [[NSNotificationCenter defaultCenter] postNotificationName:kFCTrackNotification object:self userInfo:@{@"TrackLabel":@"人脸识别_超时"}];
    }
    MAIN_ACTION((^(){
        self.numLabel.text = [NSString stringWithFormat:@"%ld",_maxTime - (long)_timerTimeCount +1];
        _timerTimeCount++;
    }));
    
}

#pragma mark - 检测过程中对于用户行为的建议

/**
 *  @brief  检测过程中对于用户行为的建议
 *
 *  @param testType 用户行为错误类型
 */

-(void)onSuggestingOptimization:(OCFTFaceDetectOptimizationType)type{
    
    MAIN_ACTION((^{
        [self.bottomView promptLabelText:type];
    }));
    
}

#pragma mark - 检脸成功，进入动作环节

/**
 *  @brief  动作检测
 *
 *  @param animationType 用户动作类型
 */
-(void)onDetectionChangeAnimation:(OCFTFaceDetectActionType)type options:(NSDictionary*)options{
    
    MAIN_ACTION((^{
        [self stopAnimations];
        [self.bottomView closePromtpView];
        [self starAnimation:type];
    }));
    
}

- (IBAction)turnCamera:(id)sender {
    
    NSArray *inputs = _session.inputs;
    for ( AVCaptureDeviceInput *input in inputs )
    {
        AVCaptureDevice *device = input.device;
        if ([device hasMediaType:AVMediaTypeVideo])
        {
            AVCaptureDevicePosition position = device.position;
            AVCaptureDevice *newCamera = nil;
            AVCaptureDeviceInput *newInput = nil;
            
            if (position == AVCaptureDevicePositionFront)
            {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
            }
            else
            {
                newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
            }
            self.device = newCamera;
            newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            
            // beginConfiguration ensures that pending changes are not applied immediately
            [_session beginConfiguration];
            
            [_session removeInput:input];
            [_session addInput:newInput];
            
            // Changes take effect once the outermost commitConfiguration is invoked.
            [_session commitConfiguration];
            break;
        }
    }
}



#pragma mark - 当前活体检测的动作检测失败时，调用此方法。
/*!
 *  当前活体检测的动作检测失败时，调用此方法。
 *
 *  @param failedType 动作检测失败的原因（具体选项请参照PALivenessDetectionFailedType）
 *  @return 无
 */
-(void)onDetectionFailed:(OCFTFaceDetectFailedType)failedType{
    
    MAIN_ACTION((^(){
//        [SVProgressHUD showWithStatus:@"请稍后"];
        [self stopcheckFace];
        [self stopAnimations];
        NSError *err = [NSError errorWithDomain:@"OCFT_FACE_CHECK_ERROR" code:failedType userInfo:nil];
        [self checkFail:err];
    }));
}
#pragma mark - 检测成功时，调用此方法。

-(void)onDetectionSuccess:(OCFTFaceDetectionFrame *)faceInfo{
    
    MAIN_ACTION(^()
                {
                    //停止活体检测步骤
                    [self stopcheckFace];
//                    [SVProgressHUD showWithStatus:@"请稍后"];
                    [self sendImage:faceInfo];
                    
                });
}


#pragma mark ---  失败回调

- (void)checkFail:(NSError *)error{
    
    MAIN_ACTION((^(){
        
        [self initHardCode:NO];
        [self stopcheckFace];
//        [SVProgressHUD showWithStatus:@"请稍后"];
        
        [self backToAppAnimated:YES];
        
        if (self.navigationController && self.navigationController.viewControllers.count > 1) {
            
            [self.navigationController popViewControllerAnimated:NO];
            
        } else {
            
            [self dismissViewControllerAnimated:NO completion:^{

                if (self.delegate && [self.delegate respondsToSelector:@selector(getSinglePAcheckReport:error:andThePAFaceCheckdelegate:)]){
                    [self.delegate getSinglePAcheckReport:nil error:error andThePAFaceCheckdelegate:self];
                }
            }];
        }
    }));
}


#pragma mark - 返回按钮触发事件

- (void)backToAppAnimatedWhenClickBlack:(UIButton*)blackB{
    NSError *err = [NSError errorWithDomain:@"界面操作_用户点击返回退出检测" code:-1000 userInfo:nil];
    [self checkFail:err];
}


#pragma mark --- 转屏--BUG，对于iPadmini不起作用

/**
 *  ios6下禁止横屏
 */
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    

    return NO;
}

- (BOOL)shouldAutorotate
{
    // Disable autorotation of the interface when recording is in progress.
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;//目前检脸 只限于图片尺寸为480X640
}


- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;

    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
        self.previewLayer.frame = CGRectMake(0, 0, size.width, size.height);
        self.previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
    }
}

- (void)dealloc {
    
    NSLog(@" PAFacecheck dealloc");
    
}


@end
