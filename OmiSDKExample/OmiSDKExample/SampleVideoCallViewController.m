//
//  OMIVideoCallViewController.m
//  OmiKit
//
//  Created by VietHQ on 2022/11/14.
//
/**
 The Flow:
 - show view , init component need for call ( Exept Video call component )
 - receive event Call confirm to start process if it video call :
    - Start init Camera View
    - Start Stream for Video View
 - Receive event durring call for update View:
    - Event OMICallNetworkQualityNotification about network Stats: ( Good/Medium/Bad )
    - Event OMICallStateChangedNotification for call status ( Disconnected/ Confirmed .. )
    - Listen OMICallVideoInfoNotification event about Video call update and need re-create view
 */
#import "SampleVideoCallViewController.h"
#import <OmiKit/OMIVideoViewManager.h>
#import <OmiKit/OMIVideoPreviewView.h>
#import <OmiKit/OmiClient.h>
#import <OmiKit/OMILogging.h>

#import <AVFoundation/AVFoundation.h>
#import "Masonry/Masonry.h"


@interface SampleVideoCallViewController ()

@property (nonatomic, strong) OMIVideoViewManager *videoManager;

@property (nonatomic, strong) OMIVideoPreviewView *remoteVideoRenderView;
@property (nonatomic, strong) OMIVideoPreviewView *localVideoRenderView;

@property (nonatomic, strong) UIButton *backButton;

@property (nonatomic, strong) UIButton *switchCameraButton;

@property (nonatomic, strong) UIButton *cameraOnButton;
@property (nonatomic, strong) UIButton *micButton;
@property (nonatomic, strong) UIButton *endCallButton;
 
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, strong) UIImageView *networkStatus;
@property (nonatomic) CGSize originalSize;
@property (nonatomic) NSArray *viewArray;


@end

@implementation SampleVideoCallViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];
    OMILogDebug(@"log: %@",[[OmiClient getListOutputDevices] description]);
    _originalSize = (CGSize){100, 100};
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callStateChanged:)
                                                 name:OMICallStateChangedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(callDealloc:)
                                                 name:OMICallDeallocNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoNotification:) name:OMICallVideoInfoNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateNetworkHealth:) name:OMICallNetworkQualityNotification object:nil];

    
}

-(void) updateNetworkHealth:(NSNotification *) noti {
    NSDictionary *dic = [noti userInfo];
    NSNumber * state = [dic valueForKey:OMINotificationNetworkStatusKey];
    switch([state intValue]){
        case OMINetworkGood:{
            [self.networkStatus setImage: [UIImage imageNamed: @"network_best"]];
            break;
        }
        case OMINetworkMedium:{
            [self.networkStatus setImage: [UIImage imageNamed: @"network_medium"]];
            break;
        }
        case OMINetworkBad:{
            [self.networkStatus setImage: [UIImage imageNamed: @"network_bad"]];
            break;
        }
    }
}


/**
 *  This function got notification when receive signal video from remote side
 *  We need call function to re-render view
 */
-(void) videoNotification:(NSNotification *) noti {
    NSDictionary *dic = [noti userInfo];
    NSNumber * state = [dic valueForKey:OMIVideoInfoState];
    switch([state intValue]){
        case OMIVideoRemoteReady:{
            [self startPreview];
            break;
        }
    }
}

-(void)setUpView{
    self.view.backgroundColor = UIColor.grayColor;
    // request camera access
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        
    }];
    
    self.videoManager = [[OMIVideoViewManager alloc] init];
    

    // back button
    self.backButton = [[UIButton alloc] init];
    [self.view addSubview:self.backButton];
    [self.backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view).inset(14);
        make.top.equalTo(self.mas_topLayoutGuide).inset(14);
        make.width.height.equalTo(@(32));
    }];
    
    self.networkStatus = [[UIImageView alloc] init];
    [self.networkStatus setImage: [UIImage imageNamed: @"network_best"]];
    self.networkStatus.contentMode = UIViewContentModeScaleAspectFit;
    
    [self.view addSubview:self.networkStatus];
    [self.networkStatus mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX;
        make.top.equalTo(self.mas_topLayoutGuide).inset(18);
        make.width.height.equalTo(@(18));
    }];
    
    [self.backButton setImage:[self imageNamed:@"back"] forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    

    // remote view
    // mic on/off
    self.micButton = [[UIButton alloc] init];
    [self.view addSubview:self.micButton];
    [self.micButton setImage:[self imageNamed:@"mic"] forState:UIControlStateNormal];
    [self.micButton addTarget:self action:@selector(micOnOff) forControlEvents:UIControlEventTouchUpInside];
    
    // hang up
    self.endCallButton = [[UIButton alloc] init];
    [self.view addSubview:self.endCallButton];
    [self.endCallButton setImage:[self imageNamed:@"hangup"] forState:UIControlStateNormal];
    [self.endCallButton addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];

    // more
    self.moreButton = [[UIButton alloc] init];
    [self.view addSubview:self.moreButton];
    [self.moreButton setImage:[self imageNamed:@"more"] forState:UIControlStateNormal];
    [self.moreButton addTarget:self action:@selector(more) forControlEvents:UIControlEventTouchUpInside];

   
   
    self.viewArray = @[self.micButton,  self.endCallButton, self.moreButton];
    
    [self.viewArray mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedItemLength:64 leadSpacing:24 tailSpacing:24];
    [self.viewArray mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view.mas_bottom).inset(32);
        make.height.equalTo(@(64));
    }];

}

-(void) updateScreenUIForVideoCall {
    if([OMIEndpoint sharedEndpoint].isSupportVideo){
        
        /**
         autolayout subviews below.
         */
        self.remoteVideoRenderView = [[OMIVideoPreviewView alloc] init];
        [self.view insertSubview: self.remoteVideoRenderView atIndex:0];
        [self.remoteVideoRenderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.left.right.bottom.equalTo(self.view);
        }];
        
        // camera switch button
        self.switchCameraButton = [[UIButton alloc] init];
        [self.view addSubview:self.switchCameraButton];
        [self.switchCameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.view).inset(14);
            make.top.equalTo(self.backButton);
            make.width.height.equalTo(@(32));
        }];
        
        [self.switchCameraButton setImage:[self imageNamed:@"refresh"] forState:UIControlStateNormal];
        [self.switchCameraButton addTarget:self action:@selector(switchCamera) forControlEvents:UIControlEventTouchUpInside];
        
        
        /**
         *  remote video
         */
        self.localVideoRenderView = [[OMIVideoPreviewView alloc] init];
        self.localVideoRenderView.backgroundColor = [UIColor blackColor];
        [self.view addSubview:self.localVideoRenderView];
        [self.localVideoRenderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self.view).inset(14);
            make.width.height.equalTo(self.view).multipliedBy(0.3);
            make.top.equalTo(self.switchCameraButton.mas_bottom).offset(14);
        }];
       
        self.localVideoRenderView.layer.cornerRadius = 5;
        self.localVideoRenderView.layer.borderColor = [UIColor grayColor].CGColor;
        self.localVideoRenderView.layer.borderWidth = 1.0;
        self.localVideoRenderView.layer.masksToBounds = YES;
   
        self.cameraOnButton = [[UIButton alloc] init];
        [self.view addSubview:self.cameraOnButton];
        [self.cameraOnButton setImage:[self imageNamed:@"video"] forState:UIControlStateNormal];
        [self.cameraOnButton addTarget:self action:@selector(cameraOnOff) forControlEvents:UIControlEventTouchUpInside];
    
        self.viewArray = @[self.micButton,self.cameraOnButton,  self.endCallButton, self.moreButton];
    
        
        [self.viewArray mas_distributeViewsAlongAxis:MASAxisTypeHorizontal withFixedItemLength:64 leadSpacing:24 tailSpacing:24];
        [self.viewArray mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.view.mas_bottom).inset(32);
            make.height.equalTo(@(64));
        }];
    }
   
}



- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    __weak typeof(self) weakSelf = self;

    // If current call state is already OMICallStateConfirmed, try to start preview videos.
    // observe Call state change notification

}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/// Call state change notification.
/// Ex: User 1 call User 2.
/// User 1 show this view controller before the call established. So observe this notification to start preview video at right time.
/// - Parameter notification: notification
- (void)callStateChanged: (NSNotification *)notification {
    __weak  OMICall *call = [[notification userInfo] objectForKey:OMINotificationUserInfoCallKey];
    if (call && call.callState == OMICallStateConfirmed && call.isVideo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateScreenUIForVideoCall];
        });
    } else if(call && call.callState == OMICallStateDisconnected) {
        dispatch_async(dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:nil];
        });
    }
}

/// Call End Notification. Need to dismiss self.
/// - Parameter notification: Call End Notification
- (void)callDealloc: (NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)startPreview {
    __weak typeof(self) weakSelf = self;
    if(!_remoteVideoRenderView || !_localVideoRenderView) return;
    
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.remoteVideoRenderView.contentMode = UIViewContentModeScaleAspectFill;
            [weakSelf.remoteVideoRenderView setView:[self.videoManager createViewForVideoRemote:weakSelf.remoteVideoRenderView.frame]];
            weakSelf.localVideoRenderView.contentMode = UIViewContentModeScaleAspectFill;
            [weakSelf.localVideoRenderView setView:[self.videoManager createViewForVideoLocal:weakSelf.localVideoRenderView.frame]];
        });
}

- (void)back {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)switchCamera {
    [self.videoManager switchCamera];
}

- (void)cameraOnOff {
    [self.videoManager toggleCamera];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.cameraOnButton setImage:[weakSelf imageNamed:weakSelf.videoManager.isCameraOn ? @"video" : @"video-off"] forState:UIControlStateNormal];
    });
}

- (void)micOnOff {
    
    __weak OMICall * call = [OMISIPLib.sharedInstance getCurrentConfirmCall];
    if(call){
        [call toggleMute:NULL];
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL muted = [OMISIPLib.sharedInstance getCurrentConfirmCall] .muted;
            [weakSelf.micButton setImage:[weakSelf imageNamed:muted ? @"mic-off" : @"mic"] forState:UIControlStateNormal];
        });
    }
  
}

- (void)hangup {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[[OMISIPLib sharedInstance] callManager] endActiveCall];

    });
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (void)more {
    __weak typeof(self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Change Audio Devices" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *inputAction = [UIAlertAction actionWithTitle:@"Input Devices" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf chooseAudioInputs];
    }];
    [alertController addAction:inputAction];
    UIAlertAction *outputAction = [UIAlertAction actionWithTitle:@"Output Devices" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf chooseAudioOutputs];
    }];
    [alertController addAction:outputAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:cancelAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)chooseAudioInputs {
    NSArray<AVAudioSessionPortDescription *> *inputs = AVAudioSession.sharedInstance.availableInputs;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Available Audio Inputs" message:@"Select one" preferredStyle:UIAlertControllerStyleActionSheet];
    
    for (AVAudioSessionPortDescription *description in inputs) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:description.portName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [AVAudioSession.sharedInstance setPreferredInput:description error:NULL];
        }];
        [alertController addAction:action];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)chooseAudioOutputs {
    NSArray<AVAudioSessionPortDescription *> *outputs = AVAudioSession.sharedInstance.currentRoute.outputs;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Available Audio Outputs" message:@"Select one" preferredStyle:UIAlertControllerStyleActionSheet];
    
    BOOL hasSpeaker = NO;
        
    for (AVAudioSessionPortDescription *description in outputs) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:description.portName style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [AVAudioSession.sharedInstance setPreferredInput:description error:NULL];
        }];
        [alertController addAction:action];
        
        if ([description.portType isEqualToString: AVAudioSessionPortBuiltInSpeaker]) {
            hasSpeaker = YES;
        }
    }
    
    if (!hasSpeaker) {
        UIAlertAction *speakerAction = [UIAlertAction actionWithTitle:@"Speaker" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [AVAudioSession.sharedInstance overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:NULL];
        }];
        [alertController addAction:speakerAction];
    }
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (UIImage *)imageNamed: (NSString *)name {
    UIImage *image = [UIImage imageNamed:name];
    if (image) {
        return image;
    }
    
    Class defaultClass = SampleVideoCallViewController.class;
    NSBundle *bundle = [NSBundle bundleForClass:defaultClass];
    image = [UIImage imageNamed:name inBundle:bundle compatibleWithTraitCollection:nil];
    if (image) {
        return image;
    }
    
    NSURL *subBundleUrl = [bundle URLForResource:@"OmiKit" withExtension:@"bundle"];
    NSBundle *subBundle = [NSBundle bundleWithURL:subBundleUrl];
    image = [UIImage imageNamed:name inBundle:subBundle compatibleWithTraitCollection:nil];
    if (image) {
        return image;
    }
    
    return nil;
}

@end
