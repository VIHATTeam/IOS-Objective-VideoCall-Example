//
//  ViewController.m
//  OmiSDKExample
//
//  Created by QUOC VIET  on 14/02/2023.
//

#import "ViewController.h"
#import <OmiKit/OmiClient.h>
#import <OmiKit/OMIVideoCallViewController.h>
#import <OmiKit/OMIVideoViewManager.h>
#import <OmiKit/OMIVideoPreviewView.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *myNumberLabel;
@property (weak, nonatomic) IBOutlet UITextField *callPhoneNumberTextField;
@property (weak, nonatomic) IBOutlet OMIVideoPreviewView *remotePreviewView;
@property (weak, nonatomic) IBOutlet OMIVideoPreviewView *localPreviewView;

@property (nonatomic, strong) OMIVideoViewManager *videoManager;

@end

@implementation ViewController
NSString * USER_NAME1 = @"100";
NSString * PASS_WORD1 = @"Kunkun";
NSString * USER_NAME2 = @"101";
NSString * PASS_WORD2 = @"Kunkun12345";

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}


- (IBAction)makeCall:(UIButton *)sender {
    [OmiClient startVideoCall:self.callPhoneNumberTextField.text];

    OMIVideoCallViewController *viewController = [[OMIVideoCallViewController alloc] init];
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:viewController animated:YES completion:^{
//        [OmiClient startCall:self.callPhoneNumberTextField.text];
    }];
}

- (IBAction)EndCall:(id)sender {
    OMICall *call = [OmiClient getFirstActiveCall];
    [[[OMISIPLib sharedInstance] callManager] endAllCalls];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callStateChanged:) name:OMICallStateChangedNotification object:nil];
    
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)callStateChanged: (NSNotification *)notification {
    
    __weak typeof(self)weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        OMICall *call = [OmiClient getFirstActiveCall];
        NSLog(@"viewcontroller ===>>> %ld", call.callState);
        if (call.callState == OMICallStateConfirmed && !self.presentedViewController) {
        
            OMIVideoCallViewController *viewController = [[OMIVideoCallViewController alloc] init];
            viewController.modalPresentationStyle = UIModalPresentationFullScreen;
            [weakSelf presentViewController:viewController animated:YES completion:^{
        //        [OmiClient startCall:self.callPhoneNumberTextField.text];
            }];
        }
    });
}



- (IBAction)login100:(id)sender {

    [OmiClient initWithUsername:USER_NAME1 password:PASS_WORD1 realm:@"dky"];
    [OmiClient startOmiService:true];// true if call video
    [OmiClient registerAccount];
    self.myNumberLabel.text = [NSString stringWithFormat:@"My number:%@", USER_NAME1];
    self.callPhoneNumberTextField.text = USER_NAME2;
    self.videoManager = [[OMIVideoViewManager alloc] init];

}

- (IBAction)login101:(id)sender {

    [OmiClient initWithUsername:USER_NAME2 password:PASS_WORD2 realm:@"dky"];
    [OmiClient startOmiService:true];// true if call video
    [OmiClient registerAccount];

    self.myNumberLabel.text = [NSString stringWithFormat:@"My number:%@", USER_NAME2];
    self.callPhoneNumberTextField.text = USER_NAME1;
    self.videoManager = [[OMIVideoViewManager alloc] init];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (IBAction)toggleMic:(UIButton *)sender {
    OMICall *call = [OmiClient getFirstActiveCall];
    if (call) {
        [call toggleMute:NULL];
    }
    
//    BOOL isMicMuted = VialerSIPLib.sharedInstance.callManager.audioController.isMicMuted;
//    NSLog(@"%d", isMicMuted);
}

- (IBAction)toggleCamera:(UIButton *)sender {
    [self.videoManager toggleCamera];
}

- (IBAction)switchCamera:(UIButton *)sender {
    [self.videoManager switchCamera];
}

- (IBAction)preview:(UIButton *)sender {
    __weak typeof(self) weakSelf = self;
    
    [self.videoManager localView:^(UIView *view) {
        dispatch_async(dispatch_get_main_queue(), ^{
            view.contentMode = UIViewContentModeScaleAspectFill;
            [weakSelf.localPreviewView setView:view];
        });
    }];
    
    [self.videoManager remoteView:^(UIView *view) {
        dispatch_async(dispatch_get_main_queue(), ^{
            view.contentMode = UIViewContentModeScaleAspectFill;
            [weakSelf.remotePreviewView setView:view];
        });
    }];
}

- (IBAction)chooseAudioInputs:(UIButton *)sender {
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

- (IBAction)chooseAudioOutputs:(UIButton *)sender {
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


@end
