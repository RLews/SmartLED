//
//  Common.m
//  GBOSA
//
//  Created by Zono on 16/4/11.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosCommon.h"
#import "GosConfigStart.h"
#import <CommonCrypto/CommonCrypto.h>
#import "AppDelegate.h"
#import <GizWifiSDK/GizWifiSDK.h>
#import <objc/runtime.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <sys/sysctl.h>

static NSString *ssidCacheKey = @"ssidKeyValuePairs";
static NSString *encryptKey = @"com.gizwits.gizwifisdk.commondata";

#define DEFAULT_API_DOMAIN      @"api.gizwits.com"
#define DEFAULT_SITE_DOMAIN     @"site.gizwits.com"

@implementation UIAlertController (GosCommon)
    
    @dynamic alertWindow;
    
- (void)setAlertWindow:(UIWindow *)alertWindow {
    objc_setAssociatedObject(self, @selector(alertWindow), alertWindow, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
    
- (UIWindow *)alertWindow {
    return objc_getAssociatedObject(self, @selector(alertWindow));
}
    
- (void)show {
    self.alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.alertWindow.rootViewController = [[UIViewController alloc] init];
    self.alertWindow.windowLevel = [UIApplication sharedApplication].windows.lastObject.windowLevel+1;
    [self.alertWindow makeKeyAndVisible];
    [self.alertWindow.rootViewController presentViewController:self animated:YES completion:nil];
}
    
- (void)viewDidDisappear:(BOOL)animated { //弹框消失的事件处理
    [super viewDidDisappear:animated];
    self.alertWindow.hidden = YES;
    self.alertWindow = nil;
}
    
- (void)allLabels:(UIView *)view labels:(NSMutableArray *)labels { //获取弹框中所有的标签，用于修改对齐方式，或者其他
    for (UILabel *label in view.subviews) {
        if ([label isKindOfClass:[UILabel class]]) {
            [labels addObject:label];
        }
        [self allLabels:label labels:labels];
    }
}
    
- (UILabel *)detailTextLabel { //获取详细信息的标签
    NSMutableArray *labels = [NSMutableArray array];
    [self allLabels:self.view labels:labels];
    if (labels.count == 2) {
        return labels[1];
    }
    return nil;
}
    
    @end

#pragma mark - 字典解析的通用安全方法
static inline id gizGetObjectFromDict(NSDictionary *dict, Class class, NSString *key, id defaultValue) { //通用安全方法
    if (![key isKindOfClass:[NSString class]] || ![dict isKindOfClass:[NSDictionary class]]) {
        return defaultValue;
    }
    
    id obj = dict[key];
    if ([obj isKindOfClass:class]) {
        return obj;
    }
    return defaultValue;
}

@implementation NSDictionary (GosCommon) //字典安全取数据的扩展方法
    
- (NSString *)stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    return gizGetObjectFromDict(self, [NSString class], key, defaultValue);
}
    
- (NSNumber *)numberValueForKey:(NSString *)key defaultValue:(NSNumber *)defaultValue {
    return gizGetObjectFromDict(self, [NSNumber class], key, defaultValue);
}
    
- (NSInteger)integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue {
    NSNumber *number = gizGetObjectFromDict(self, [NSNumber class], key, @(defaultValue));
    return [number integerValue];
}
    
- (BOOL)boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    NSNumber *number = gizGetObjectFromDict(self, [NSNumber class], key, @(defaultValue));
    return [number boolValue];
}
    
- (double)doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue {
    NSNumber *number = gizGetObjectFromDict(self, [NSNumber class], key, @(defaultValue));
    return [number doubleValue];
}
    
- (NSArray *)arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue {
    return gizGetObjectFromDict(self, [NSArray class], key, defaultValue);
}
    
- (NSDictionary *)dictValueForKey:(NSString *)key defaultValue:(NSDictionary *)defaultValue {
    return gizGetObjectFromDict(self, [NSDictionary class], key, defaultValue);
}
    
    @end

static NSData *AES256EncryptWithKey(NSString *key, NSData *data) { //AES加密
    char keyPtr[kCCKeySizeAES256+1] = { 0 };
    if (![key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding]) {
        return nil;
    }
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    size_t numBytesEncrypted = 0;
    void *buffer = malloc(bufferSize);
    if (!buffer) {
        return nil;
    }
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256, NULL, [data bytes], dataLength,
                                          buffer, bufferSize, &numBytesEncrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
    }
    free(buffer);
    return nil;
}

static NSData *AES256DecryptWithKey(NSString *key, NSData *data) { //AES解密
    char keyPtr[kCCKeySizeAES256+1] = { 0 };
    if (![key getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding]) {
        return nil;
    }
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    size_t numBytesDecrypted = 0;
    void *buffer = malloc(bufferSize);
    if (!buffer) {
        return nil;
    }
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding,
                                          keyPtr, kCCKeySizeAES256, NULL, [data bytes], dataLength,
                                          buffer, bufferSize, &numBytesDecrypted);
    if (cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}

static NSString *makeEncryptKey(Class class, NSString *ssid) { //生成MD5作为AES加密密码
    NSString *tmpEncryptKey = NSStringFromClass(class);
    tmpEncryptKey = [tmpEncryptKey stringByAppendingString:@"_"];
    tmpEncryptKey = [tmpEncryptKey stringByAppendingString:ssid];
    tmpEncryptKey = [tmpEncryptKey stringByAppendingString:@"_"];
    
    unsigned char result[16] = { 0 };
    CC_MD5(tmpEncryptKey.UTF8String, (CC_LONG)tmpEncryptKey.length, result);
    NSString *ret = @"";
    
    for (int i=0; i<16; i++) {
        ret = [ret stringByAppendingFormat:@"%02X", result[i]];
    }
    
    return ret;
}

static NSMutableDictionary *ssidKeyPairs() { //获取ssid缓存信息
    id obj = [[NSUserDefaults standardUserDefaults] valueForKey:ssidCacheKey];
    if (![obj isKindOfClass:[NSDictionary class]]) {
        return [NSMutableDictionary dictionary];
    }
    return [obj mutableCopy];
}

static void setSsidKeyPairs(NSDictionary *dict) { //设置ssid缓存信息
    if ([dict isKindOfClass:[NSDictionary class]]) {
        [[NSUserDefaults standardUserDefaults] setValue:dict forKey:ssidCacheKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

static NSString *getCurrentDeviceModel() { //获取设备的型号
    int mib[2];
    size_t len;
    char *machine;
    
    mib[0] = CTL_HW;
    mib[1] = HW_MACHINE;
    sysctl(mib, 2, NULL, &len, NULL, 0);
    machine = malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);
    
    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    
    NSDictionary *models = @{@"iPhone4,1": @"iPhone 4S",
                             @"iPhone5,1": @"iPhone 5 (GSM/LTE)",
                             @"iPhone5,2": @"iPhone 5 (CDMA/LTE)",
                             @"iPhone5,3": @"iPhone 5c (GSM/LTE)",
                             @"iPhone5,4": @"iPhone 5c (CDMA/LTE)",
                             @"iPhone6,1": @"iPhone 5s (GSM/LTE)",
                             @"iPhone6,2": @"iPhone 5s (CDMA/LTE)",
                             @"iPhone7,1": @"iPhone 6 Plus",
                             @"iPhone7,2": @"iPhone 6",
                             @"iPhone8,1": @"iPhone 6s",
                             @"iPhone8,2": @"iPhone 6s Plus",
                             @"iPhone8,4": @"iPhone SE",
                             @"iPhone9,1": @"iPhone 7 (CDMA+GSM/LTE)",
                             @"iPhone9,2": @"iPhone 7 Plus (CDMA+GSM/LTE)",
                             @"iPhone9,3": @"iPhone 7 (GSM/LTE)",
                             @"iPhone9,4": @"iPhone 7 Plus (GSM/LTE)",
                             @"iPhone10,1": @"iPhone 8",
                             @"iPhone10,2": @"iPhone 8 Plus",
                             @"iPhone10,3": @"iPhone X",
                             @"iPhone10,4": @"iPhone 8",
                             @"iPhone10,5": @"iPhone 8 Plus",
                             @"iPhone10,6": @"iPhone X",
                             
                             @"iPod5,1": @"iPod Touch 5",
                             @"iPod7,1": @"iPod touch 6",
                             
                             @"iPad2,1": @"iPad 2 (Wi‑Fi)",
                             @"iPad2,2": @"iPad 2 (GSM)",
                             @"iPad2,3": @"iPad 2 (CDMA)",
                             @"iPad2,4": @"iPad 2 (Wi‑Fi, A5R)",
                             @"iPad2,5": @"iPad mini (Wi‑Fi)",
                             @"iPad2,6": @"iPad mini (GSM/LTE)",
                             @"iPad2,7": @"iPad mini (CDMA/LTE)",
                             
                             @"iPad3,1": @"iPad 3 (Wi‑Fi)",
                             @"iPad3,2": @"iPad 3 (GSM/LTE)",
                             @"iPad3,3": @"iPad 3 (CDMA/LTE)",
                             @"iPad3,4": @"iPad 4 (Wi‑Fi)",
                             @"iPad3,5": @"iPad 4 (GSM/LTE)",
                             @"iPad3,6": @"iPad 4 (CDMA/LTE)",
                             
                             @"iPad4,1": @"iPad Air (Wi‑Fi)",
                             @"iPad4,2": @"iPad Air (LTE)",
                             @"iPad4,3": @"iPad Air (China)",
                             @"iPad4,4": @"iPad Mini 2 (Wi‑Fi)",
                             @"iPad4,5": @"iPad Mini 2 (LTE)",
                             @"iPad4,6": @"iPad Mini 2 (China)",
                             @"iPad4,7": @"iPad Mini 3 (Wi‑Fi)",
                             @"iPad4,8": @"iPad Mini 3 (LTE)",
                             @"iPad4,9": @"iPad Mini 3 (China)",
                             
                             @"iPad5,1": @"iPad mini 4 (Wi-Fi)",
                             @"iPad5,2": @"iPad mini 4 (LTE)",
                             @"iPad5,3": @"iPad Air 2 (Wi‑Fi)",
                             @"iPad5,4": @"iPad Air 2 (LTE)",
                             
                             @"iPad6,3": @"iPad Pro (9.7 inch) (Wi-Fi)",
                             @"iPad6,4": @"iPad Pro (9.7 inch) (LTE)",
                             @"iPad6,7": @"iPad Pro (12.9 inch) (Wi-Fi)",
                             @"iPad6,8": @"iPad Pro (12.9 inch) (LTE)",
                             @"iPad6,11": @"iPad 9.7-Inch 5th Gen (Wi-Fi Only)",
                             @"iPad6,12": @"iPad 9.7-Inch 5th Gen (Wi-Fi/Cellular)"
                             };
    
    NSString *newPlatform = models[platform];
    if (newPlatform.length > 0) {
        return newPlatform;
    }
    
    if ([platform isEqualToString:@"i386"] ||
        [platform isEqualToString:@"x86_64"])    return @"iPhone Simulator";
    return platform;
}

static NSString *getPhoneId() { //获取phoneid，用于日志
    NSString *phoneId = [GizKeychainRecorder load:XcodeAppBundle];
    NSLog(@"bundleID = %@", XcodeAppBundle);
    if (phoneId.length == 0) {
        phoneId = [[UIDevice currentDevice].identifierForVendor UUIDString];
        [GizKeychainRecorder save:XcodeAppBundle data:phoneId];
    }
    return phoneId;
}

@implementation GosCommon
    
+ (instancetype)sharedInstance {
    static GosCommon *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GosCommon alloc] init];
        instance.ssid = @"";
        instance.uid = @"";
        instance.token = @"";
        instance.currentLoginStatus = GizLoginNone;
        instance.cid = @"";
        [instance parseConfig];
    });
    return instance;
}
    
#pragma mark - 配网相关
- (void)saveSSID:(NSString *)ssid key:(NSString *)key { //保存ssid、密码
    if (nil == ssid)  return;
    if (nil == key) {
        key = @"";
    }
    
    NSMutableDictionary *dict = ssidKeyPairs();
    NSString *tmpEncryptKey = makeEncryptKey([self class], ssid);
    NSData *encrypted = AES256EncryptWithKey(tmpEncryptKey, [key dataUsingEncoding:NSUTF8StringEncoding]);
    [dict setValue:encrypted forKey:ssid];
    setSsidKeyPairs(dict);
}
    
- (NSString *)getPasswrodFromSSID:(NSString *)ssid { //通过ssid获取密码
    if (nil == ssid) return @"";
    
    NSMutableDictionary *dict = ssidKeyPairs();
    NSData *encrypted = dict[ssid];
    if ([encrypted isKindOfClass:[NSData class]]) {
        NSString *tmpEncryptKey = makeEncryptKey([self class], ssid);
        NSData *data = AES256DecryptWithKey(tmpEncryptKey, encrypted);
        if (data) {
            NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if ([ret isKindOfClass:[NSString class]]) {
                return ret;
            }
        }
    }
    return @"";
}
    

- (void)onCancel { //配置取消
    id <GosConfigStartDelegate>__delegate = self.delegate;
    [__delegate gosConfigDidFinished];
}
    
- (void)onSucceed:(GizWifiDevice *)device { //配置成功
    id <GosConfigStartDelegate>__delegate = self.delegate;
    [__delegate gosConfigDidSucceed:device];
}

    
+ (void)showAlertConfigDiscard:(void (^)(UIAlertAction *action))handler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Discard your configuration?", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:handler]];
    [alertController show];
}
    
+ (void)showAlertEmptyPassword:(void (^)(UIAlertAction *action))handler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Password is empty?", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:handler]];
    [alertController show];
}
    
- (void)showAlertCancelConfig:(void (^)(UIAlertAction *action))handler { //显示取消配置的提示
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"tip", nil) message:NSLocalizedString(@"Device try to connect, discard your configuration?", nil) preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:handler]];
    [alertController show];
}
    
- (void)cancelAlertViewDismiss { //隐藏配置提示
    [self.cancelAlertView dismissWithClickedButtonIndex:self.cancelAlertView.cancelButtonIndex animated:YES];
}
    
+ (NSURL *)wifiURL { //跳转设置的路径
    NSURL *url = [NSURL URLWithString:@"prefs:root=WIFI"];
    NSInteger version = [[UIDevice currentDevice].systemVersion integerValue];
    if (version >= 10) { //ios11开始不支持跳转到具体页面
        url = [NSURL URLWithString:@"App-Prefs:root=WIFI"];
    }
    return url;
}
    
#pragma mark - users
- (void)saveUserDefaults:(GizLoginType)loginType userName:(NSString *)username password:(NSString *)password tokenSecret:(NSString *)tokenSecret uid:(NSString *)uid token:(NSString *)token {
    if (uid.length == 32 && token.length == 32) {
        if (uid) self.uid = uid;
        if (token) self.token = token;
        self.sharingMessageList = nil;
        return;
    }
    [self removeUserDefaults]; //  先移除所有的信息
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:loginType forKey:@"loginType"];
    if (loginType != GizUnUserLogin && loginType != GizAnonymousLogin) {
        // 排除无用户和匿名登录的情况
        if (username.length > 0 && password.length > 0) {
            if (loginType == GizTwitterLogin) {
                if (tokenSecret.length > 0) {
                    [defaults setObject:username forKey:@"username"];
                    [defaults setObject:password forKey:@"password"];
                    [defaults setObject:tokenSecret forKey:@"tokenSecret"];
                }
                else {
                    [defaults setInteger:GizUnUserLogin forKey:@"loginType"];
                }
            }
            else {
                if (loginType == GizUserNameLogin) {
                    _tmpUser = username;
                    _tmpPass = password;
                }
                [defaults setObject:username forKey:@"username"];
                [defaults setObject:password forKey:@"password"];
            }
        }
        else {
            [defaults setInteger:GizUnUserLogin forKey:@"loginType"];
        }
    }
    [defaults synchronize];
    self.sharingMessageList = nil;
}
    
- (void)removeUserDefaults { //清理用户信息
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger loginType = [defaults integerForKey:@"loginType"];
    if (loginType == GizUserNameLogin) {
        _tmpUser = [defaults valueForKey:@"username"];
        _tmpPass = [defaults valueForKey:@"password"];
    }
    // 移除所有信息，并设置为无用户登陆的状态
    [defaults removeObjectForKey:@"username"];
    [defaults removeObjectForKey:@"password"];
    [defaults removeObjectForKey:@"tokenSecret"];
    [defaults setInteger:GizUnUserLogin forKey:@"loginType"];
    [defaults synchronize];
    self.uid = @"";
    self.token = @"";
}
    
- (void)removeUserValues { //清理用户缓存
    _tmpUser = nil;
    _tmpPass = nil;
}
    
#pragma mark - tools
- (NSString *)parseString:(NSDictionary *)dict key:(NSString *)key defaultValue:(NSString *)defaultValue { //根据配置文件，解析出符合国际化规则的字符串
    NSDictionary *stringDict = [dict dictValueForKey:key defaultValue:nil];
    if (stringDict) {
        if (GosCommon.isChinese) {
            return [stringDict stringValueForKey:@"ch" defaultValue:defaultValue];
        }
        return [stringDict stringValueForKey:@"en" defaultValue:defaultValue];
    }
    return defaultValue;
}
    
- (BOOL)isValidDomain:(NSString *)domain { //检测域名是否符合规则
    NSArray *domainArr = [domain componentsSeparatedByString:@"."];
    if (domainArr.count != 3 && domainArr.count != 4) { //xxx.xxx.xxx, xxx.xxx.xxx.xxx
        return NO;
    }
    BOOL isValidDomain = YES;
    for (NSString *str in domainArr) {
        if (str.length == 0) {
            isValidDomain = NO;
            break;
        }
    }
    return isValidDomain;
}
    
- (void)parseConfig { //解析配置文件
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"appConfig" ofType:@"json"];
    if (jsonPath) {
        @try {
            NSData *configContent = [NSData dataWithContentsOfFile:jsonPath];
            NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:configContent options:NSJSONReadingMutableContainers error:nil];
            if (jsonObject) {
                NSDictionary *buildInfo = [jsonObject dictValueForKey:@"buildInfo" defaultValue:nil];
                if (buildInfo) {
                    NSString *buildType = [buildInfo stringValueForKey:@"buildType" defaultValue:nil];
                    NSLog(@"buildType = %@", buildType);
                }
                NSDictionary *appInfo = [jsonObject dictValueForKey:@"appInfo" defaultValue:nil];
                if (appInfo) {
                    NSDictionary *cloudServiceInfo = [appInfo dictValueForKey:@"cloudService" defaultValue:nil];
                    if (cloudServiceInfo) {
                        NSString *openapi = [cloudServiceInfo stringValueForKey:@"api" defaultValue:nil];
                        NSString *site = [cloudServiceInfo stringValueForKey:@"site" defaultValue:nil];
                        NSString *push = [cloudServiceInfo stringValueForKey:@"push" defaultValue:nil];
                        if (![self isValidDomain:openapi]) {
                            openapi = nil;
                        }
                        if (![self isValidDomain:site]) {
                            site = nil;
                        }
                        if (![self isValidDomain:push]) {
                            push = nil;
                        }
                        NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
                        [mdict setValue:openapi forKey:@"openAPIInfo"];
                        [mdict setValue:site forKey:@"siteInfo"];
                        [mdict setValue:push forKey:@"pushInfo"];
                        if (openapi.length == 0) {
                            mdict = nil;
                        }
                        _cloudDomainDict = mdict;
                    }
                    NSDictionary *gizwitsInfo = [appInfo dictValueForKey:@"gizwitsInfo" defaultValue:nil];
                    if (gizwitsInfo) {
                        _appID = [gizwitsInfo stringValueForKey:@"appId" defaultValue:nil];
                        _appSecret = [gizwitsInfo stringValueForKey:@"appSecret" defaultValue:nil];
                    }
                    NSArray *productInfo = [appInfo arrayValueForKey:@"productInfo" defaultValue:nil];
                    if (productInfo) {
                        NSMutableArray *mArr = [NSMutableArray array];
                        for (NSDictionary *dict in productInfo) {
                            if (![dict isKindOfClass:[NSDictionary class]]) {
                                continue;
                            }
                            NSString *productKey = [dict stringValueForKey:@"productKey" defaultValue:nil];
                            NSString *productSecret = [dict stringValueForKey:@"productSecret" defaultValue:nil];
                            if (productKey.length == 32 && productSecret.length == 32) {
                                [mArr addObject:@{@"productKey": productKey,
                                                  @"productSecret": productSecret}];
                            }
                        }
                        _productInfo = mArr;
                    }
                    NSDictionary *tencentInfo = [appInfo dictValueForKey:@"tencentInfo" defaultValue:nil];
                    if (tencentInfo) {
                        _tencentAppID = [tencentInfo stringValueForKey:@"appId" defaultValue:nil];
                    }
                    NSDictionary *weChatInfo = [appInfo dictValueForKey:@"weChatInfo" defaultValue:nil];
                    if (weChatInfo) {
                        _wechatAppID = [weChatInfo stringValueForKey:@"appId" defaultValue:nil];
                        _wechatAppSecret = [weChatInfo stringValueForKey:@"appSecret" defaultValue:nil];
                    }
                    NSDictionary *facebookInfo = [appInfo dictValueForKey:@"facebookInfo" defaultValue:nil];
                    if (facebookInfo) {
                        _facebookAppID = [facebookInfo stringValueForKey:@"appId" defaultValue:nil];
                    }
                    NSDictionary *twitterInfo = [appInfo dictValueForKey:@"twitterInfo" defaultValue:nil];
                    if (twitterInfo) {
                        _twitterAppID = [twitterInfo stringValueForKey:@"appId" defaultValue:nil];
                        _twitterAppSecret = [twitterInfo stringValueForKey:@"appSecret" defaultValue:nil];
                    }
                    NSDictionary *pushInfo = [appInfo dictValueForKey:@"pushInfo" defaultValue:nil];
                    if (pushInfo) {
                        _jpushAppKey = [pushInfo stringValueForKey:@"jpushAppKey" defaultValue:nil];
                        _bpushAppKey = [pushInfo stringValueForKey:@"bpushAppKey" defaultValue:nil];
                    }
                    NSDictionary *umengInfo = [appInfo dictValueForKey:@"umengInfo" defaultValue:nil];
                    if (umengInfo) {
                        _umAppKey = [umengInfo stringValueForKey:@"appKey" defaultValue:nil];
                        _umMessageKey = [umengInfo stringValueForKey:@"messageKey" defaultValue:nil];
                    }
                }
                
                NSDictionary *templateSelectInfo = [jsonObject dictValueForKey:@"templateSelect" defaultValue:nil];
                if (templateSelectInfo) {
                    NSDictionary *deviceListInfo = [templateSelectInfo dictValueForKey:@"deviceList" defaultValue:nil];
                    if (deviceListInfo) {
                        _isAutoSubscribeDevice = [deviceListInfo boolValueForKey:@"autoSubscribe" defaultValue:NO];
                        _isUsingUnbindButton = [deviceListInfo boolValueForKey:@"unbindDevice" defaultValue:NO];
                        _isDisplayMac = [deviceListInfo boolValueForKey:@"displayMac" defaultValue:NO];
                        _usingPowerOnShortcutButton = [deviceListInfo arrayValueForKey:@"shortCutButton" defaultValue:nil];
                    }
                    _productLightDict = [templateSelectInfo dictValueForKey:@"product_light" defaultValue:nil];
                }
                
                NSDictionary *functionConfigInfo = [jsonObject dictValueForKey:@"functionConfig" defaultValue:nil];
                if (functionConfigInfo) {
                    _isNormalDeviceQRCodeScan = [functionConfigInfo boolValueForKey:@"bindDevice_qrcode" defaultValue:NO];
                    NSDictionary *deviceOnboarding = [functionConfigInfo dictValueForKey:@"deviceOnboarding" defaultValue:nil];
                    if (deviceOnboarding) {
                        _isSoftAP = [deviceOnboarding boolValueForKey:@"config_softap" defaultValue:NO];
                        _isAirlink = [deviceOnboarding boolValueForKey:@"config_airlink" defaultValue:NO];
                        _wifiModuleTypes = [deviceOnboarding arrayValueForKey:@"wifiModuleType" defaultValue:nil];
                        BOOL deploy = [deviceOnboarding boolValueForKey:@"useOnboardingDeploy" defaultValue:NO];
                        BOOL onboardingBind = [deviceOnboarding boolValueForKey:@"onboardingBind" defaultValue:NO];
                        if (deploy) {
                            if (onboardingBind) {
                                _onboardingType = GizSetDeviceOnboardingDeployBind;
                            }
                            else {
                                _onboardingType = GizSetDeviceOnboardingDeployUnbind;
                            }
                        }
                        else {
                            if (onboardingBind) {
                                _onboardingType = GizSetDeviceOnboardingByBind;
                            }
                            else {
                                _onboardingType = GizSetDeviceOnboarding;
                            }
                        }
                    }
                    _isAnonymous = [functionConfigInfo boolValueForKey:@"login_anonymous" defaultValue:NO];
                    _isQQ = [functionConfigInfo boolValueForKey:@"login_qq" defaultValue:NO];
                    _isWechat = [functionConfigInfo boolValueForKey:@"login_weChat" defaultValue:NO];
                    _isTwitter = [functionConfigInfo boolValueForKey:@"login_twitter" defaultValue:NO];
                    _isFacebook = [functionConfigInfo boolValueForKey:@"login_facebook" defaultValue:NO];
                    _isRegisterNormalUser = [functionConfigInfo boolValueForKey:@"register_normalUser" defaultValue:NO];
                    _isRegisterPhoneUser = [functionConfigInfo boolValueForKey:@"register_phoneUser" defaultValue:NO];
                    _isRegisterEmailUser = [functionConfigInfo boolValueForKey:@"register_emailUser" defaultValue:NO];
                    _isForgetPhoneUser = [functionConfigInfo boolValueForKey:@"resetPassword_phoneUser" defaultValue:NO];
                    _isForgetEmailUser = [functionConfigInfo boolValueForKey:@"resetPassword_emailUser" defaultValue:NO];
                    _isAddDeviceByQRCode = [functionConfigInfo boolValueForKey:@"gateway_qrcode" defaultValue:NO];
                    _isShowGatewayDataPoint = [functionConfigInfo boolValueForKey:@"gateway_showDataPoint" defaultValue:NO];
                    _isGroupModule = [functionConfigInfo boolValueForKey:@"gateway_group" defaultValue:NO];
                    _isSceneModule = [functionConfigInfo boolValueForKey:@"gateway_scene" defaultValue:NO];
                    _isSchedulerModule = [functionConfigInfo boolValueForKey:@"gateway_scheduler" defaultValue:NO];
                    _isJointActionModule = [functionConfigInfo boolValueForKey:@"gateway_jointAction" defaultValue:NO];
                    if (_isAddDeviceByQRCode || _isGroupModule || _isSceneModule || _isSchedulerModule || _isJointActionModule) {
                        _isGatewaySupport = YES;
                    }
                    _isMessageCenter = [functionConfigInfo boolValueForKey:@"messageCenter" defaultValue:YES];
                    _isDeviceOTA = [functionConfigInfo boolValueForKey:@"personalCenter_deviceOTA" defaultValue:NO];
                    _isDeviceSharingSupport = [functionConfigInfo boolValueForKey:@"personalCenter_deviceSharing" defaultValue:YES];
                    _isDeviceSharingQRCode = [functionConfigInfo boolValueForKey:@"personalCenter_deviceSharing_qrcode" defaultValue:YES];
                    _isFeedbackSupport = [functionConfigInfo boolValueForKey:@"personalCenter_feedbackSupport" defaultValue:NO];
                    _isDeviceGlobalDeployment = [functionConfigInfo boolValueForKey:@"personalCenter_deployment" defaultValue:NO];
                    _isSetDeploymentDomain = ![functionConfigInfo boolValueForKey:@"personalCenter_no_deployment_domain" defaultValue:NO];
                    _isWiFiModuleMall = [functionConfigInfo boolValueForKey:@"personalCenter_WiFiModuleMall" defaultValue:NO];
                    _isChangePassword = [functionConfigInfo boolValueForKey:@"personalCenter_changePassword" defaultValue:NO];
                    BOOL isBPush = [functionConfigInfo boolValueForKey:@"push_baidu" defaultValue:NO];
                    BOOL isJPush = [functionConfigInfo boolValueForKey:@"push_jiguang" defaultValue:NO];
                    if (isBPush) {
                        _pushType = 0;
                    }
                    else if (isJPush) {
                        _pushType = 1;
                    }
                    else {
                        _pushType = -1;  //未使用第三方推送
                    }
                    NSDictionary *disableLANInfo = [functionConfigInfo dictValueForKey:@"disableLan" defaultValue:nil];
                    if (disableLANInfo) {
                        _isDisableLAN = [disableLANInfo boolValueForKey:@"enable" defaultValue:NO];
                        if (_isDisableLAN) { //不支持以下功能
                            _isPowerSavingSupport = NO;
                            _isSoftAP = NO;
                            _isAirlink = NO;
                        } else {
                            _isPowerSavingSupport = [disableLANInfo boolValueForKey:@"powerSavingSupport" defaultValue:NO];
                        }
                    }
                    _isUmengSuport = [functionConfigInfo boolValueForKey:@"umengSupport" defaultValue:NO];
                    
                }
                NSLog(@"_isDisableLAN = %d, _isPowerSavingSupport = %d, _isSoftAP = %d, _isAirlink = %d", _isDisableLAN, _isPowerSavingSupport, _isSoftAP, _isAirlink);
                NSDictionary *viewConfigInfo = [jsonObject dictValueForKey:@"viewConfig" defaultValue:nil];
                if (viewConfigInfo) {
                    NSDictionary *viewColor = [viewConfigInfo dictValueForKey:@"viewColor" defaultValue:nil];
                    if (viewColor) {
                        _backgroundColor = [self colorWithString:[viewColor stringValueForKey:@"background" defaultValue:nil] defaultValue:[UIColor colorWithRed:0.973 green:0.855 blue:0.247 alpha:1]];
                        _contrastColor = [self colorWithString:[viewColor stringValueForKey:@"contrast" defaultValue:nil] defaultValue:[UIColor blackColor]];
                    }
                    NSDictionary *textContent = [viewConfigInfo dictValueForKey:@"textContent" defaultValue:nil];
                    if (textContent) {
                        _aboutInfo = [self parseString:textContent key:@"aboutInfo" defaultValue:nil];
                        NSDictionary *launchPageInfo = [textContent dictValueForKey:@"launchPageInfo" defaultValue:nil];
                    }
                    NSString *statusBarStyle = [viewConfigInfo stringValueForKey:@"statusBarStyle" defaultValue:nil];
                    if ([statusBarStyle isEqualToString:@"colored"]) {
                        _statusBarStyle = UIStatusBarStyleLightContent;
                    }
                    else {
                        _statusBarStyle = UIStatusBarStyleDefault;
                    }
                }
                _deviceInfo = [jsonObject arrayValueForKey:@"deviceInfo" defaultValue:nil];
                NSLog(@"deviceInfo = %@", _deviceInfo);
            } else {
                NSLog(@"Parse json failed");
                [self loadDefaultConfig];
            }
        } @catch (NSException *exception) {
            GIZ_LOG_DEBUG("Parse appConfig.json cause an exception: %s", exception.description.UTF8String);
        }
    } else {
        NSLog(@"appConfig.json was not exist.");
        [self loadDefaultConfig];
    }
}
    
- (void)loadDefaultConfig { //解析失败后，需要设置的默认值
    _backgroundColor = [UIColor colorWithRed:0.973 green:0.855 blue:0.247 alpha:1];
    _contrastColor = [UIColor blackColor];
    _statusBarStyle = UIStatusBarStyleDefault;
}
    
- (NSString *)checkErrorCode:(GizWifiErrorCode)errorCode { //错误信息的国际化转换
    switch (errorCode) {
        case GIZ_SDK_PARAM_FORM_INVALID:
        return NSLocalizedString(@"GIZ_SDK_PARAM_FORM_INVALID", nil);
        case GIZ_SDK_CLIENT_NOT_AUTHEN:
        return NSLocalizedString(@"GIZ_SDK_CLIENT_NOT_AUTHEN", nil);
        case GIZ_SDK_CLIENT_VERSION_INVALID:
        return NSLocalizedString(@"GIZ_SDK_CLIENT_VERSION_INVALID", nil);
        case GIZ_SDK_UDP_PORT_BIND_FAILED:
        return NSLocalizedString(@"GIZ_SDK_UDP_PORT_BIND_FAILED", nil);
        case GIZ_SDK_DAEMON_EXCEPTION:
        return NSLocalizedString(@"GIZ_SDK_DAEMON_EXCEPTION", nil);
        case GIZ_SDK_PARAM_INVALID:
        return NSLocalizedString(@"GIZ_SDK_PARAM_INVALID", nil);
        case GIZ_SDK_APPID_LENGTH_ERROR:
        return NSLocalizedString(@"GIZ_SDK_APPID_LENGTH_ERROR", nil);
        case GIZ_SDK_LOG_PATH_INVALID:
        return NSLocalizedString(@"GIZ_SDK_LOG_PATH_INVALID", nil);
        case GIZ_SDK_LOG_LEVEL_INVALID:
        return NSLocalizedString(@"GIZ_SDK_LOG_LEVEL_INVALID", nil);
        case GIZ_SDK_UID_INVALID:
        return NSLocalizedString(@"GIZ_SDK_UID_INVALID", nil);
        case GIZ_SDK_TOKEN_INVALID:
        return NSLocalizedString(@"GIZ_SDK_TOKEN_INVALID", nil);
        case GIZ_SDK_USER_NOT_LOGIN:
        return NSLocalizedString(@"GIZ_SDK_USER_NOT_LOGIN", nil);
        case GIZ_SDK_APPID_INVALID:
        return NSLocalizedString(@"GIZ_SDK_APPID_INVALID", nil);
        case GIZ_SDK_APP_SECRET_INVALID:
        return NSLocalizedString(@"GIZ_SDK_APP_SECRET_INVALID", nil);
        case GIZ_SDK_PRODUCT_KEY_INVALID:
        return NSLocalizedString(@"GIZ_SDK_PRODUCT_KEY_INVALID", nil);
        case GIZ_SDK_PRODUCT_SECRET_INVALID:
        return NSLocalizedString(@"GIZ_SDK_PRODUCT_SECRET_INVALID", nil);
        case GIZ_SDK_DEVICE_NOT_IN_LAN:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_NOT_IN_LAN", nil);
        case GIZ_SDK_PRODUCTKEY_NOT_IN_SPECIAL_LIST:
        return NSLocalizedString(@"GIZ_SDK_PRODUCTKEY_NOT_IN_SPECIAL_LIST", nil);
        case GIZ_SDK_PRODUCTKEY_NOT_RELATED_WITH_APPID:
        return NSLocalizedString(@"GIZ_SDK_PRODUCTKEY_NOT_RELATED_WITH_APPID", nil);
        
        case GIZ_SDK_NO_AVAILABLE_DEVICE:
        return NSLocalizedString(@"GIZ_SDK_NO_AVAILABLE_DEVICE", nil);
        case GIZ_SDK_DEVICE_CONFIG_SEND_FAILED:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_CONFIG_SEND_FAILED", nil);
        case GIZ_SDK_DEVICE_CONFIG_IS_RUNNING:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_CONFIG_IS_RUNNING", nil);
        case GIZ_SDK_DEVICE_CONFIG_TIMEOUT:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_CONFIG_TIMEOUT", nil);
        case GIZ_SDK_DEVICE_DID_INVALID:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_DID_INVALID", nil);
        case GIZ_SDK_DEVICE_MAC_INVALID:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_MAC_INVALID", nil);
        case GIZ_SDK_SUBDEVICE_DID_INVALID:
        return NSLocalizedString(@"GIZ_SDK_SUBDEVICE_DID_INVALID", nil);
        case GIZ_SDK_DEVICE_PASSCODE_INVALID:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_PASSCODE_INVALID", nil);
        case GIZ_SDK_DEVICE_NOT_CENTERCONTROL:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_NOT_CENTERCONTROL", nil);
        case GIZ_SDK_DEVICE_NOT_SUBSCRIBED:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_NOT_SUBSCRIBED", nil);
        case GIZ_SDK_DEVICE_NO_RESPONSE:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_NO_RESPONSE", nil);
        case GIZ_SDK_DEVICE_NOT_READY:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_NOT_READY", nil);
        case GIZ_SDK_DEVICE_NOT_BINDED:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_NOT_BINDED", nil);
        case GIZ_SDK_DEVICE_CONTROL_WITH_INVALID_COMMAND:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_CONTROL_WITH_INVALID_COMMAND", nil);
        case GIZ_SDK_DEVICE_CONTROL_FAILED:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_CONTROL_FAILED", nil);
        case GIZ_SDK_DEVICE_GET_STATUS_FAILED:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_GET_STATUS_FAILED", nil);
        case GIZ_SDK_DEVICE_CONTROL_VALUE_TYPE_ERROR:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_CONTROL_VALUE_TYPE_ERROR", nil);
        case GIZ_SDK_DEVICE_CONTROL_VALUE_OUT_OF_RANGE:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_CONTROL_VALUE_OUT_OF_RANGE", nil);
        case GIZ_SDK_DEVICE_CONTROL_NOT_WRITABLE_COMMAND:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_CONTROL_NOT_WRITABLE_COMMAND", nil);
        case GIZ_SDK_BIND_DEVICE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_BIND_DEVICE_FAILED", nil);
        case GIZ_SDK_UNBIND_DEVICE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_UNBIND_DEVICE_FAILED", nil);
        case GIZ_SDK_DNS_FAILED:
        return NSLocalizedString(@"GIZ_SDK_DNS_FAILED", nil);
        case GIZ_SDK_M2M_CONNECTION_SUCCESS:
        return NSLocalizedString(@"GIZ_SDK_M2M_CONNECTION_SUCCESS", nil);
        case GIZ_SDK_SET_SOCKET_NON_BLOCK_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SET_SOCKET_NON_BLOCK_FAILED", nil);
        case GIZ_SDK_CONNECTION_TIMEOUT:
        return NSLocalizedString(@"GIZ_SDK_CONNECTION_TIMEOUT", nil);
        case GIZ_SDK_CONNECTION_REFUSED:
        return NSLocalizedString(@"GIZ_SDK_CONNECTION_REFUSED", nil);
        case GIZ_SDK_CONNECTION_ERROR:
        return NSLocalizedString(@"GIZ_SDK_CONNECTION_ERROR", nil);
        case GIZ_SDK_CONNECTION_CLOSED:
        return NSLocalizedString(@"GIZ_SDK_CONNECTION_CLOSED", nil);
        case GIZ_SDK_SSL_HANDSHAKE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SSL_HANDSHAKE_FAILED", nil);
        case GIZ_SDK_DEVICE_LOGIN_VERIFY_FAILED:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_LOGIN_VERIFY_FAILED", nil);
        case GIZ_SDK_INTERNET_NOT_REACHABLE:
        return NSLocalizedString(@"GIZ_SDK_INTERNET_NOT_REACHABLE", nil);
        case GIZ_SDK_M2M_CONNECTION_INVALID:
        return NSLocalizedString(@"GIZ_SDK_M2M_CONNECTION_INVALID", nil);
        case GIZ_SDK_HTTP_SERVER_NOT_SUPPORT_API:
        return NSLocalizedString(@"GIZ_SDK_HTTP_SERVER_NOT_SUPPORT_API", nil);
        case GIZ_SDK_HTTP_ANSWER_FORMAT_ERROR:
        return NSLocalizedString(@"GIZ_SDK_HTTP_ANSWER_FORMAT_ERROR", nil);
        case GIZ_SDK_HTTP_ANSWER_PARAM_ERROR:
        return NSLocalizedString(@"GIZ_SDK_HTTP_ANSWER_PARAM_ERROR", nil);
        case GIZ_SDK_HTTP_SERVER_NO_ANSWER:
        return NSLocalizedString(@"GIZ_SDK_HTTP_SERVER_NO_ANSWER", nil);
        case GIZ_SDK_HTTP_REQUEST_FAILED:
        return NSLocalizedString(@"GIZ_SDK_HTTP_REQUEST_FAILED", nil);
        case GIZ_SDK_OTHERWISE:
        return NSLocalizedString(@"GIZ_SDK_OTHERWISE", nil);
        case GIZ_SDK_MEMORY_MALLOC_FAILED:
        return NSLocalizedString(@"GIZ_SDK_MEMORY_MALLOC_FAILED", nil);
        case GIZ_SDK_THREAD_CREATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_THREAD_CREATE_FAILED", nil);
        case GIZ_SDK_AES_ENCRYPT_FAILED:
        return NSLocalizedString(@"GIZ_SDK_AES_ENCRYPT_FAILED", nil);
        case GIZ_SDK_AES_DECRYPT_FAILED:
        return NSLocalizedString(@"GIZ_SDK_AES_DECRYPT_FAILED", nil);
        case GIZ_SDK_JSON_OBJECT_CREATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_JSON_OBJECT_CREATE_FAILED", nil);
        case GIZ_SDK_JSON_PARSE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_JSON_PARSE_FAILED", nil);
        case GIZ_SDK_JSON_UNFORMAT_FAILED:
        return NSLocalizedString(@"GIZ_SDK_JSON_UNFORMAT_FAILED", nil);
        case GIZ_SDK_JSON_DUPLICATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_JSON_DUPLICATE_FAILED", nil);
        case GIZ_SDK_SCHEDULER_CREATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCHEDULER_CREATE_FAILED", nil);
        case GIZ_SDK_SCHEDULER_DELETE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCHEDULER_DELETE_FAILED", nil);
        case GIZ_SDK_SCHEDULER_EDIT_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCHEDULER_EDIT_FAILED", nil);
        case GIZ_SDK_SCHEDULER_LIST_UPDATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCHEDULER_LIST_UPDATE_FAILED", nil);
        case GIZ_SDK_SCHEDULER_TASK_EDIT_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCHEDULER_TASK_EDIT_FAILED", nil);
        case GIZ_SDK_SCHEDULER_TASK_LIST_UPDATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCHEDULER_TASK_LIST_UPDATE_FAILED", nil);
        case GIZ_SDK_SCHEDULER_ID_INVALID:
        return NSLocalizedString(@"GIZ_SDK_SCHEDULER_ID_INVALID", nil);
        case GIZ_SDK_SCHEDULER_ENABLE_DISABLE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCHEDULER_ENABLE_DISABLE_FAILED", nil);
        case GIZ_SDK_SCHEDULER_STATUS_UPDATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCHEDULER_STATUS_UPDATE_FAILED", nil);
        case GIZ_SDK_SUBDEVICE_ADD_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SUBDEVICE_ADD_FAILED", nil);
        case GIZ_SDK_SUBDEVICE_DELETE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SUBDEVICE_DELETE_FAILED", nil);
        case GIZ_SDK_SUBDEVICE_LIST_UPDATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SUBDEVICE_LIST_UPDATE_FAILED", nil);
        case GIZ_SDK_GROUP_ID_INVALID:
        return NSLocalizedString(@"GIZ_SDK_GROUP_ID_INVALID", nil);
        case GIZ_SDK_GROUP_PRODUCTKEY_INVALID:
        return NSLocalizedString(@"GIZ_SDK_GROUP_PRODUCTKEY_INVALID", nil);
        case GIZ_SDK_GROUP_FAILED_DELETE_DEVICE:
        return NSLocalizedString(@"GIZ_SDK_GROUP_FAILED_DELETE_DEVICE", nil);
        case GIZ_SDK_GROUP_FAILED_ADD_DEVICE:
        return NSLocalizedString(@"GIZ_SDK_GROUP_FAILED_ADD_DEVICE", nil);
        case GIZ_SDK_GROUP_GET_DEVICE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_GROUP_GET_DEVICE_FAILED", nil);
        case GIZ_SDK_GROUP_CREATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_GROUP_CREATE_FAILED", nil);
        case GIZ_SDK_GROUP_DELETE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_GROUP_DELETE_FAILED", nil);
        case GIZ_SDK_GROUP_EDIT_FAILED:
        return NSLocalizedString(@"GIZ_SDK_GROUP_EDIT_FAILED", nil);
        case GIZ_SDK_GROUP_LIST_UPDATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_GROUP_LIST_UPDATE_FAILED", nil);
        case GIZ_SDK_GROUP_COMMAND_WRITE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_GROUP_COMMAND_WRITE_FAILED", nil);
        case GIZ_SDK_SCENE_CREATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCENE_CREATE_FAILED", nil);
        case GIZ_SDK_SCENE_DELETE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCENE_DELETE_FAILED", nil);
        case GIZ_SDK_SCENE_EDIT_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCENE_EDIT_FAILED", nil);
        case GIZ_SDK_SCENE_LIST_UPDATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCENE_LIST_UPDATE_FAILED", nil);
        case GIZ_SDK_SCENE_ITEM_LIST_EDIT_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCENE_ITEM_LIST_EDIT_FAILED", nil);
        case GIZ_SDK_SCENE_ITEM_LIST_UPDATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCENE_ITEM_LIST_UPDATE_FAILED", nil);
        case GIZ_SDK_SCENE_ID_INVALID:
        return NSLocalizedString(@"GIZ_SDK_SCENE_ID_INVALID", nil);
        case GIZ_SDK_SCENE_RUN_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCENE_RUN_FAILED", nil);
        case GIZ_SDK_SCENE_STATUS_UPDATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_SCENE_STATUS_UPDATE_FAILED", nil);
        case GIZ_SDK_JOINT_ACTION_CREATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_JOINT_ACTION_CREATE_FAILED", nil);
        case GIZ_SDK_JOINT_ACTION_DELETE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_JOINT_ACTION_DELETE_FAILED", nil);
        case GIZ_SDK_JOINT_ACTION_VER_UNSUPPORTED:
        return NSLocalizedString(@"GIZ_SDK_JOINT_ACTION_VER_UNSUPPORTED", nil);
        case GIZ_SDK_JOINT_ACTION_INVALID_CONDITION_TYPE:
        return NSLocalizedString(@"GIZ_SDK_JOINT_ACTION_INVALID_CONDITION_TYPE", nil);
        case GIZ_SDK_JOINT_ACTION_INVALID_RESULT_EVENT_TYPE:
        return NSLocalizedString(@"GIZ_SDK_JOINT_ACTION_INVALID_RESULT_EVENT_TYPE", nil);
        case GIZ_SDK_DATAPOINT_NOT_DOWNLOAD:
        return NSLocalizedString(@"GIZ_SDK_DATAPOINT_NOT_DOWNLOAD", nil);
        case GIZ_SDK_DATAPOINT_SERVICE_UNAVAILABLE:
        return NSLocalizedString(@"GIZ_SDK_DATAPOINT_SERVICE_UNAVAILABLE", nil);
        case GIZ_SDK_DATAPOINT_PARSE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_DATAPOINT_PARSE_FAILED", nil);
        case GIZ_SDK_DEVICE_GATWEWAY_UNKNOWN:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_GATWEWAY_UNKNOWN", nil);
        case GIZ_SDK_DEVICE_MESHID_INVALID:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_MESHID_INVALID", nil);
        case GIZ_SDK_DEVICE_PRODUCTKEY_DIFFERENT:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_PRODUCTKEY_DIFFERENT", nil);
        case GIZ_SDK_NOT_INITIALIZED:
        return NSLocalizedString(@"GIZ_SDK_SDK_NOT_INITIALIZED", nil);
        case GIZ_SDK_EXEC_DAEMON_FAILED:
        return NSLocalizedString(@"GIZ_SDK_EXEC_DAEMON_FAILED", nil);
        case GIZ_SDK_EXEC_CATCH_EXCEPTION:
        return NSLocalizedString(@"GIZ_SDK_EXEC_CATCH_EXCEPTION", nil);
        case GIZ_SDK_APPID_IS_EMPTY:
        return NSLocalizedString(@"GIZ_SDK_APPID_IS_EMPTY", nil);
        case GIZ_SDK_UNSUPPORTED_API:
        return NSLocalizedString(@"GIZ_SDK_UNSUPPORTED_API", nil);
        case GIZ_SDK_REQUEST_TIMEOUT:
        return NSLocalizedString(@"GIZ_SDK_REQUEST_TIMEOUT", nil);
        case GIZ_SDK_DAEMON_VERSION_INVALID:
        return NSLocalizedString(@"GIZ_SDK_DAEMON_VERSION_INVALID", nil);
        case GIZ_SDK_PHONE_NOT_CONNECT_TO_SOFTAP_SSID:
        return NSLocalizedString(@"GIZ_SDK_PHONE_NOT_CONNECT_TO_SOFTAP_SSID", nil);
        case GIZ_SDK_DEVICE_CONFIG_SSID_NOT_MATCHED:
        return NSLocalizedString(@"GIZ_SDK_DEVICE_CONFIG_SSID_NOT_MATCHED", nil);
        case GIZ_SDK_NOT_IN_SOFTAPMODE:
        return NSLocalizedString(@"GIZ_SDK_NOT_IN_SOFTAPMODE", nil);
        case GIZ_SDK_PHONE_WIFI_IS_UNAVAILABLE:
        return NSLocalizedString(@"GIZ_SDK_PHONE_WIFI_IS_UNAVAILABLE", nil);
        case GIZ_SDK_RAW_DATA_TRANSMIT:
        return NSLocalizedString(@"GIZ_SDK_RAW_DATA_TRANSMIT", nil);
        case GIZ_SDK_PRODUCT_IS_DOWNLOADING:
        return NSLocalizedString(@"GIZ_SDK_PRODUCT_IS_DOWNLOADING", nil);
        case GIZ_SDK_START_SUCCESS:
        return NSLocalizedString(@"GIZ_SDK_START_SUCCESS", nil);
        //        case GIZ_SDK_NEED_UPDATE_TO_LATEST:
        //            return NSLocalizedString(@"GIZ_SDK_NEED_UPDATE_TO_LATEST", nil);
        case GIZ_SDK_ONBOARDING_STOPPED:
        return NSLocalizedString(@"GIZ_SDK_ONBOARDING_STOPPED", nil);
        //        case GIZ_SDK_ONBOARDING_WIFI_IS_5G:
        //            return NSLocalizedString(@"GIZ_SDK_ONBOARDING_WIFI_IS_5G", nil);
        case GIZ_SDK_OTA_FIRMWARE_IS_LATEST:
        return NSLocalizedString(@"GIZ_SDK_OTA_FIRMWARE_IS_LATEST", nil);
        case GIZ_SDK_OTA_FIRMWARE_CHECK_UPDATE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_OTA_FIRMWARE_CHECK_UPDATE_FAILED", nil);
        case GIZ_SDK_OTA_FIRMWARE_DOWNLOAD_OK:
        return NSLocalizedString(@"GIZ_SDK_OTA_FIRMWARE_DOWNLOAD_OK", nil);
        case GIZ_SDK_OTA_FIRMWARE_DOWNLOAD_FAILED:
        return NSLocalizedString(@"GIZ_SDK_OTA_FIRMWARE_DOWNLOAD_FAILED", nil);
        case GIZ_SDK_OTA_DEVICE_BUSY_IN_UPGRADE:
        return NSLocalizedString(@"GIZ_SDK_OTA_DEVICE_BUSY_IN_UPGRADE", nil);
        case GIZ_SDK_OTA_PUSH_FAILED:
        return NSLocalizedString(@"GIZ_SDK_OTA_PUSH_FAILED", nil);
        case GIZ_SDK_OTA_FIRMWARE_VERSION_TOO_LOW:
        return NSLocalizedString(@"GIZ_SDK_OTA_FIRMWARE_VERSION_TOO_LOW", nil);
        case GIZ_SDK_OTA_FIRMWARE_CHECK_FAILED:
        return NSLocalizedString(@"GIZ_SDK_OTA_FIRMWARE_CHECK_FAILED", nil);
        case GIZ_SDK_OTA_UPGRADE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_OTA_UPGRADE_FAILED", nil);
        case GIZ_SDK_OTA_FIRMWARE_VERIFY_SUCCESS:
        return NSLocalizedString(@"GIZ_SDK_OTA_FIRMWARE_VERIFY_SUCCESS", nil);
        case GIZ_SDK_OTA_DEVICE_NOT_SUPPORT:
        return NSLocalizedString(@"GIZ_SDK_OTA_DEVICE_NOT_SUPPORT", nil);
        case GIZ_SDK_WS_HANDSHAKE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_WS_HANDSHAKE_FAILED", nil);
        case GIZ_SDK_WS_LOGIN_FAILED:
        return NSLocalizedString(@"GIZ_SDK_WS_LOGIN_FAILED", nil);
        case GIZ_SDK_WS_DEVICE_SUBSCRIBE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_WS_DEVICE_SUBSCRIBE_FAILED", nil);
        case GIZ_SDK_WS_DEVICE_UNSUBSCRIBE_FAILED:
        return NSLocalizedString(@"GIZ_SDK_WS_DEVICE_UNSUBSCRIBE_FAILED", nil);
        case GIZ_SITE_PRODUCTKEY_INVALID:
        return NSLocalizedString(@"GIZ_SITE_PRODUCTKEY_INVALID", nil);
        case GIZ_SITE_DATAPOINTS_NOT_DEFINED:
        return NSLocalizedString(@"GIZ_SITE_DATAPOINTS_NOT_DEFINED", nil);
        case GIZ_SITE_DATAPOINTS_NOT_MALFORME:
        return NSLocalizedString(@"GIZ_SITE_DATAPOINTS_NOT_MALFORME", nil);
        case GIZ_OPENAPI_MAC_ALREADY_REGISTERED:
        return NSLocalizedString(@"GIZ_OPENAPI_MAC_ALREADY_REGISTERED", nil);
        case GIZ_OPENAPI_PRODUCT_KEY_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_PRODUCT_KEY_INVALID", nil);
        case GIZ_OPENAPI_APPID_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_APPID_INVALID", nil);
        case GIZ_OPENAPI_TOKEN_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_TOKEN_INVALID", nil);
        case GIZ_OPENAPI_USER_NOT_EXIST:
        return NSLocalizedString(@"GIZ_OPENAPI_USER_NOT_EXIST", nil);
        case GIZ_OPENAPI_TOKEN_EXPIRED:
        return NSLocalizedString(@"GIZ_OPENAPI_TOKEN_EXPIRED", nil);
        case GIZ_OPENAPI_M2M_ID_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_M2M_ID_INVALID", nil);
        case GIZ_OPENAPI_SERVER_ERROR:
        return NSLocalizedString(@"GIZ_OPENAPI_SERVER_ERROR", nil);
        case GIZ_OPENAPI_CODE_EXPIRED:
        return NSLocalizedString(@"GIZ_OPENAPI_CODE_EXPIRED", nil);
        case GIZ_OPENAPI_CODE_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_CODE_INVALID", nil);
        case GIZ_OPENAPI_SANDBOX_SCALE_QUOTA_EXHAUSTED:
        return NSLocalizedString(@"GIZ_OPENAPI_SANDBOX_SCALE_QUOTA_EXHAUSTED", nil);
        case GIZ_OPENAPI_PRODUCTION_SCALE_QUOTA_EXHAUSTED:
        return NSLocalizedString(@"GIZ_OPENAPI_PRODUCTION_SCALE_QUOTA_EXHAUSTED", nil);
        case GIZ_OPENAPI_PRODUCT_HAS_NO_REQUEST_SCALE:
        return NSLocalizedString(@"GIZ_OPENAPI_PRODUCT_HAS_NO_REQUEST_SCALE", nil);
        case GIZ_OPENAPI_DEVICE_NOT_FOUND:
        return NSLocalizedString(@"GIZ_OPENAPI_DEVICE_NOT_FOUND", nil);
        case GIZ_OPENAPI_FORM_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_FORM_INVALID", nil);
        case GIZ_OPENAPI_DID_PASSCODE_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_DID_PASSCODE_INVALID", nil);
        case GIZ_OPENAPI_DEVICE_NOT_BOUND:
        return NSLocalizedString(@"GIZ_OPENAPI_DEVICE_NOT_BOUND", nil);
        case GIZ_OPENAPI_PHONE_UNAVALIABLE:
        return NSLocalizedString(@"GIZ_OPENAPI_PHONE_UNAVALIABLE", nil);
        case GIZ_OPENAPI_USERNAME_UNAVALIABLE:
        return NSLocalizedString(@"GIZ_OPENAPI_USERNAME_UNAVALIABLE", nil);
        case GIZ_OPENAPI_USERNAME_PASSWORD_ERROR:
        return NSLocalizedString(@"GIZ_OPENAPI_USERNAME_PASSWORD_ERROR", nil);
        case GIZ_OPENAPI_SEND_COMMAND_FAILED:
        return NSLocalizedString(@"GIZ_OPENAPI_SEND_COMMAND_FAILED", nil);
        case GIZ_OPENAPI_EMAIL_UNAVALIABLE:
        return NSLocalizedString(@"GIZ_OPENAPI_EMAIL_UNAVALIABLE", nil);
        case GIZ_OPENAPI_DEVICE_DISABLED:
        return NSLocalizedString(@"GIZ_OPENAPI_DEVICE_DISABLED", nil);
        case GIZ_OPENAPI_FAILED_NOTIFY_M2M:
        return NSLocalizedString(@"GIZ_OPENAPI_FAILED_NOTIFY_M2M", nil);
        case GIZ_OPENAPI_ATTR_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_ATTR_INVALID", nil);
        case GIZ_OPENAPI_USER_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_USER_INVALID", nil);
        case GIZ_OPENAPI_FIRMWARE_NOT_FOUND:
        return NSLocalizedString(@"GIZ_OPENAPI_FIRMWARE_NOT_FOUND", nil);
        case GIZ_OPENAPI_JD_PRODUCT_NOT_FOUND:
        return NSLocalizedString(@"GIZ_OPENAPI_JD_PRODUCT_NOT_FOUND", nil);
        case GIZ_OPENAPI_DATAPOINT_DATA_NOT_FOUND:
        return NSLocalizedString(@"GIZ_OPENAPI_DATAPOINT_DATA_NOT_FOUND", nil);
        case GIZ_OPENAPI_SCHEDULER_NOT_FOUND:
        return NSLocalizedString(@"GIZ_OPENAPI_SCHEDULER_NOT_FOUND", nil);
        case GIZ_OPENAPI_QQ_OAUTH_KEY_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_QQ_OAUTH_KEY_INVALID", nil);
        case GIZ_OPENAPI_OTA_SERVICE_OK_BUT_IN_IDLE:
        return NSLocalizedString(@"GIZ_OPENAPI_OTA_SERVICE_OK_BUT_IN_IDLE", nil);
        case GIZ_OPENAPI_BT_FIRMWARE_UNVERIFIED:
        return NSLocalizedString(@"GIZ_OPENAPI_BT_FIRMWARE_UNVERIFIED", nil);
        case GIZ_OPENAPI_BT_FIRMWARE_NOTHING_TO_UPGRADE:
        return NSLocalizedString(@"GIZ_OPENAPI_BT_FIRMWARE_NOTHING_TO_UPGRADE", nil);
        case GIZ_OPENAPI_SAVE_KAIROSDB_ERROR:
        return NSLocalizedString(@"GIZ_OPENAPI_SAVE_KAIROSDB_ERROR", nil);
        case GIZ_OPENAPI_EVENT_NOT_DEFINED:
        return NSLocalizedString(@"GIZ_OPENAPI_EVENT_NOT_DEFINED", nil);
        case GIZ_OPENAPI_SEND_SMS_FAILED:
        return NSLocalizedString(@"GIZ_OPENAPI_SEND_SMS_FAILED", nil);
        case GIZ_OPENAPI_APPLICATION_AUTH_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_APPLICATION_AUTH_INVALID", nil);
        case GIZ_OPENAPI_NOT_ALLOWED_CALL_API:
        return NSLocalizedString(@"GIZ_OPENAPI_NOT_ALLOWED_CALL_API", nil);
        case GIZ_OPENAPI_BAD_QRCODE_CONTENT:
        return NSLocalizedString(@"GIZ_OPENAPI_BAD_QRCODE_CONTENT", nil);
        case GIZ_OPENAPI_REQUEST_THROTTLED:
        return NSLocalizedString(@"GIZ_OPENAPI_REQUEST_THROTTLED", nil);
        case GIZ_OPENAPI_DEVICE_OFFLINE:
        return NSLocalizedString(@"GIZ_OPENAPI_DEVICE_OFFLINE", nil);
        case GIZ_OPENAPI_TIMESTAMP_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_TIMESTAMP_INVALID", nil);
        case GIZ_OPENAPI_SIGNATURE_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_SIGNATURE_INVALID", nil);
        case GIZ_OPENAPI_DEPRECATED_API:
        return NSLocalizedString(@"GIZ_OPENAPI_DEPRECATED_API", nil);
        case GIZ_OPENAPI_REGISTER_IS_BUSY:
        return NSLocalizedString(@"GIZ_OPENAPI_REGISTER_IS_BUSY", nil);
        case GIZ_OPENAPI_CANNOT_SHARE_TO_SELF:
        return NSLocalizedString(@"GIZ_OPENAPI_CANNOT_SHARE_TO_SELF", nil);
        case GIZ_OPENAPI_ONLY_OWNER_CAN_SHARE:
        return NSLocalizedString(@"GIZ_OPENAPI_ONLY_OWNER_CAN_SHARE", nil);
        case GIZ_OPENAPI_NOT_FOUND_GUEST:
        return NSLocalizedString(@"GIZ_OPENAPI_NOT_FOUND_GUEST", nil);
        case GIZ_OPENAPI_GUEST_ALREADY_BOUND:
        return NSLocalizedString(@"GIZ_OPENAPI_GUEST_ALREADY_BOUND", nil);
        case GIZ_OPENAPI_NOT_FOUND_SHARING_INFO:
        return NSLocalizedString(@"GIZ_OPENAPI_NOT_FOUND_SHARING_INFO", nil);
        case GIZ_OPENAPI_NOT_FOUND_THE_MESSAGE:
        return NSLocalizedString(@"GIZ_OPENAPI_NOT_FOUND_THE_MESSAGE", nil);
        case GIZ_OPENAPI_SHARING_IS_WAITING_FOR_ACCEPT:
        return NSLocalizedString(@"GIZ_OPENAPI_SHARING_IS_WAITING_FOR_ACCEPT", nil);
        case GIZ_OPENAPI_SHARING_IS_EXPIRED:
        return NSLocalizedString(@"GIZ_OPENAPI_SHARING_IS_EXPIRED", nil);
        case GIZ_OPENAPI_SHARING_IS_COMPLETED:
        return NSLocalizedString(@"GIZ_OPENAPI_SHARING_IS_COMPLETED", nil);
        case GIZ_OPENAPI_INVALID_SHARING_BECAUSE_UNBINDING:
        return NSLocalizedString(@"GIZ_OPENAPI_INVALID_SHARING_BECAUSE_UNBINDING", nil);
        case GIZ_OPENAPI_ONLY_OWNER_CAN_BIND:
        return NSLocalizedString(@"GIZ_OPENAPI_ONLY_OWNER_CAN_BIND", nil);
        case GIZ_OPENAPI_ONLY_OWNER_CAN_OPERATE:
        return NSLocalizedString(@"GIZ_OPENAPI_ONLY_OWNER_CAN_OPERATE", nil);
        case GIZ_OPENAPI_SHARING_ALREADY_CANCELLED:
        return NSLocalizedString(@"GIZ_OPENAPI_SHARING_ALREADY_CANCELLED", nil);
        case GIZ_OPENAPI_OWNER_CANNOT_UNBIND_SELF:
        return NSLocalizedString(@"GIZ_OPENAPI_OWNER_CANNOT_UNBIND_SELF", nil);
        case GIZ_OPENAPI_ONLY_GUEST_CAN_CHECK_QRCODE:
        return NSLocalizedString(@"GIZ_OPENAPI_ONLY_GUEST_CAN_CHECK_QRCODE", nil);
        case GIZ_OPENAPI_MESSAGE_ALREADY_DELETED:
        return NSLocalizedString(@"GIZ_OPENAPI_MESSAGE_ALREADY_DELETED", nil);
        case GIZ_OPENAPI_BINDING_NOTIFY_FAILED:
        return NSLocalizedString(@"GIZ_OPENAPI_BINDING_NOTIFY_FAILED", nil);
        case GIZ_OPENAPI_ONLY_SELF_CAN_MODIFY_ALIAS:
        return NSLocalizedString(@"GIZ_OPENAPI_ONLY_SELF_CAN_MODIFY_ALIAS", nil);
        case GIZ_OPENAPI_ONLY_RECEIVER_CAN_MARK_MESSAGE:
        return NSLocalizedString(@"GIZ_OPENAPI_ONLY_RECEIVER_CAN_MARK_MESSAGE", nil);
        case GIZ_OPENAPI_RESERVED:
        return NSLocalizedString(@"GIZ_OPENAPI_RESERVED", nil);
        case GIZ_OPENAPI_APPID_PK_NOT_RELATION:
        return NSLocalizedString(@"GIZ_OPENAPI_APPID_PK_NOT_RELATION", nil);
        case GIZ_OPENAPI_CALL_INNER_FAILED:
        return NSLocalizedString(@"GIZ_OPENAPI_CALL_INNER_FAILED", nil);
        case GIZ_OPENAPI_DEVICE_SHARING_NOT_ENABLED:
        return NSLocalizedString(@"GIZ_OPENAPI_DEVICE_SHARING_NOT_ENABLED", nil);
        case GIZ_OPENAPI_NOT_FIRST_USER_OF_DEVICE:
        return NSLocalizedString(@"GIZ_OPENAPI_NOT_FIRST_USER_OF_DEVICE", nil);
        case GIZ_OPENAPI_PRODUCT_KEY_AUTHEN_FAULT:
        return NSLocalizedString(@"GIZ_OPENAPI_PRODUCT_KEY_AUTHEN_FAULT", nil);
        case GIZ_OPENAPI_BUSY_NOW:
        return NSLocalizedString(@"GIZ_OPENAPI_BUSY_NOW", nil);
        case GIZ_OPENAPI_TWITTER_CONSUMER_KEY_INVALID:
        return NSLocalizedString(@"GIZ_OPENAPI_TWITTER_CONSUMER_KEY_INVALID", nil);
        //        case GIZ_OPENAPI_CODE_NOT_EXIST:
        //            return NSLocalizedString(@"GIZ_OPENAPI_CODE_NOT_EXIST", nil);
        //        case GIZ_OPENAPI_EMAIL_NOT_ACTIVE:
        //            return NSLocalizedString(@"GIZ_OPENAPI_EMAIL_NOT_ACTIVE", nil);
        //        case GIZ_OPENAPI_EMAIL_NOT_ENABLE:
        //            return NSLocalizedString(@"GIZ_OPENAPI_EMAIL_NOT_ENABLE", nil);
        //        case GIZ_OPENAPI_DEVICE_REGISTER_NOT_FOUND:
        //            return NSLocalizedString(@"GIZ_OPENAPI_DEVICE_REGISTER_NOT_FOUND", nil);
        case GIZ_OPENAPI_GUEST_NOT_BIND:
        return NSLocalizedString(@"GIZ_OPENAPI_GUEST_NOT_BIND", nil);
        case GIZ_OPENAPI_CANNOT_TRANSFER_OWNER_TO_SELF:
        return NSLocalizedString(@"GIZ_OPENAPI_CANNOT_TRANSFER_OWNER_TO_SELF", nil);
        case GIZ_OPENAPI_TRANSFER_OWNER_TO_LIMIT_GUEST:
        return NSLocalizedString(@"GIZ_OPENAPI_TRANSFER_OWNER_TO_LIMIT_GUEST", nil);
        case GIZ_PUSHAPI_BODY_JSON_INVALID:
        return NSLocalizedString(@"GIZ_PUSHAPI_BODY_JSON_INVALID", nil);
        case GIZ_PUSHAPI_DATA_NOT_EXIST:
        return NSLocalizedString(@"GIZ_PUSHAPI_DATA_NOT_EXIST", nil);
        case GIZ_PUSHAPI_NO_CLIENT_CONFIG:
        return NSLocalizedString(@"GIZ_PUSHAPI_NO_CLIENT_CONFIG", nil);
        case GIZ_PUSHAPI_NO_SERVER_DATA:
        return NSLocalizedString(@"GIZ_PUSHAPI_NO_SERVER_DATA", nil);
        case GIZ_PUSHAPI_GIZWITS_APPID_EXIST:
        return NSLocalizedString(@"GIZ_PUSHAPI_GIZWITS_APPID_EXIST", nil);
        case GIZ_PUSHAPI_PARAM_ERROR:
        return NSLocalizedString(@"GIZ_PUSHAPI_PARAM_ERROR", nil);
        case GIZ_PUSHAPI_AUTH_KEY_INVALID:
        return NSLocalizedString(@"GIZ_PUSHAPI_AUTH_KEY_INVALID", nil);
        case GIZ_PUSHAPI_APPID_OR_TOKEN_ERROR:
        return NSLocalizedString(@"GIZ_PUSHAPI_APPID_OR_TOKEN_ERROR", nil);
        case GIZ_PUSHAPI_TYPE_PARAM_ERROR:
        return NSLocalizedString(@"GIZ_PUSHAPI_TYPE_PARAM_ERROR", nil);
        case GIZ_PUSHAPI_ID_PARAM_ERROR:
        return NSLocalizedString(@"GIZ_PUSHAPI_ID_PARAM_ERROR", nil);
        case GIZ_PUSHAPI_APPKEY_SECRETKEY_INVALID:
        return NSLocalizedString(@"GIZ_PUSHAPI_APPKEY_SECRETKEY_INVALID", nil);
        case GIZ_PUSHAPI_CHANNELID_ERROR_INVALID:
        return NSLocalizedString(@"GIZ_PUSHAPI_CHANNELID_ERROR_INVALID", nil);
        case GIZ_PUSHAPI_PUSH_ERROR:
        return NSLocalizedString(@"GIZ_PUSHAPI_PUSH_ERROR", nil);
        case GIZ_OPENAPI_ALTER_PASSWORD_FAILED:
        return NSLocalizedString(@"GIZ_OPENAPI_ALTER_PASSWORD_FAILED", nil);
        case GIZ_OPENAPI_NOT_ALLOW_WEEK_PASSWORD:
        return NSLocalizedString(@"GIZ_OPENAPI_NOT_ALLOW_WEEK_PASSWORD", nil);
        default:
        return NSLocalizedString(@"UNKNOWN_ERROR", nil);
    }
}
    
+ (NSString *)currentSSID { //iphone上的ssid名
    NSArray *interfaces = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
    for (NSString *interface in interfaces) {
        NSDictionary *ssidInfo = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)interface);
        NSString *ssid = ssidInfo[(__bridge_transfer NSString *)kCNNetworkInfoKeySSID];
        if (ssid.length > 0) {
            return ssid;
        }
    }
    return @"";
}
    
+ (BOOL)appLogInit:(int)logLevel { //日志初始化
    NSURL *documentsDictoryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    [[NSFileManager defaultManager] createDirectoryAtPath:documentsDictoryURL.path withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSDictionary *sysInfo = @{@"phone_id": getPhoneId(),
                              @"os": @"iOS",
                              @"os_ver": [[UIDevice currentDevice] systemVersion],
                              @"app_version": XcodeAppVersion,
                              @"phone_model": getCurrentDeviceModel()};
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:sysInfo options:0 error:nil];
    NSString *strSysInfo = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    int ret = GizLogInit(strSysInfo.UTF8String, [documentsDictoryURL.path stringByAppendingString:@"/"].UTF8String, logLevel);
    if (0 != ret) {
        GIZ_LOG_ERROR("failed, errorCode: %i", ret);
    }
    return (ret == 0);
}
    
+ (BOOL)isChinese { //当前环境是否为中文
    NSString *language = [NSLocale preferredLanguages].firstObject;
    if ([language hasPrefix:@"zh-Hans"]) { //兼容iOS8
        return YES;
    }
    return NO;
}
    
        
- (BOOL)isSpecialBundleID {
    NSString *bundleID = XcodeAppBundle;
    GIZ_LOG_DEBUG("XcodeAppBundle = %s", bundleID.UTF8String);
    return [bundleID isEqualToString:@"com.xtremeprog.WiFiDemo"] || [bundleID isEqualToString:@"com.xtremeprog.IOEDemo"];
}
    
+ (NSString *)stringLimit:(NSString *)name { //限制16个字符，场景、分组等地方通用
    const char *ostr = name.UTF8String;
    int len = (int)strlen(ostr);
    char *str = malloc(len+1);
    strcpy(str, ostr);
    int nAscii = 0, nOther = 0;
    static int maxCount = 16;
    for (int i=0; i<len; i++) {
        Byte c = str[i];
        if (c < 0x80) {
            nAscii++;
            if (nAscii+nOther*2 > maxCount) {
                str[i] = 0;
                break;
            }
            continue;
        }
        if ((c & 0xE0) == 0xC0) {  //110xxxxx
            nOther++;
            if (nAscii+nOther*2 > maxCount) {
                str[i] = 0;
                break;
            }
            i+=1;
        } else if ((c & 0xF0) == 0xE0) { //1110xxxx
            nOther++;
            if (nAscii+nOther*2 > maxCount) {
                str[i] = 0;
                break;
            }
            i+=2;
        } else if ((c & 0xF8) == 0xF0) { //11110xxx
            nOther++;
            if (nAscii+nOther*2 > maxCount) {
                str[i] = 0;
                break;
            }
            i+=3;
        } else if ((c & 0xFC) == 0xF8) { //111110xx
            nOther++;
            if (nAscii+nOther*2 > maxCount) {
                str[i] = 0;
                break;
            }
            i+=4;
        } else if ((c & 0xFE) == 0xFC) { //1111110x
            nOther++;
            if (nAscii+nOther*2 > maxCount) {
                str[i] = 0;
                break;
            }
            i+=5;
        }
    }
    NSInteger count = nAscii+nOther*2;
    if (count > 12) {
        NSString *newStr = [NSString stringWithUTF8String:str];
        free(str);
        return newStr;
    }
    free(str);
    return name;
}
    
+ (void)updateButtonStyle:(UIButton *)button { //按钮文字有外圈的通用样式
    //    button.backgroundColor = common.buttonColor;
    //    [button setTitleColor:common.buttonTextColor forState:UIControlStateNormal];
    button.backgroundColor = common.backgroundColor;
    [button setTitleColor:common.contrastColor forState:UIControlStateNormal];
    [button.layer setCornerRadius:22.0];
}
    
- (UIColor *)colorWithString:(NSString *)str defaultValue:(UIColor *)color { //xxxxxx转颜色对象
    if (nil == str) {
        return color;
    }
    NSScanner *scanner = [[NSScanner alloc] initWithString:str];
    uint value;
    if ([scanner scanHexInt:&value]) {
        return [UIColor colorWithRed:(((value & 0xFF0000) >> 16))/255.0 green:(((value &0xFF00) >>8))/255.0 blue:((value &0xFF))/255.0 alpha:1.0];
    }
    return color;
}
    
+ (UIColor *)colorWithHexString:(NSString *)hexString { //#xxxxxx转颜色对象
    if (hexString.length == 7) {
        NSString *firstValue = [hexString substringToIndex:1];
        if ([firstValue isEqualToString:@"#"]) {
            return [[GosCommon sharedInstance] colorWithString:[hexString substringFromIndex:1] defaultValue:nil];
        }
    }
    return nil;
}
    
+ (NSString *)productSecretFromDevice:(GizWifiDevice *)device { //通过device对象中的productKey获取productSecret
    for (NSDictionary *productDict in common.productInfo) {
        if ([productDict isKindOfClass:[NSDictionary class]]) {
            NSString *productKey = [productDict stringValueForKey:@"productKey" defaultValue:nil];
            if ([productKey isEqualToString:device.productKey]) {
                return [productDict stringValueForKey:@"productSecret" defaultValue:nil];
            }
        }
    }
    return nil;
}
    
+ (BOOL)canEnterProductSecret:(GizWifiDevice *)device { //是否需要productSecret弹框
    if (device.productType == GizDeviceSub && !device.isBind && device.did.length != 0 && device.netStatus == GizDeviceOnline) {
        NSArray *productInfo = common.productInfo;
        NSString *productSecret = nil;
        for (NSDictionary *productDict in productInfo) {
            NSString *productKey = [productDict stringValueForKey:@"productKey" defaultValue:nil];
            if ([productKey isEqualToString:device.productKey]) {
                productSecret = [productDict stringValueForKey:@"productSecret" defaultValue:nil];
                break;
            }
        }
        if (productSecret.length != 32) {
            return YES;
        }
    }
    return NO;
}
    
+ (NSString *)dataPointFromProductKey:(NSString *)productKey { //通过productKey获取dataPoint
    for (NSDictionary *dict in common.usingPowerOnShortcutButton) {
        if ([dict isKindOfClass:[NSDictionary class]]) {
            NSString *dictProductKey = [dict stringValueForKey:@"productKey" defaultValue:nil];
            NSString *dataPoint = [dict stringValueForKey:@"dataPointID" defaultValue:nil];
            if ([productKey isEqualToString:dictProductKey] && dataPoint.length > 0) {
                return dataPoint;
            }
        }
    }
    return nil;
}
    
#pragma mark - 弹框的简单封装
+ (UIAlertController *)showAlertWithTip:(NSString *)message { //默认title为tip的情况
    NSString *title = NSLocalizedString(@"tip", nil);
    NSString *confirm = NSLocalizedString(@"OK", nil);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:confirm style:UIAlertActionStyleCancel handler:nil]];
    [alertController show];
    return alertController;
}
    
+ (UIAlertController *)showAlert:(NSString *)title message:(NSString *)message {
    NSString *confirm = NSLocalizedString(@"OK", nil);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:confirm style:UIAlertActionStyleCancel handler:nil]];
    [alertController show];
    return alertController;
}
    
+ (void)showAlertAutoDisappear:(NSString *)message { //默认2.0s后自动隐藏弹框
    [self showAlertAutoDisappear:message completion:nil];
}
    
+ (void)showAlertAutoDisappear:(NSString *)message completion:(void (^)(void))completion { //自动隐藏弹框后可选有完成事件
    __block UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertController show];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [alertController dismissViewControllerAnimated:YES completion:completion];
        alertController = nil;
    });
}
    
#pragma mark - 子设备订阅设备可选的弹框
+ (void)enterProductSecret:(void (^)(NSString *text))handler controller:(UIViewController *)controller {
    NSString *strTitle = NSLocalizedString(@"Please enter product secret to bind device", nil);
    NSString *strMsg = NSLocalizedString(@"Please enter 32 length of the Product Secret", nil);
    __block UIAlertController *alertCtrl = [UIAlertController alertControllerWithTitle:strTitle message:strMsg preferredStyle:UIAlertControllerStyleAlert];
    [alertCtrl addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
#if DEBUG
        textField.text = @"c92f498b40d04b3d9c94088a0cf8c291";
#endif
    }];
    [alertCtrl addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
    [alertCtrl addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (handler) {
            NSString *text = alertCtrl.textFields.firstObject.text;
            if (text == nil) {
                text = @"";
            }
            if (text.length != 32) {
                [GosCommon showAlertWithTip:NSLocalizedString(@"The product secret is incorrect，please try again", nil)];
            } else {
                handler(text);
            }
        }
    }]];
    [controller presentViewController:alertCtrl animated:YES completion:nil];
}
    
#pragma mark - 转圈控件的显示、查找、隐藏
+ (void)showHUDAddedTo:(UIView *)view animated:(BOOL)animated {
    if (view) {
        MBProgressHUD *hud = [MBProgressHUD HUDForView:view];
        if (!animated || hud.alpha == 0) {
            [MBProgressHUD showHUDAddedTo:view animated:animated];
        }
    }
}
    
+ (MBProgressHUD *)findHUDForView:(UIView *)view tag:(NSInteger)tag {
    NSEnumerator *subviewsEnum = [view.subviews reverseObjectEnumerator];
    for (UIView *subview in subviewsEnum) {
        if ([subview isKindOfClass:[MBProgressHUD class]] && subview.tag == tag) {
            return (MBProgressHUD *)subview;
        }
    }
    return nil;
}
    
+ (void)showHUDAddedTo:(UIView *)view tips:(NSString *)tips tag:(NSInteger)tag animated:(BOOL)animated {
    if (![self findHUDForView:view tag:tag]) {
        MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
        hud.tag = tag;
        hud.label.text = tips;
        hud.label.adjustsFontSizeToFitWidth = YES;
        hud.label.minimumScaleFactor = 0.3;
        hud.removeFromSuperViewOnHide = YES;
        [view addSubview:hud];
        [hud showAnimated:YES];
    }
}
    
+ (void)showHUDWithImage:(UIImage *)image text:(NSString *)text {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.mode = MBProgressHUDModeCustomView;
    hud.customView = [[UIImageView alloc] initWithImage:image];
    hud.color = [UIColor blackColor];
    hud.detailsLabel.text = text;
    hud.detailsLabel.textColor = [UIColor whiteColor];
    hud.removeFromSuperViewOnHide = YES;
    [hud hideAnimated:YES afterDelay:2];
}
    
+ (void)hideHUDForView:(UIView *)view tag:(NSInteger)tag {
    MBProgressHUD *hud = [self findHUDForView:view tag:tag];
    if (hud != nil) {
        hud.removeFromSuperViewOnHide = YES;
        [hud hideAnimated:YES];
    }
}
    
#pragma mark - App Info
- (BOOL)setApplicationInfo:(NSDictionary *)info { //相当于调用启动接口
    if ([info isKindOfClass:[NSDictionary class]]) { //有在独立部署设置中设置过的情况
        NSString *appid = [info stringValueForKey:@"APPID" defaultValue:APP_ID];
        NSString *appSecret = [info stringValueForKey:@"APPSECRET" defaultValue:APP_SECRET];
        NSArray *productInfo = [info arrayValueForKey:@"productInfo" defaultValue:nil];
        NSDictionary *cloudServiceInfo;
        if (!self.isSetDeploymentDomain) {
            //独立部署没有域名设置的情况下，使用json设置的域名
            cloudServiceInfo = common.cloudDomainDict;
        }
        else {
            cloudServiceInfo = [info dictValueForKey:@"cloudServiceInfo" defaultValue:nil];
        }
        if (info && (32 != appid.length || 32 != appSecret.length)) {
            return NO;
        }
        
        [GizWifiSDK startWithAppInfo:@{@"appId": appid, @"appSecret": appSecret} productInfo:productInfo cloudServiceInfo:cloudServiceInfo autoSetDeviceDomain:NO];
        [[NSUserDefaults standardUserDefaults] setValue:info forKey:@"appInfo"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    } else {
        [GizWifiSDK startWithAppInfo:@{@"appId": APP_ID, @"appSecret": APP_SECRET} productInfo:common.productInfo cloudServiceInfo:common.cloudDomainDict autoSetDeviceDomain:NO];
    }
    return YES;
}
    
- (NSDictionary *)getApplicationInfo { //获取应用信息
    return [[NSUserDefaults standardUserDefaults] valueForKey:@"appInfo"];
}
    
- (NSString *)getAppSecret { //获取appSecret
    NSDictionary *ret = [[NSUserDefaults standardUserDefaults] valueForKey:@"appInfo"];
    if (!ret) {
        return APP_SECRET;
    }
    NSString *appSecret = ret[@"APPSECRET"];
    if (appSecret.length != 32) {
        return APP_SECRET;
    }
    return appSecret;
}
    
#pragma mark - 设备分享
+ (NSDateFormatter *)sharedFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
    });
    return dateFormatter;
}
    
+ (NSDate *)serviceDateFromString:(NSString *)dateStr { //设备分享的时间转换函数
    NSDateFormatter *dateFormatter = [self sharedFormatter];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSString *time = [dateStr stringByReplacingOccurrencesOfString:@"T" withString:@" "];
    time = [time stringByReplacingOccurrencesOfString:@"Z" withString:@""];
    return [dateFormatter dateFromString:time];
}
    
+ (NSString *)localDateStringFromDate:(NSDate *)date { //转换为本地时间
    NSDateFormatter *dateFormatter = [self sharedFormatter];
    dateFormatter.timeZone = [NSTimeZone localTimeZone];
    return [dateFormatter stringFromDate:date];
}
    
#pragma mark - 控制器
+ (BOOL)hasViewController:(UIViewController *)controller controllers:(NSArray <UIViewController *>*)controllers { //数组内是否包含指定的控制器
    for (UIViewController *old_controller in controllers) {
        if (controller == old_controller) {
            return YES;
        }
    }
    return NO;
}
    
+ (UIViewController *)firstViewControllerFromClass:(UINavigationController *)navCtrl class:(Class)cls { //通过类，查找第一个符合条件的控制器
    for (UIViewController *controller in navCtrl.viewControllers) {
        if ([controller isKindOfClass:cls]) {
            return controller;
        }
    }
    return nil;
}
    
+ (void)safePushViewController:(UINavigationController *)navCtrl viewController:(UIViewController *)controller animated:(BOOL)animated { //导航压入视图控制器
    if ([self hasViewController:controller controllers:navCtrl.viewControllers]) {
        return;
    }
    if ([NSThread currentThread].isMainThread) {
        [navCtrl pushViewController:controller animated:animated];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self safePushViewController:navCtrl viewController:controller animated:animated];
        });
    }
}
    
+ (void)safePopViewController:(UINavigationController *)navCtrl currentViewController:(UIViewController *)controller animated:(BOOL)animated { //导航弹出控制器
    if ([NSThread currentThread].isMainThread) {
        if (navCtrl.viewControllers.lastObject == controller) {
            [navCtrl popViewControllerAnimated:animated];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self safePopViewController:navCtrl currentViewController:controller animated:animated];
        });
    }
}
    
+ (void)safePopToViewController:(UINavigationController *)navCtrl viewController:(UIViewController *)controller animated:(BOOL)animated { //导航弹出到指定的控制器
    if (![self hasViewController:controller controllers:navCtrl.viewControllers]) {
        return;
    }
    if ([NSThread currentThread].isMainThread) {
        [navCtrl popToViewController:controller animated:animated];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self safePopToViewController:navCtrl viewController:controller animated:animated];
        });
    }
}
    
+ (void)safePopToRootViewController:(UINavigationController *)navCtrl animated:(BOOL)animated { //退回根控制器
    if (navCtrl.viewControllers.count <= 1) {
        return;
    }
    if ([NSThread currentThread].isMainThread) {
        [navCtrl popToRootViewControllerAnimated:animated];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self safePopToRootViewController:navCtrl animated:animated];
        });
    }
}
    
+ (void)safePopToDeviceList:(UINavigationController *)navCtrl { //退回设备列表
    if ([NSThread currentThread].isMainThread) {
        UIViewController *listCtrl = nil;
        for (UIViewController *viewController in navCtrl.viewControllers) {
            NSString *strClass = NSStringFromClass([viewController class]);
            if ([strClass isEqualToString:@"GosDeviceListViewController"] || [strClass isEqualToString:@"UITabBarController"]) {
                listCtrl = viewController;
                break;
            }
        }
        if (listCtrl != nil && navCtrl.viewControllers.lastObject != listCtrl) {
            [navCtrl popToViewController:listCtrl animated:YES];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self safePopToDeviceList:navCtrl];
        });
    }
}
    
#pragma mark - 列表项（Cell）
+ (id)controllerWithClass:(Class)cls tableView:(UITableView *)tableView reuseIdentifier:(NSString *)reuseIdentifier {
    if ([cls isSubclassOfClass:[UITableViewCell class]]) {
        id cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        if (nil == cell) {
            UINib *nib = [UINib nibWithNibName:NSStringFromClass(cls) bundle:nil];
            [tableView registerNib:nib forCellReuseIdentifier:reuseIdentifier];
            return [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
        }
        return cell;
    }
    return nil;
}
    
    //增加消息分享cell右上角小圆点
+ (void)markTableViewCell:(UITableViewCell *)cell label:(UILabel *)label hasUnreadMessage:(BOOL)hasUnreadMessage {
    for (UIView *view in cell.contentView.subviews) {
        if ([view isMemberOfClass:[UIImageView class]]) {
            [view removeFromSuperview];
        }
    }
    if (hasUnreadMessage) {
        CGSize fontSize = [label.text sizeWithAttributes:@{NSFontAttributeName: label.font}];
        CGRect realFrame = label.frame;
        CGFloat scale = 0.5f*label.contentScaleFactor;
        realFrame.size.width = realFrame.size.width * scale;
        
        if (fontSize.width > realFrame.size.width && realFrame.size.width != 0) {
            fontSize.width = realFrame.size.width;
        }
        
        UIGraphicsBeginImageContext(CGSizeMake(21, 21));
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetRGBFillColor(context, 1, 0, 0, 1);
        CGContextAddArc(context, 10, 10, 9, 0, 2*M_PI, 0);
        CGContextDrawPath(context, kCGPathFill);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        
        CGFloat left = fontSize.width+realFrame.origin.x+5;
        CGFloat top = realFrame.origin.y+(realFrame.size.height-label.font.pointSize)/2;
        if (realFrame.size.width != 0) {
            UIImageView *customView = [[UIImageView alloc] initWithFrame:CGRectMake(left, top, 7, 7)];
            customView.image = image;
            [cell.contentView addSubview:customView];
        }
    }
}
    
#pragma mark - 列表
+ (CGFloat)tableHeaderHeight:(UITableView *)tableView text:(NSString *)text offset:(CGFloat)offset {
    return [text boundingRectWithSize:CGSizeMake(tableView.frame.size.width-20, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]} context:nil].size.height+8+offset;
}
    
+ (UIView *)tableHeaderView:(UITableView *)tableView text:(NSString *)text offset:(CGFloat)offset {
    UIView *view = [[UIView alloc] init];
    CGFloat textHeight = [text boundingRectWithSize:CGSizeMake(tableView.frame.size.width-20, 100) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14]} context:nil].size.height+4;
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, tableView.bounds.size.width-20, textHeight)];
    headerLabel.numberOfLines = 10;
    CGRect frame = headerLabel.frame;
    frame.origin.y = offset;
    headerLabel.frame = frame;
    headerLabel.textColor = [UIColor grayColor];
    headerLabel.font = [UIFont systemFontOfSize:14];
    [view addSubview:headerLabel];
    headerLabel.text = text;
    return view;
}
    
#pragma mark - 场景
    /**
     数据结构：
     [{"title": xxx,
     "image": xxx,
     "scene": xxx},
     {"scene": xxx}]
     * 有title、image的情况为预设
     * 只有scene为非预设
     */
+ (NSArray *)sceneItemsWithDevice:(GizWifiCentralControlDevice *)centralDevice {
    NSString *key = [NSString stringWithFormat:@"scene_%@%@%@", centralDevice.macAddress, centralDevice.did, centralDevice.productKey];
    NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (nil == array) {
        array = @[@{@"title": @{@"cn": @"回家", @"en": @"Back home"}, @"image": @"scene_backhome_icon.png"},
                  @{@"title": @{@"cn": @"离家", @"en": @"Leave home"}, @"image": @"scene_leavehome_icon.png"},
                  @{@"title": @{@"cn": @"起床", @"en": @"Wake up"}, @"image": @"scene_getup_icon.png"},
                  @{@"title": @{@"cn": @"睡眠", @"en": @"Sleep"}, @"image": @"scene_sleep_icon.png"}];
        [[NSUserDefaults standardUserDefaults] setValue:array forKey:key];
    }
    NSArray *sceneObjects = [GizDeviceSceneCenter getSceneListGateway:centralDevice];
    NSMutableArray *mObjects = [sceneObjects mutableCopy];
    NSMutableArray *ret = [NSMutableArray array];
    for (NSDictionary *dict in array) { //预设
        NSString *sceneID = [dict stringValueForKey:@"sceneID" defaultValue:nil];
        NSDictionary *titleDict = [dict dictValueForKey:@"title" defaultValue:nil];
        NSString *sceneNameCN = [titleDict stringValueForKey:@"cn" defaultValue:nil];
        NSString *sceneNameEN = [titleDict stringValueForKey:@"en" defaultValue:nil];
        GizDeviceScene *existScene = nil;
        for (GizDeviceScene *sceneObject in sceneObjects) {
            if ([sceneObject isKindOfClass:[GizDeviceScene class]]) {
                BOOL isSceneIDEqual = [sceneObject.sceneID isEqualToString:sceneID];
                BOOL isPresetTitleEqual = titleDict && ([sceneObject.sceneName isEqualToString:sceneNameCN] || [sceneObject.sceneName isEqualToString:sceneNameEN]);
                if (isSceneIDEqual || isPresetTitleEqual) {
                    existScene = sceneObject;
                    [mObjects removeObject:sceneObject];
                    break;
                }
            }
        }
        if (existScene) {
            NSMutableDictionary *mdict = [dict mutableCopy];
            [mdict setValue:existScene forKey:@"scene"];
            [mdict setValue:nil forKey:@"sceneID"];
            [ret addObject:[mdict copy]];
        } else if (titleDict) {
            [ret addObject:dict];
        }
    }
    for (GizDeviceScene *sceneObject in mObjects) { //非预设
        if ([sceneObject isKindOfClass:[GizDeviceScene class]]) {
            [ret addObject:@{@"scene": sceneObject}];
        }
    }
    return ret;
}
    
+ (void)setSceneItemsWithDevice:(GizWifiCentralControlDevice *)centralDevice sceneItems:(NSArray *)sceneItems {
    NSString *key = [NSString stringWithFormat:@"scene_%@%@%@", centralDevice.macAddress, centralDevice.did, centralDevice.productKey];
    if (nil == sceneItems) {
        GIZ_LOG_DEBUG("sceneItems is nil, ignored.");
        return;
    } else {
        NSMutableArray *mArray = [NSMutableArray array];
        for (NSDictionary *dict in sceneItems) {
            if ([dict isKindOfClass:[NSDictionary class]]) {
                NSDictionary *titleDict = [dict dictValueForKey:@"title" defaultValue:nil];
                NSString *image = [dict stringValueForKey:@"image" defaultValue:nil];
                if (titleDict && image) {
                    GizDeviceScene *scene = dict[@"scene"];
                    NSString *sceneID = nil;
                    if ([scene isKindOfClass:[GizDeviceScene class]]) {
                        sceneID = scene.sceneID;
                    }
                    if (sceneID) {
                        [mArray addObject:@{@"title": titleDict, @"image": image, @"sceneID": sceneID}];
                    } else {
                        [mArray addObject:@{@"title": titleDict, @"image": image}];
                    }
                } else {
                    GizDeviceScene *scene = dict[@"scene"];
                    NSString *sceneID = nil;
                    if ([scene isKindOfClass:[GizDeviceScene class]]) {
                        sceneID = scene.sceneID;
                    }
                    if (sceneID) {
                        [mArray addObject:@{@"sceneID": sceneID}];
                    }
                }
            }
        }
        if (mArray.count == 0) {
            GIZ_LOG_DEBUG("array is empty, ignored. sceneItems: %s", sceneItems.description.UTF8String);
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:mArray forKey:key];
        }
    }
}
    
+ (void)updateScenePresetInfo:(NSString *)oldSceneImage centralDevice:(GizWifiCentralControlDevice *)centralDevice newSceneName:(NSString *)newSceneName sceneList:(NSArray *)sceneList {
    NSString *key = [NSString stringWithFormat:@"scene_%@%@%@", centralDevice.macAddress, centralDevice.did, centralDevice.productKey];
    NSArray *array = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    for (NSDictionary *dict in array) {
        NSString *image = [dict valueForKey:@"image"];
        if ([image isEqualToString:oldSceneImage]) { //不用替换预设项目的title值
            NSMutableDictionary *mdict = [dict mutableCopy];
            NSMutableArray *mArray = [array mutableCopy];
            NSString *sceneID = [mdict stringValueForKey:@"sceneID" defaultValue:nil];
            NSInteger index = [array indexOfObject:dict];
            if (sceneID.length == 0 && sceneList) {
                for (GizDeviceScene *scene in sceneList) {
                    if ([scene isKindOfClass:[GizDeviceScene class]] &&
                        [scene.sceneName isEqualToString:newSceneName]) {
                        [mdict setValue:scene.sceneID forKey:@"sceneID"];
                        break;
                    }
                }
            }
            [mArray replaceObjectAtIndex:index withObject:mdict];
            if (mArray.count == 0) {
                GIZ_LOG_DEBUG("array is empty, ignored. sceneList: %s", sceneList.description.UTF8String);
            } else {
                [[NSUserDefaults standardUserDefaults] setObject:mArray forKey:key];
            }
            break;
        }
    }
}
    
#pragma mark - images
+ (UIImage *)transparentImage:(CGSize)size { //透明图像
    UIGraphicsBeginImageContext(size);
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}
    
+ (UIImage *)tabImage { //自定义的标签图像，底部一条线的那种样式
    UIGraphicsBeginImageContext(CGSizeMake(562, 111));
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, common.backgroundColor.CGColor);
    CGContextFillRect(context, CGRectMake(0, 99, 562, 111));
    UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return ret;
}
    
#pragma mark - 配网信息记录
- (void)setLastConfigType:(NSArray *)lastConfigType {
    [[NSUserDefaults standardUserDefaults] setValue:lastConfigType forKey:@"CommonLastConfigType"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
    
- (NSArray *)lastConfigType {
    NSArray *type = [[NSUserDefaults standardUserDefaults] valueForKey:@"CommonLastConfigType"];
    if ([type isKindOfClass:[NSArray class]]) {
        return type;
    }
    return nil;
}
    
#pragma mark - 中能定制
- (GizDeviceSharingUserRole)role { //中能定制：根据第一台设备决定用户角色
    GizWifiDevice *device = nil;
    if ([GizWifiSDK sharedInstance].deviceList.count > 0) {
        device = [GizWifiSDK sharedInstance].deviceList.firstObject;
    }
    if (device) {
        return device.sharingRole;
    }
    return -1;
}
    
#pragma mark - 通用控制界面显示名称重置
    /**
     根据JSON配置给定的产品数据点显示名称
     
     @param productKey 将显示设备的PK
     @param ui 将显示设备的数据点配置UI
     @return 返回设置成新数据点名称的UI
     */
- (NSDictionary *)getControlDeviceUI:(NSString *)productKey ui:(NSDictionary *)ui {
    if (productKey.length != 32) {
        return ui;
    }
    NSDictionary *productInfo = [self hasConfigureInJson:productKey];
    if (!productInfo) {
        return ui;
    }
    NSArray *sections = [ui arrayValueForKey:@"sections" defaultValue:nil];
    if (sections.count == 1) {  // 所有数据点都只在一个组中显示，不会分组
        NSDictionary *section = sections[0];
        NSArray *oldElements = [section arrayValueForKey:@"elements" defaultValue:nil];
        if (oldElements.count == 0) {
            return ui;
        }
        NSMutableArray *newElements = [NSMutableArray arrayWithCapacity:oldElements.count];
        for (NSDictionary *oldElement in oldElements) {
            NSMutableDictionary *newElement = [oldElement mutableCopy];
            NSString *key = [oldElement stringValueForKey:@"key" defaultValue:nil];
            NSArray *arr = [key componentsSeparatedByString:@"."];
            if (arr.count == 2) {
                key = arr[1];  //获取数据点名称
                //获取该key在json中的配置
                NSDictionary *dataPoint = [self getAttrDic:key productInfo:productInfo];
                if (dataPoint) {
                    newElement[@"title"] = [self parseString:dataPoint key:@"name" defaultValue:key];
                }
            }
            [newElements addObject:newElement];
        }
        if (newElements.count > 1) {
            NSMutableDictionary *newUI = [ui mutableCopy];
            NSMutableArray *newSections = [sections mutableCopy];
            newSections[0] = @{@"elements": newElements};
            newUI[@"sections"] = newSections;
            NSLog(@"danly newUI = %@", newUI);
            return [newUI copy];
        }
    }
    return ui;
}
    
    /**
     查看给定PK是否在配置文件设置了显示名称
     
     @param productKey 给定PK
     @return 返回该PK数据点名称的配置，当没有配置该PK时，返回nil
     */
- (NSDictionary *)hasConfigureInJson:(NSString *)productKey {
    if (productKey.length != 32) {
        return nil;
    }
    for (NSDictionary *productConfig in _deviceInfo) {
        NSString *pk = [productConfig stringValueForKey:@"productKey" defaultValue:nil];
        if (pk && [pk isEqualToString:productKey]) {
            return [productConfig copy];
        }
    }
    return nil;
}
    
    
    /**
     获取给定数据点名称的数据点配置字典
     
     @param key 给定数据点名称
     @param productInfo 该产品的配置字典:appConfig中配置的
     @return 配置指定中指定数据点的配置， 没有指定数据点配置时，返回nil
     */
- (NSDictionary *)getAttrDic:(NSString *)key productInfo:(NSDictionary *)productInfo {
    if (key.length == 0) {
        return nil;
    }
    NSArray *dataPoints = [productInfo arrayValueForKey:@"dataPoint" defaultValue:nil];
    for (NSDictionary *dataPoint in dataPoints) {
        NSString *ID = [dataPoint stringValueForKey:@"id" defaultValue:nil];
        if ([ID isEqualToString:key]) {
            return [dataPoint copy];
        }
    }
    return nil;
}
    
- (NSString *)deviceName:(GizWifiDevice *)device {
    if (device.alias.length > 0) {
        return device.alias;
    }
    NSDictionary *jsonConfig = [self hasConfigureInJson:device.productKey];
    NSString *productName = [self parseString:jsonConfig key:@"productName" defaultValue:device.productName];
    return productName;
}
    
    @end
