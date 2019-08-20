//
//  GosWebController.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2017/7/3.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import "GosWebController.h"
#import "GosCommon.h"

@interface GosWebController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) NSString *localFile;

@end

@implementation GosWebController

- (id)initWithLocalFile:(NSString *)localFile {
    self = [super init];
    if (self) {
        self.localFile = localFile;
    }
    return self;
}

+ (id)controllerWithLocalFile:(NSString *)localPath {
    return [[GosWebController alloc] initWithLocalFile:localPath];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    NSURL *url = [NSURL fileURLWithPath:self.localFile];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"page_back_button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onBack)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)onBack {
    [GosCommon safePopViewController:self.navigationController currentViewController:self animated:YES];
}

@end
