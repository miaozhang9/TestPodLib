//
//  BottomView.h
//  PAFacecheckController
//
//  Created by ken on 15/4/27.
//  Copyright (c) 2015年 PingAN. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OCFTFaceDetect/OCFTFaceDetector.h>

typedef NS_ENUM(NSInteger, animationState){
    animationOne,
    animationTwo,
    animationThree,
};

@interface PABottomView : UIView

- (void)willChangeAnimation:(OCFTFaceDetectActionType)state outTime:(CGFloat)time;
-(void)initWithTheCountDown:(BOOL)countDown andTheFaceConter:(BOOL)faceConter;
- (void)recovery;
- (void)showPromtpView;
- (void)closePromtpView;
- (void)startRollAnimation;
- (void)stopRollAnimation;
- (void)promptLabelText:(OCFTFaceDetectOptimizationType)promptLabelStr;
@end
