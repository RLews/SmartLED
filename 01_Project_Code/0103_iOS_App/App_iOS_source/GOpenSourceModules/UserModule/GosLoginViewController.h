//
//  LoginViewController.h
//  GBOSA
//
//  Created by Zono on 16/3/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GosCommon.h"
#import "GosDeviceListViewController.h"

@interface GosLoginViewController : UIViewController <GizWifiSDKDelegate, UITextFieldDelegate>

- (void)autoLogin;

@end
