//
//  AppDelegate.m
//  GBOSA
//
//  Created by Zono on 16/3/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "AppDelegate.h"
#import "GizLog.h"

#import <GizWifiSDK/GizWifiSDK.h>
#import "GosCommon.h"
#import "GosLoginViewController.h"

#import "GosPushManager.h"

#import <TencentOpenAPI/TencentOAuth.h>
#import "WXApi.h"
#import "GosDeviceViewController.h"


@interface AppDelegate () <GizWifiSDKDelegate, WXApiDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSDate *date = [NSDate date];
    [GosCommon appLogInit:2];
    [GosCommon sharedInstance].controlHandler = ^(GizWifiDevice *device, UIViewController *deviceListController) {
        UIViewController *lastCtrl = deviceListController.navigationController.viewControllers.lastObject;
        if (lastCtrl == deviceListController || lastCtrl == deviceListController.tabBarController) {
            UINavigationController *navigationController = nil;
            if (deviceListController.tabBarController) { //注意导航和标签控制器嵌套的关系
                navigationController = deviceListController.tabBarController.navigationController;
            } else {
                navigationController = deviceListController.navigationController;
            }
            if (navigationController.viewControllers.lastObject != deviceListController.tabBarController &&
                navigationController.viewControllers.lastObject != deviceListController) {
                return;
            }
            if([deviceListController isKindOfClass:[GosDeviceListViewController class]]) {
                GosDeviceListViewController *deviceListVC = (GosDeviceListViewController *)deviceListController;
                // 增加控制界面代码
                                GosDeviceViewController *deviceVC = [[GosDeviceViewController alloc] initWithDevice:device];
                                [deviceListVC safePushViewController:deviceVC];
            }
        }
    };
    
    if ([APP_ID isEqualToString:@"your_app_id"] || APP_ID.length == 0 || [APP_SECRET isEqualToString:@"your_app_secret"] || APP_SECRET.length == 0) {
        [GosCommon showAlert:nil message:@"请替换 GOpenSourceModules/CommonModule/appConfig.json 中的参数定义为您申请到的机智云 app id、app secret、product key 等"];
    } else { // 初始化 推送服务
        
        [GosPushManager initManager:launchOptions];
        
        if (PUSH_TYPE != -1 || common.isSoftAP) { // ios8 注册推送通知，覆盖本地、远程通知
            UIUserNotificationType type = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
            UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type categories:nil];
            [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        }
        // 初始化 GizWifiSDK
        GosWifiSDKMessageCenter.delegate = self;
        //        [GizWifiSDK setLogLevel:GizLogPrintNone];
        [GizWifiSDK setLogLevel:GizLogPrintAll];
        [common setApplicationInfo:[common getApplicationInfo]];
    }
    
    [[UINavigationBar appearance] setBackgroundColor:common.backgroundColor];
    [UINavigationBar appearance].barStyle = (UIBarStyle)common.statusBarStyle;
    [[UINavigationBar appearance] setBarTintColor:common.backgroundColor];
    [[UINavigationBar appearance] setTintColor:common.contrastColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:common.contrastColor}];
    
    //加载主页
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"GosUser" bundle:nil];
    UINavigationController *newViewController = [storyboard instantiateInitialViewController];
    newViewController.view.alpha = 0;
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = newViewController;
    [self.window makeKeyAndVisible];
    
    uint32_t timeRemaining = (0.5-[date timeIntervalSinceNow])*1000000; //加一点延迟，使得总耗时为0.5秒
    if (timeRemaining > 0) {
        usleep(timeRemaining);
    }
    return YES;
}

- (void)showMainPage {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationsEnabled:YES];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
        self.window.rootViewController.view.alpha = 1;
        [UIView commitAnimations];
        
        // 自动登录逻辑，在个人中心退回不应该触发此逻辑
        UINavigationController *navCtrl = (UINavigationController *)self.window.rootViewController;
        GosLoginViewController *loginCtrl = navCtrl.viewControllers.firstObject;
        GosWifiSDKMessageCenter.delegate = loginCtrl;
        
        if (!loginCtrl.presentedViewController) {
            [loginCtrl autoLogin];
        }
    });
}

- (void)wifiSDK:(GizWifiSDK *)wifiSDK didNotifyEvent:(GizEventType)eventType eventSource:(id)eventSource eventID:(GizWifiErrorCode)eventID eventMessage:(NSString*)eventMessage {
    GIZ_LOG_DEBUG("eventID: %zi, eventMessage: %s", eventID, eventMessage.description.UTF8String);
    
    if (eventType == GizEventSDK) {
        GosWifiSDKMessageCenter.delegate = nil; //清理代理
        if (eventID == GIZ_SDK_START_SUCCESS) { // GizWifiSDK已启动
            [GizWifiSDK getCurrentCloudService]; //获取SDK当前连接的服务器
        } else {
            [GosCommon showAlertAutoDisappear:[common checkErrorCode:eventID]];
        }
        [self showMainPage];
    }
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    GIZ_LOG_BIZ("switch_wifi_notify_click", "success", "wifi switch success notify is clicked");
}

//- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
//}
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options {
    
    if (common.isQQ) {
        if ([[url absoluteString] hasPrefix:@"tencent"]) {
            return [TencentOAuth HandleOpenURL:url];
        }
    }
    
    
    if (common.isWechat) {
        if ([[url absoluteString] hasPrefix:WECHAT_APP_ID]) {
            return [WXApi handleOpenURL:url delegate:self];
        }
    }
    
    return NO;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
    if (common.isQQ) {
        if ([[url absoluteString] hasPrefix:@"tencent"]) {
            return [TencentOAuth HandleOpenURL:url];
        }
    }
    
    
    if (common.isWechat) {
        if ([[url absoluteString] hasPrefix:WECHAT_APP_ID]) {
            return [WXApi handleOpenURL:url delegate:self];
        }
    }
    
    return NO;
}

#pragma mark - WXApiDelegate
- (void)onResp:(BaseResp *)resp {
    common.WXApiOnRespHandler(resp);
}

- (void)onReq:(BaseReq *)req {
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    // Required,For systems with less than or equal to iOS6
    
    [GosPushManager handleRemoteNotification:userInfo];
    
    // 取得 APNs 标准信息内容
    NSDictionary *aps = [userInfo valueForKey:@"aps"];
    NSString *content = [aps valueForKey:@"alert"];
    NSString *title = [userInfo valueForKey:@"title"];
    [GosCommon showAlert:title message:content];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    
    // IOS 7 Support Required
    [self application:application didReceiveRemoteNotification:userInfo];
    completionHandler(UIBackgroundFetchResultNewData);
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [GosPushManager didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    _isBackground = YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    _isBackground = NO;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
