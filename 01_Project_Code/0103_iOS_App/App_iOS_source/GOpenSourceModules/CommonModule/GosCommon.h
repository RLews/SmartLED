//
//  Common.h
//  GBOSA
//
//  Created by Zono on 16/4/11.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIImageView+PlayGIF.h"
#import "MBProgressHUD.h"
#import "GizLog.h"
#import "WXApi.h"
#import "GizKeychainRecorder.h"
#import "GosWifiSDKMessageCenter.h"
#import <TargetConditionals.h>

#define common [GosCommon sharedInstance]
#define IS_VAILABLE_IOS9  ([[[UIDevice currentDevice] systemVersion] intValue] >= 9)

#if TARGET_OS_SIMULATOR
#define SSID_PREFIX     @""
#else
#define SSID_PREFIX     @"XPG-GAgent"
#endif

#ifndef XcodeAppBundle
#define XcodeAppBundle  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"]
#endif

#ifndef XcodeAppVersion
#define XcodeAppVersion [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]
#endif

//UIAlertController+window
@interface UIAlertController (GosCommon)

@property (strong, nonatomic) UIWindow *alertWindow;
@property (strong, nonatomic, readonly) UILabel *detailTextLabel;

- (void)show;

@end

//NSDictionary+parser
@interface NSDictionary (GosCommon)

- (NSString *)stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue;
- (NSNumber *)numberValueForKey:(NSString *)key defaultValue:(NSNumber *)defaultValue;
- (NSInteger)integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;
- (BOOL)boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (double)doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue;
- (NSArray *)arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue;
- (NSDictionary *)dictValueForKey:(NSString *)key defaultValue:(NSDictionary *)defaultValue;

@end


/**
 登录类型类型
 */
typedef NS_ENUM(NSInteger, GizLoginStatus) {
    /**
     未登录
     */
    GizLoginNone = 0,
    
    /**
     用户登录
     */
    GizLoginUser = 1,
};

/**
 绑定类型
 */
typedef NS_ENUM(NSInteger, GizSetDeviceOnboardingType) {
    /**
     使用setDeviceOnboarding:接口配网
     */
    GizSetDeviceOnboarding = 0,
    
    /**
     使用setDeviceOnboardingByBind接口配网
     */
    GizSetDeviceOnboardingByBind = 1,
    
    /**
     使用setDeviceOnboardingDeploy接口配网并自动绑定
     */
    GizSetDeviceOnboardingDeployBind = 2,
    
    /**
     使用setDeviceOnboardingDeploy接口配网不自动绑定
     */
    GizSetDeviceOnboardingDeployUnbind = 3,
};

/**
 登陆类型
 */
typedef NS_ENUM(NSInteger, GizLoginType) {
    /**
     未知登陆类型的情况
     */
    GizUnknowLogin = -1,
    
    /**
     没有用户登陆的情况
     */
    GizUnUserLogin = 0,
    
    /**
     匿名登录
     */
    GizAnonymousLogin = 1,
    
    /**
     用户名和密码的方式登陆,包括手机号码，邮箱登陆
     */
    GizUserNameLogin = 2,
    
    /**
     QQ授权登陆
     */
    GizQQLogin = 3,
    
    /**
     微信授权登陆
     */
    GizWechatLogin = 4,
    
    /**
     Twitter授权登陆
     */
    GizTwitterLogin = 5,
    
    /**
     Facebook授权登陆
     */
    GizFacebookLogin = 6,
};

@class GizWifiDevice;

typedef void (^GosRecordPageBlock)(UIViewController *viewController);
typedef void (^GosSettingPageBlock)(UIViewController *viewController);

typedef void (^WXApiOnRespBlock)(BaseResp *resp);
typedef void (^GosControlBlock)(GizWifiDevice *device, UIViewController *viewController);

@interface GosCommon : NSObject

+ (instancetype)sharedInstance;

- (void)saveUserDefaults:(GizLoginType)loginType userName:(NSString *)username password:(NSString *)password tokenSecret:(NSString *)tokenSecret uid:(NSString *)uid token:(NSString *)token;
- (void)removeUserDefaults;
- (void)removeUserValues;

@property (strong) NSString *ssid;

@property (assign) id delegate;

@property (strong, readonly) NSString *tmpUser;
@property (strong, readonly) NSString *tmpPass;
@property (strong) NSString *uid;
@property (strong) NSString *token;
@property (assign) GizLoginStatus currentLoginStatus;
@property (assign) BOOL isThirdAccount;
@property (strong) GosRecordPageBlock recordPageHandler; //自定义页面统计
@property (strong) GosControlBlock controlHandler; //自定义控制页面
@property (strong) GosSettingPageBlock settingPageHandler; //自定义设置页面

@property (strong) WXApiOnRespBlock WXApiOnRespHandler;

@property (strong, nonatomic) NSArray *lastConfigType; //上次配置过的类型索引号

@property (strong) NSArray <GizMessage *>*sharingMessageList; //分享消息列表

@property (nonatomic, strong) UIAlertView *cancelAlertView;

@property (nonatomic, strong) NSString *cid;
/********************* 初始化参数 appInfo *********************/
@property (strong, nonatomic, readonly) NSDictionary *cloudDomainDict;
@property (strong, nonatomic, readonly) NSString *appID;
@property (strong, nonatomic, readonly) NSString *appSecret;
@property (strong, nonatomic, readonly) NSArray *productInfo;
@property (strong, nonatomic, readonly) NSString *tencentAppID;
@property (strong, nonatomic, readonly) NSString *wechatAppID;
@property (strong, nonatomic, readonly) NSString *wechatAppSecret;
@property (strong, nonatomic, readonly) NSString *jpushAppKey;
@property (strong, nonatomic, readonly) NSString *bpushAppKey;
@property (strong, nonatomic, readonly) NSString *umAppKey;
@property (strong, nonatomic, readonly) NSString *umMessageKey;
@property (strong, nonatomic, readonly) NSString *facebookAppID;
@property (strong, nonatomic, readonly) NSString *twitterAppID;
@property (strong, nonatomic, readonly) NSString *twitterAppSecret;

/********************* 初始化参数 supportModule *********************/
@property (assign, nonatomic, readonly) BOOL isDeviceGlobalDeployment;
@property (assign, nonatomic, readonly) BOOL isSetDeploymentDomain;
@property (assign, nonatomic, readonly) BOOL isDeviceOTA;
@property (assign, nonatomic, readonly) BOOL isSoftAP;
@property (assign, nonatomic, readonly) BOOL isAirlink;
@property (assign, nonatomic, readonly) BOOL isAutoSubscribeDevice;
@property (assign, nonatomic, readonly) BOOL isAnonymous;
@property (assign, nonatomic, readonly) BOOL isDisplayMac;
@property (assign, nonatomic, readonly) BOOL isQQ;
@property (assign, nonatomic, readonly) BOOL isWechat;
@property (assign, nonatomic, readonly) BOOL isTwitter;
@property (assign, nonatomic, readonly) BOOL isFacebook;
@property (assign, nonatomic, readonly) BOOL isRegisterNormalUser;
@property (assign, nonatomic, readonly) BOOL isRegisterPhoneUser;
@property (assign, nonatomic, readonly) BOOL isRegisterEmailUser;
@property (assign, nonatomic, readonly) BOOL isForgetPhoneUser;
@property (assign, nonatomic, readonly) BOOL isForgetEmailUser;
@property (assign, nonatomic, readonly) BOOL isChangePassword;
@property (assign, nonatomic, readonly) BOOL isMessageCenter;
@property (assign, nonatomic, readonly) BOOL isNormalDeviceQRCodeScan;
@property (assign, nonatomic, readonly) BOOL isDeviceSharingQRCode;
@property (assign, nonatomic, readonly) BOOL isDeviceSharingSupport;
@property (assign, nonatomic, readonly) BOOL isUmengSuport;
@property (assign, nonatomic, readonly) BOOL isWiFiModuleMall;
@property (assign, nonatomic, readonly) BOOL isFeedbackSupport;
@property (assign, nonatomic, readonly) BOOL isDisableLAN;
@property (assign, nonatomic, readonly) BOOL isPowerSavingSupport;
@property (assign, nonatomic, readonly) BOOL isAddDeviceByQRCode;
@property (assign, nonatomic, readonly) BOOL isGatewaySupport;
@property (assign, nonatomic, readonly) BOOL isShowGatewayDataPoint;
@property (assign, nonatomic, readonly) NSInteger pushType;

/********************* 初始化参数 configUI *********************/
@property (assign, nonatomic, readonly) BOOL isUsingUnbindButton;
@property (strong, nonatomic, readonly) NSArray *wifiModuleTypes;
@property (assign, nonatomic, readonly) GizSetDeviceOnboardingType onboardingType;
@property (strong, nonatomic, readonly) UIColor *backgroundColor;
@property (strong, nonatomic, readonly) UIColor *contrastColor;
@property (assign, nonatomic, readonly) UIStatusBarStyle statusBarStyle;
@property (strong, nonatomic, readonly) NSString *aboutInfo;
@property (strong, nonatomic, readonly) NSDictionary *productLightDict;
@property (strong, nonatomic, readonly) NSArray *deviceInfo;

/********************* 中控参数 *********************/
@property (assign, nonatomic, readonly) BOOL isGroupModule;
@property (assign, nonatomic, readonly) BOOL isSceneModule;
@property (assign, nonatomic, readonly) BOOL isSchedulerModule;
@property (assign, nonatomic, readonly) BOOL isJointActionModule;
@property (assign, nonatomic, readonly) BOOL isSpecialBundleID;
@property (strong, nonatomic, readonly) NSArray *usingPowerOnShortcutButton;
@property (strong, nonatomic, readonly) NSDictionary *dataPointNameDict;

+ (NSString *)dataPointFromProductKey:(NSString *)productKey;

/******************** 语言 ***************************/
@property (class, nonatomic, assign, readonly) BOOL isChinese;

//中能定制
@property (assign, nonatomic) GizDeviceSharingUserRole role; //用户角色
//标识SDK当前连接的服务器域名 NO:国内服务器  YES：国外服务器
@property (nonatomic, assign) BOOL unChineseServer;

#define BUTTON_TEXT_COLOR [UIColor colorWithRed:0.322 green:0.244 blue:0.747 alpha:1]

/*
 * ssid 缓存
 */
- (void)saveSSID:(NSString *)ssid key:(NSString *)key;
- (NSString *)getPasswrodFromSSID:(NSString *)ssid;

/**
 * appID、appSecret、域名、端口
 * @note {"APPID": xxx, "APPSECRET": xxx, "cloudServiceInfo": {"siteInfo": xxx, "openAPIInfo": xxx}, "productInfo": xxx}
 */
- (BOOL)setApplicationInfo:(NSDictionary *)info;
- (NSDictionary *)getApplicationInfo;
- (NSString *)getAppSecret;

/*
 * 判断错误码
 */
- (NSString *)checkErrorCode:(GizWifiErrorCode)errorCode;

/*
 * UIAlertController
 */
+ (UIAlertController *)showAlertWithTip:(NSString *)message;
+ (UIAlertController *)showAlert:(NSString *)title message:(NSString *)message;
+ (void)showAlertAutoDisappear:(NSString *)message;
+ (void)showAlertAutoDisappear:(NSString *)message completion:(void (^)(void))completion;
+ (void)showAlertConfigDiscard:(void (^)(UIAlertAction *action))handler;
+ (void)showAlertEmptyPassword:(void (^)(UIAlertAction *action))handler;
+ (void)enterProductSecret:(void (^)(NSString *text))handler controller:(UIViewController *)controller;

/*
 * MBProgressHUD
 */
+ (void)showHUDAddedTo:(UIView *)view animated:(BOOL)animated;
+ (void)showHUDAddedTo:(UIView *)view tips:(NSString *)tips tag:(NSInteger)tag animated:(BOOL)animated;
+ (void)showHUDWithImage:(UIImage *)image text:(NSString *)text;
+ (void)hideHUDForView:(UIView *)view tag:(NSInteger)tag;
+ (MBProgressHUD *)findHUDForView:(UIView *)view tag:(NSInteger)tag;

/*
 * 回到主页
 */
- (void)onCancel;
- (void)onSucceed:(GizWifiDevice *)device;
- (void)showAlertCancelConfig:(void (^)(UIAlertAction *action))handler;
- (void)cancelAlertViewDismiss;

/**
 格式：xxxx-xx-xxTxx:xx:xxZ
 */
+ (NSDate *)serviceDateFromString:(NSString *)dateStr;
+ (NSString *)localDateStringFromDate:(NSDate *)date;

@property (class, nonatomic, strong, readonly) NSURL *wifiURL;

/*
 * 导航
 */
+ (UIViewController *)firstViewControllerFromClass:(UINavigationController *)navCtrl class:(Class)cls;
+ (void)safePushViewController:(UINavigationController *)navCtrl viewController:(UIViewController *)controller animated:(BOOL)animated;
+ (void)safePopViewController:(UINavigationController *)navCtrl currentViewController:(UIViewController *)controller animated:(BOOL)animated;
+ (void)safePopToViewController:(UINavigationController *)navCtrl viewController:(UIViewController *)controller animated:(BOOL)animated;
+ (void)safePopToRootViewController:(UINavigationController *)navCtrl animated:(BOOL)animated;
+ (void)safePopToDeviceList:(UINavigationController *)navCtrl;

/*
 * 列表
 */
+ (CGFloat)tableHeaderHeight:(UITableView *)tableView text:(NSString *)text offset:(CGFloat)offset;
+ (UIView *)tableHeaderView:(UITableView *)tableView text:(NSString *)text offset:(CGFloat)offset;

/*
 * 场景预设项数据
 */
+ (NSArray *)sceneItemsWithDevice:(GizWifiCentralControlDevice *)centralDevice;
+ (void)setSceneItemsWithDevice:(GizWifiCentralControlDevice *)centralDevice sceneItems:(NSArray *)sceneItems;
+ (void)updateScenePresetInfo:(NSString *)oldSceneImage centralDevice:(GizWifiCentralControlDevice *)centralDevice newSceneName:(NSString *)newSceneName sceneList:(NSArray *)sceneList;

/*
 * 其他
 */
+ (NSString *)currentSSID;
+ (BOOL)appLogInit:(int)logLevel;

+ (id)controllerWithClass:(Class)cls tableView:(UITableView *)tableView reuseIdentifier:(NSString *)reuseIdentifier;
//增加消息分享cell右上角小圆点
+ (void)markTableViewCell:(UITableViewCell *)cell label:(UILabel *)label hasUnreadMessage:(BOOL)hasUnreadMessage;

+ (NSString *)productSecretFromDevice:(GizWifiDevice *)device;
+ (UIImage *)transparentImage:(CGSize)size;
+ (UIImage *)tabImage;
+ (NSString *)stringLimit:(NSString *)name;

+ (void)updateButtonStyle:(UIButton *)button; //倒圆角，加特定背景的按钮
+ (UIColor *)colorWithHexString:(NSString *)hexString; //#000000
+ (BOOL)canEnterProductSecret:(GizWifiDevice *)device;


/**
 根据JSON配置给定的产品数据点显示名称

 @param productKey 将显示设备的PK
 @param ui 将显示设备的数据点配置UI
 @return 返回设置成新数据点名称的UI
 */
- (NSDictionary *)getControlDeviceUI:(NSString *)productKey ui:(NSDictionary *)ui;

/**
 根据JSON配置显示设备名称

 @param device 将显示的设备
 @return 设备名称
 */
- (NSString *)deviceName:(GizWifiDevice *)device;

@end
