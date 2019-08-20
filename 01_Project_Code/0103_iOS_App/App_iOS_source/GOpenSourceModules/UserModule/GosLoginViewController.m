//
//  LoginViewController.m
//  GBOSA
//
//  Created by Zono on 16/3/22.
//  Copyright © 2016年 Gizwits. All rights reserved.
//

#import "GosLoginViewController.h"
#import "AppDelegate.h"
#import <GizWifiSDK/GizWifiSDK.h>

#import <TencentOpenAPI/TencentOAuth.h>
#import <TencentOpenAPI/TencentApiInterface.h>
#import "WXApi.h"

#import "GosPushManager.h"
#import "GosAnonymousLogin.h"
#import "GosMessageCenterTableViewController.h"
#import "GosPersonalCenterTableViewController.h"


#define APPDELEGATE ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface GosLoginViewController () <TencentSessionDelegate, WXApiDelegate>

@property (assign, nonatomic) CGFloat top;

@property (strong, nonatomic) TencentOAuth *tencentOAuth;
@property (strong, nonatomic) UIButton *loginQQBtn;

@property (weak, nonatomic) IBOutlet UITextField *textUser;
@property (weak, nonatomic) IBOutlet UITextField *textPassword;
@property (weak, nonatomic) IBOutlet UIView *loginBtnsBar;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;
@property (weak, nonatomic) IBOutlet UIButton *forgetBtn;
@property (weak, nonatomic) IBOutlet UIButton *signupBtn;
@property (weak, nonatomic) IBOutlet UIButton *skipBtn;

@property (strong, nonatomic) UIButton *loginWechatBtn;

@end

@implementation GosLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [GosCommon updateButtonStyle:self.loginBtn];
    if (!common.isRegisterNormalUser && !common.isRegisterPhoneUser && !common.isRegisterEmailUser) {
        self.signupBtn.hidden = YES;
    }
    if (!common.isForgetPhoneUser && !common.isForgetEmailUser) {
        self.forgetBtn.hidden = YES;
    }
    if (!common.isAnonymous) {
        self.skipBtn.hidden = YES;
    }
    
    [self createThirdLoginButton];
    
    
    if (common.isWechat) {
        //注册微信
        [WXApi registerApp:WECHAT_APP_ID];
    }
    
    
    
    self.automaticallyAdjustsScrollViewInsets = false;
    self.top = self.navigationController.navigationBar.translucent ? 0 : 64;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelInput)];
    [self.view addGestureRecognizer:tapGesture];
    
    // 左边空出8px
    self.textUser.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 8)];
    self.textUser.leftViewMode = UITextFieldViewModeAlways;
    self.textPassword.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 8)];
    self.textPassword.leftViewMode = UITextFieldViewModeAlways;
    
    // 给密码按钮添加显示隐藏按钮
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[UIImage imageNamed:@"password_show.png"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"password_hide.png"] forState:UIControlStateSelected];
    [button addTarget:self action:@selector(onPasswordVisible:) forControlEvents:UIControlEventTouchUpInside];
    button.frame = CGRectMake(0, 0, 64, 44);
    self.textPassword.rightView = button;
    self.textPassword.rightViewMode = UITextFieldViewModeAlways;
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //增加服务器变更监听
    [common addObserver:self forKeyPath:@"unChineseServer" options:NSKeyValueObservingOptionNew context:nil];
    self.navigationController.navigationBarHidden = YES;
    self.textUser.text = common.tmpUser;
    self.textPassword.text = common.tmpPass;
    
    [self showThirdLoginButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoLogin) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [common removeObserver:self forKeyPath:@"unChineseServer"];
    self.navigationController.navigationBarHidden = NO;
    [self cancelInput];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)createThirdLoginButton {
    
    self.loginQQBtn = [self thirdLoginButton:@"user_login_qq.png" title:NSLocalizedString(@"QQ Login", nil)];
    [self.loginQQBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginQQBtnPressed)]];
    
    
    self.loginWechatBtn = [self thirdLoginButton:@"user_login_wechat.png" title:NSLocalizedString(@"Wechat Login", nil)];
    [self.loginWechatBtn addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loginWechatBtnPressed)]];
    
}

- (UIButton *)thirdLoginButton:(NSString *)imageName title:(NSString *)title {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14];
    btn.frame = CGRectMake(0, 20, 90, 30);
    return btn;
}

- (void)showThirdLoginButton {
    NSMutableArray *buttons = [NSMutableArray array];
    
    BOOL isQQ = common.isQQ && !common.unChineseServer;
    if (isQQ) {
        [buttons addObject:self.loginQQBtn];
    }
    
    
    BOOL isWechat = common.isWechat && [WXApi isWXAppInstalled];//微信比较特殊，需要在页面切换、后台切换时检测应用是否存在
    if (isWechat) {
        [buttons addObject:self.loginWechatBtn];
    }
    
    // twitter和facebook只支持iOS9开始的系统
    [self layoutThirdLoginButton:buttons];
}

- (void)layoutThirdLoginButton:(NSArray *)buttons {
    for (NSInteger i = self.loginBtnsBar.subviews.count-1; i>=0; i--) {
        [self.loginBtnsBar.subviews[i] removeFromSuperview];
    }
    if (buttons.count > 0) {
        if (buttons.count == 1) {
            UIButton *button = buttons.firstObject;
            CGRect frame = button.frame;
            frame.origin.x = ([UIScreen mainScreen].bounds.size.width-button.frame.size.width)/2.0;
            button.frame = frame;
            [self.loginBtnsBar addSubview:button];
        } else { //按照多个按钮处理
            CGFloat space = 10;
            UIButton *firstBtn = buttons.firstObject;
            CGFloat btnWidth = firstBtn.frame.size.width;
            CGFloat btnCount = buttons.count;
            CGFloat preBtnX = ([UIScreen mainScreen].bounds.size.width - btnCount * btnWidth - (btnCount - 1) * space)/2.0;
            CGRect firstBtnFrame = firstBtn.frame;
            firstBtnFrame.origin.x = preBtnX;
            firstBtn.frame = firstBtnFrame;
            [self.loginBtnsBar addSubview:firstBtn];
            for (int i = 1; i < btnCount; ++i) {
                //中间的竖线
                UIView *view = [[UIView alloc] initWithFrame:CGRectMake(preBtnX + btnWidth + space * 0.5, 23, 1, 24)];
                view.backgroundColor = [UIColor lightGrayColor];
                [self.loginBtnsBar addSubview:view];
                
                // 下一个按钮
                UIButton *btn = buttons[i];
                preBtnX = preBtnX + btnWidth + space;
                CGRect frame = btn.frame;
                frame.origin.x = preBtnX;
                btn.frame = frame;
                [self.loginBtnsBar addSubview:btn];
            }
        }
    }
}


- (void)autoLogin {
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"username"];
    NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"password"];
    if (![MBProgressHUD HUDForView:self.view] && //上次没有执行登录操作
        username && [username length] > 0 && password && [password length] > 0) {
        [self userLogin:YES];
    }
    [self toDeviceListWithoutLogin:YES]; //跳过自动登录
}

- (void)cancelInput {
    [self.textUser resignFirstResponder];
    [self.textPassword resignFirstResponder];
}

#pragma mark - ThirdLogin

- (void)loginQQBtnPressed {
    if ([TENCENT_APP_ID isEqualToString:@"your_tencent_app_id"] || TENCENT_APP_ID.length == 0) {
        [GosCommon showAlert:nil message:@"请替换 GOpenSourceModules/CommonModule/appConfig.json 中的参数定义为您申请到的QQ登录授权 app id"];
        return;
    }
    //    if (self.textUser.text.length == 0) {
    //        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Please enter username", nil)];
    //    } else if (self.textPassword.text.length == 0) {
    //        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Please enter password", nil)];
    //    }
    common.currentLoginStatus = GizLoginNone;
    NSArray* permissions = [NSArray arrayWithObjects:
                            kOPEN_PERMISSION_GET_USER_INFO,
                            kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                            nil];
    self.tencentOAuth = [[TencentOAuth alloc] initWithAppId:TENCENT_APP_ID andDelegate:self];
    [self.tencentOAuth authorize:permissions inSafari:NO];
}


- (void)loginWechatBtnPressed {
    if ([WECHAT_APP_ID isEqualToString:@"your_wechat_app_id"] || WECHAT_APP_ID.length == 0 || [WECHAT_APP_SECRET isEqualToString:@"your_wechat_app_secret"] || WECHAT_APP_SECRET.length == 0) {
        [GosCommon showAlert:nil message:@"请替换 GOpenSourceModules/CommonModule/appConfig.json 中的参数定义为您申请到的微信登录授权 app id 及 app secret"];
        return;
    }
    if (![WXApi isWXAppInstalled]) {
        [GosCommon showAlertWithTip:NSLocalizedString(@"haven't WeChat Application", nil)];
        return;
    }
    common.currentLoginStatus = GizLoginNone;
    //构造SendAuthReq结构体
    SendAuthReq* req =[[SendAuthReq alloc] init];
    req.scope = @"snsapi_userinfo" ;
    req.state = @"123" ;
    //第三方向微信终端发送一个SendAuthReq消息结构
    [WXApi sendReq:req];
    common.WXApiOnRespHandler = ^(BaseResp *resp) {
        SendAuthResp *aresp = (SendAuthResp *)resp;
        if (aresp.errCode== 0) {
            NSString *code = aresp.code;
            [GosCommon showHUDAddedTo:self.view animated:YES];
            [self getAccessToken:code];
        }
    };
}

- (void)getAccessToken:(NSString *)code {
    NSString *url =[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code",WECHAT_APP_ID,WECHAT_APP_SECRET,code];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *zoneUrl = [NSURL URLWithString:url];
        NSString *zoneStr = [NSString stringWithContentsOfURL:zoneUrl encoding:NSUTF8StringEncoding error:nil];
        NSData *data = [zoneStr dataUsingEncoding:NSUTF8StringEncoding];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                NSString *accessToken = [dic objectForKey:@"access_token"];
                NSString *openId = [dic objectForKey:@"openid"];
                common.isThirdAccount = YES;
                GosWifiSDKMessageCenter.delegate = self;
                [common saveUserDefaults:GizWechatLogin userName:openId password:accessToken tokenSecret:nil uid:nil token:nil];
                [[GizWifiSDK sharedInstance] userLoginWithThirdAccount:GizThirdWeChat uid:openId token:accessToken];
            }
        });
    });
}


#pragma mark - userLogin
- (void)userLogin:(BOOL)automatic {
    common.currentLoginStatus = GizLoginNone;
    NSString *username = nil;
    NSString *password = nil;
    if (automatic) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger loginType = [defaults integerForKey:@"loginType"];
        username = [defaults objectForKey:@"username"];
        password = [defaults objectForKey:@"password"];
        if (username.length > 0 && password.length > 0) {
            switch (loginType) {
                case GizUserNameLogin:
                {
                    [GosCommon showHUDAddedTo:self.view animated:YES];
                    common.isThirdAccount = NO;
                    
                    if (common.isAnonymous) {
                        [GosAnonymousLogin cleanup];
                    }
                    
                    GosWifiSDKMessageCenter.delegate = self;
                    [common saveUserDefaults:GizUserNameLogin userName:username password:password tokenSecret:nil uid:nil token:nil];
                    [[GizWifiSDK sharedInstance] userLogin:username password:password];
                    return;
                }
                    
                case GizQQLogin:
                {
                    [GosCommon showHUDAddedTo:self.view animated:YES];
                    common.isThirdAccount = YES;
                    
                    if (common.isAnonymous) {
                        [GosAnonymousLogin cleanup];
                    }
                    
                    GosWifiSDKMessageCenter.delegate = self;
                    [[GizWifiSDK sharedInstance] userLoginWithThirdAccount:GizThirdQQ uid:username token:password];
                    return;
                }
                    
                    
                case GizWechatLogin:
                {
                    [GosCommon showHUDAddedTo:self.view animated:YES];
                    common.isThirdAccount = YES;
                    
                    if (common.isAnonymous) {
                        [GosAnonymousLogin cleanup];
                    }
                    
                    GosWifiSDKMessageCenter.delegate = self;
                    [[GizWifiSDK sharedInstance] userLoginWithThirdAccount:GizThirdWeChat uid:username token:password];
                    return;
                }
                    
                default:
                    break;
            }
        }
    }
    username = self.textUser.text;
    password = self.textPassword.text;
    if([username isEqualToString:@""]) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Please enter username", nil)];
        return;
    }
    if ([password isEqualToString:@""]) {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Please enter password", nil)];
        return;
    }
    [GosCommon showHUDAddedTo:self.view animated:YES];
    [common saveUserDefaults:GizUserNameLogin userName:username password:password tokenSecret:nil uid:nil token:nil];
    common.isThirdAccount = NO;
    [[GizWifiSDK sharedInstance] userLogin:username password:password];
    GosWifiSDKMessageCenter.delegate = self;
    
    if (common.isAnonymous) {
        [GosAnonymousLogin cleanup];
    }
    
}

- (IBAction)userLoginBtnPressed:(id)sender {
    [self userLogin:NO];
}

- (IBAction)loginSkipBtnPressed:(id)sender {
    [self toDeviceListWithoutLogin:YES];
}

#pragma mark - GizWifiSDKDelegate
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUserLogin:(NSError *)result uid:(NSString *)uid token:(NSString *)token {
    [MBProgressHUD hideHUDForView:self.view animated:!APPDELEGATE.isBackground];
    
    if (common.isAnonymous) {
        GosAnonymousLoginStatus lastStatus = [GosAnonymousLogin lastLoginStatus];
        if (lastStatus == GosAnonymousLoginStatusProcessing ||
            lastStatus == GosAnonymousLoginStatusFailed) {
            return;
        }
    }
    
    if (result.code == GIZ_SDK_SUCCESS) {
        [common saveUserDefaults:GizUnknowLogin userName:nil password:nil tokenSecret:nil uid:uid token:token];
        self.textUser.text = @"";
        self.textPassword.text = @"";
        common.currentLoginStatus = GizLoginUser;
        
        [GosPushManager unbindToGDMS:NO];
        [GosPushManager bindToGDMS];
        
        UIViewController *devListCtrl = [self getDeviceListController];
        [GosCommon safePushViewController:self.navigationController viewController:devListCtrl animated:YES];
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Login successful", nil)];
    } else {
        if (result.code != GIZ_SDK_DNS_FAILED &&
            result.code != GIZ_SDK_CONNECTION_TIMEOUT &&
            result.code != GIZ_SDK_CONNECTION_REFUSED &&
            result.code != GIZ_SDK_CONNECTION_ERROR &&
            result.code != GIZ_SDK_CONNECTION_CLOSED &&
            result.code != GIZ_SDK_SSL_HANDSHAKE_FAILED) {
        }
        [common removeUserDefaults];
        NSString *info = [common checkErrorCode:result.code];
        [GosCommon showAlertAutoDisappear:info];
    }
}


- (void)wifiSDK:(GizWifiSDK *)wifiSDK didChannelIDUnBind:(NSError *)result {
    [GosPushManager didUnbind:result];
}



#pragma mark - TencentDelegate
- (void)tencentDidLogin {
    GIZ_LOG_DEBUG("tencent login successed");
    if (self.tencentOAuth.accessToken && 0 != [self.tencentOAuth.accessToken length]) {
        [GosCommon showHUDAddedTo:self.view animated:YES];
        common.isThirdAccount = YES;
        GosWifiSDKMessageCenter.delegate = self;
        NSString *uid = self.tencentOAuth.openId;
        NSString *token = self.tencentOAuth.accessToken;
        [common saveUserDefaults:GizQQLogin userName:uid password:token tokenSecret:nil uid:nil token:nil];
        [[GizWifiSDK sharedInstance] userLoginWithThirdAccount:GizThirdQQ uid:uid token:token];
    } else {
        GIZ_LOG_DEBUG("tencent login successed, but no accessToken");
    }
}

- (void)tencentDidNotLogin:(BOOL)cancelled {
    
}

- (void)tencentDidNotNetWork {
    [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Login failed, please login again", nil)];
}


#pragma mark - textField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.textUser) {
        [self.textPassword becomeFirstResponder];
    } else {
        [self.textPassword resignFirstResponder];
    }
    return NO;
}

#pragma mark - Event
- (void)onPasswordVisible:(UIButton *)button {
    button.selected = !button.selected;
    self.textPassword.secureTextEntry = !button.selected;
}

- (IBAction)onTap {
    [self.textUser resignFirstResponder];
    [self.textPassword resignFirstResponder];
}

- (IBAction)onRegister:(id)sender {
    if (common.isRegisterEmailUser || common.isRegisterPhoneUser || common.isRegisterNormalUser) {
        [self performSegueWithIdentifier:@"toRegister" sender:nil];
    }
}

- (IBAction)onForget:(id)sender {
    
    if (common.isForgetEmailUser || common.isForgetPhoneUser) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"GosUser" bundle:nil];
        UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"toForget"];
        [GosCommon safePushViewController:self.navigationController viewController:viewController animated:YES];
    }
    
}

- (UIViewController *)getDeviceListController {
    GosDeviceListViewController *devListCtrl = [[GosDeviceListViewController alloc] initWithStyle:UITableViewStyleGrouped];
    devListCtrl.parent = self;
    
    if (true) {
        UITabBarController *tabCtrl =  [[UITabBarController alloc] init];
        tabCtrl.navigationItem.hidesBackButton = YES;
        tabCtrl.tabBar.tintColor = common.contrastColor;
        tabCtrl.tabBar.barTintColor = common.backgroundColor;
        
        GosPersonalCenterTableViewController *personalCtrl = [[GosPersonalCenterTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        
        NSMutableArray *viewControllers = [NSMutableArray array];
        devListCtrl.tabBarItem.title = devListCtrl.navigationItem.title;
        devListCtrl.tabBarItem.image = [UIImage imageNamed:@"tabbar_mydevice.png"];
        [viewControllers addObject:devListCtrl];
        if (common.isMessageCenter) {
            GosMessageCenterTableViewController *messageCtrl = [[GosMessageCenterTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            messageCtrl.tabBarItem.title = NSLocalizedString(@"Messages", nil);
            messageCtrl.tabBarItem.image = [UIImage imageNamed:@"tabbar_messages.png"];
            [viewControllers addObject:messageCtrl];
        }
        personalCtrl.tabBarItem.title = NSLocalizedString(@"Personal Center", nil);
        personalCtrl.tabBarItem.image = [UIImage imageNamed:@"tabbar_personal.png"];
        [viewControllers addObject:personalCtrl];
        
        [tabCtrl setViewControllers:viewControllers animated:YES];
        return tabCtrl;
    }
    
    return devListCtrl;
}

- (void)toDeviceListWithoutLogin:(BOOL)animated {
    UIViewController *devListCtrl = [self getDeviceListController];
    [GosCommon safePushViewController:self.navigationController viewController:devListCtrl animated:YES];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"unChineseServer"]) {
        [self showThirdLoginButton];
    }
    
}

@end
