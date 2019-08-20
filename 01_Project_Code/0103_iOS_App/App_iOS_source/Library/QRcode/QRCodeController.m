//
//  QRCodeController.m
//  eCarry
//  依赖于AVFoundation
//  Created by whde on 15/8/14.
//  Copyright (c) 2015年 Joybon. All rights reserved.
//

#import "QRCodeController.h"
#import <AVFoundation/AVFoundation.h>
#import "GosCommon.h"

@interface QRCodeController ()<AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate>
{
    AVCaptureSession * session;//输入输出的中间桥梁
    int line_tag;
    UIView *highlightView;
}
@end

@implementation QRCodeController

/**
 *  @author Whde
 *
 *  viewDidLoad
 */
- (void)viewDidLoad {
    [super viewDidLoad];
    [self instanceDevice];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] init];
}

/**
 *  @author Whde
 *
 *  配置相机属性
 */
- (void)instanceDevice{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    line_tag = 1872637;
    //获取摄像设备
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    //创建输出流
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    //初始化链接对象
    session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [session setSessionPreset:AVCaptureSessionPresetHigh];
    if (input) {
        [session addInput:input];
    }
    if (output) {
        [session addOutput:output];
        //设置扫码支持的编码格式(如下设置条形码和二维码兼容)
        NSMutableArray *a = [[NSMutableArray alloc] init];
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
            [a addObject:AVMetadataObjectTypeQRCode];
        }
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN13Code]) {
            [a addObject:AVMetadataObjectTypeEAN13Code];
        }
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeEAN8Code]) {
            [a addObject:AVMetadataObjectTypeEAN8Code];
        }
        if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeCode128Code]) {
            [a addObject:AVMetadataObjectTypeCode128Code];
        }
        output.metadataObjectTypes=a;
    }
    AVCaptureVideoPreviewLayer * layer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    layer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    layer.frame=self.view.layer.bounds;
    [self.view.layer insertSublayer:layer atIndex:0];
    
    [self setOverlayPickerView];
    
    [session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:nil];
    
    //开始捕获
    [session startRunning];
}

/**
 *  @author Whde
 *
 *  监听扫码状态-修改扫描动画
 *
 *  @param keyPath
 *  @param object
 *  @param change
 *  @param context
 */
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context{
    if ([object isKindOfClass:[AVCaptureSession class]]) {
        BOOL isRunning = ((AVCaptureSession *)object).isRunning;
        if (isRunning) {
            [self addAnimation];
        }else{
            [self removeAnimation];
        }
    }
}

/**
 *  @author Whde
 *
 *  获取扫码结果
 *
 *  @param captureOutput
 *  @param metadataObjects
 *  @param connection
 */
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count>0) {
        [session stopRunning];
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex :0];
        
        //输出扫描字符串
        NSString *data = metadataObject.stringValue;
        if (_didReceiveBlock) {
            _didReceiveBlock(data);
            [self selfRemoveFromSuperview];
        } else {
            if (IS_VAILABLE_IOS8) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Scan QRCode", nil) message:data preferredStyle:UIAlertControllerStyleAlert];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"HAO", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    [session startRunning];
                }]];
                [alertController show];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Scan QRCode", nil) message:data delegate:self cancelButtonTitle:NSLocalizedString(@"HAO", nil) otherButtonTitles:nil];
                [alert show];
            }
        }
    }
}

/**
 *  @author Whde
 *
 *  未识别(其他)的二维码提示点击"好",继续扫码
 *
 *  @param alertView
 */
- (void)alertViewCancel:(UIAlertView *)alertView {
    [session startRunning];
}

/**
 *  @author Whde
 *
 *  didReceiveMemoryWarning
 */
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

/**
 *  @author Whde
 *
 *  创建扫码页面
 */
- (UIView *)innerView {
    UIView *ret = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 220, 296)];

    UIImageView *scanView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, ret.frame.size.width, 220)];
    scanView.image = [UIImage imageNamed:@"qrcode_scan_frame.png"];
    //设置始终根据tintColor绘制图片颜色
    scanView.image = [scanView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    scanView.contentMode = UIViewContentModeScaleAspectFit;
    scanView.backgroundColor = [UIColor clearColor];
    scanView.tintColor = common.backgroundColor;
    [ret addSubview:scanView];

    UILabel *msg = [[UILabel alloc] initWithFrame:CGRectMake(0, 241, ret.frame.size.width, 20)];
    msg.backgroundColor = [UIColor clearColor];
    msg.textColor = [UIColor whiteColor];
    msg.textAlignment = NSTextAlignmentCenter;
    msg.font = [UIFont systemFontOfSize:12];
    msg.text = NSLocalizedString(@"Put the QR Code into the frame", nil);
    [ret addSubview:msg];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 261, ret.frame.size.width, 20)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor colorWithRed:0.996 green:0.816 blue:0.184 alpha:1];
//    label.textColor = common.backgroundColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:12];
    label.text = NSLocalizedString(@"Scanning code, binding device", nil);
    [ret addSubview:label];

    return ret;
}

- (void)setOverlayPickerView
{
    UIView *innerView = [self innerView];
    CGRect frame = innerView.frame;
    frame.origin.x = (self.view.frame.size.width-frame.size.width)/2;
    frame.origin.y = (self.view.frame.size.height-frame.size.height)/2;
    innerView.frame = frame;

    //左侧的view
    UIImageView *leftView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.origin.x, self.view.frame.size.height)];
    leftView.alpha = 0.5;
    leftView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:leftView];
    //右侧的view
    UIImageView *rightView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width-frame.origin.x, 0, frame.origin.x, self.view.frame.size.height)];
    rightView.alpha = 0.5;
    rightView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:rightView];
    
    //最上部view
    UIImageView* upView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.origin.x, 0, self.view.frame.size.width-frame.origin.x*2, frame.origin.y)];
    upView.alpha = 0.5;
    upView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:upView];

    //底部view
    UIImageView * downView = [[UIImageView alloc] initWithFrame:CGRectMake(frame.origin.x, frame.origin.y+220, self.view.frame.size.width-frame.origin.x*2, frame.size.height-220+frame.origin.y)];
    downView.alpha = 0.5;
    downView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:downView];

    CGFloat lineX = (self.view.frame.size.width-220)/2;
    UIImage *lineImage = [UIImage imageNamed:@"qrcode_scan_line.png"];
    // 设置始终根据tintColor绘制图片颜色
    lineImage = [lineImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *line = [[UIImageView alloc] initWithImage:lineImage];
    line.frame = CGRectMake(lineX, CGRectGetMaxY(upView.frame), 220, 2);
    line.tag = line_tag;
    line.backgroundColor = [UIColor clearColor];
    line.tintColor = common.backgroundColor;
    [self.view addSubview:line];

    CGRect leftFrame;
    leftFrame = CGRectMake(10, 20, 24, 44);
    UIButton *leftButton= [UIButton buttonWithType:UIButtonTypeCustom];
    leftButton.frame =leftFrame;
    [leftButton addTarget:self action:@selector(dismissOverlayView:) forControlEvents:UIControlEventTouchUpInside];
    [leftButton setImage:[UIImage imageNamed:@"qrcode_back_button.png"] forState:UIControlStateNormal];
    [self.view addSubview:leftButton];
    [self.view addSubview:innerView];
}

/**
 *  @author Whde
 *
 *  添加扫码动画
 */
- (void)addAnimation{
    UIView *line = [self.view viewWithTag:line_tag];
    line.hidden = NO;
    CABasicAnimation *animation = [QRCodeController moveYTime:2 fromY:@0 toY:@219 rep:OPEN_MAX];
    [line.layer addAnimation:animation forKey:@"LineAnimation"];
}

+ (CABasicAnimation *)moveYTime:(float)time fromY:(NSNumber *)fromY toY:(NSNumber *)toY rep:(int)rep
{
    CABasicAnimation *animationMove = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    [animationMove setFromValue:fromY];
    [animationMove setToValue:toY];
    animationMove.duration = time;
    animationMove.repeatCount  = rep;
    animationMove.fillMode = kCAFillModeForwards;
    animationMove.removedOnCompletion = NO;
    animationMove.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return animationMove;
}


/**
 *  @author Whde
 *
 *  去除扫码动画
 */
- (void)removeAnimation{
    UIView *line = [self.view viewWithTag:line_tag];
    [line.layer removeAnimationForKey:@"LineAnimation"];
    line.hidden = YES;
}

/**
 *  @author Whde
 *
 *  扫码取消button方法
 *
 *  @return
 */
- (void)dismissOverlayView:(id)sender{
    [self selfRemoveFromSuperview];
}

/**
 *  @author Whde
 *
 *  从父视图中移出
 */
- (void)selfRemoveFromSuperview{
    [session removeObserver:self forKeyPath:@"running" context:nil];
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }];
    [[UIApplication sharedApplication] setStatusBarStyle:common.statusBarStyle animated:YES];
    if (_didCancelBlock) {
        _didCancelBlock();
    }
}

/*!
 *  <#Description#>
 *  @param didCancelBlock <#didReceiveBlock description#>
 */
- (void)setDidCancelBlock:(QRCodeDidCancelBlock)didCancelBlock {
    _didCancelBlock = [didCancelBlock copy];
}

/*!
 *  <#Description#>
 *  @param didReceiveBlock <#didReceiveBlock description#>
 */
- (void)setDidReceiveBlock:(QRCodeDidReceiveBlock)didReceiveBlock {
    _didReceiveBlock = [didReceiveBlock copy];
}

@end
