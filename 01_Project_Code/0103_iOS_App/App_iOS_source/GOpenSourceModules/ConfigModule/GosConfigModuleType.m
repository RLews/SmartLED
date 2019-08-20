//
//  GosConfigModuleType.m
//  GOpenSource_AppKit
//
//  Created by Tom on 2017/6/5.
//  Copyright © 2017年 Gizwits. All rights reserved.
//

#import "GosConfigModuleType.h"
#import "GosCommon.h"
#import <ZipArchive/ZipArchive.h>
#import "GosWebController.h"
#import "GizConfigAirlinkConfirm.h"
#import "GosConfigStart.h"

@interface GosConfigModuleType () <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSArray *modules;
@property (strong, nonatomic) NSMutableArray *selectedIndexs;  // 存放模组类型
@property (weak, nonatomic) IBOutlet UIButton *confirmBtn;

@end

@implementation GosConfigModuleType

- (void)viewDidLoad {
    [super viewDidLoad];
    [GosCommon updateButtonStyle:self.confirmBtn];
    
//    NSArray *lastType = common.lastConfigType;
//    NSMutableArray *arr = [NSMutableArray array];
//    if (lastType.count > 0) {
//        for (NSNumber *selectType in lastType) {
//            [arr addObject:@([self.configValueArray indexOfObject:selectType])];
//        }
//
//    }
    self.selectedIndexs = [common.lastConfigType mutableCopy];
    self.modules = self.configTextArray;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"config_help_button.png"] style:UIBarButtonItemStylePlain target:self action:@selector(onHelp)];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{ //多线程解压缩
        NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        NSString *zipfile = [[NSBundle mainBundle] pathForResource:@"wifi-help" ofType:@"zip"];
        [SSZipArchive unzipFileAtPath:zipfile toDestination:cachePath overwrite:NO password:nil error:nil];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.modules.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    NSString *text = NSLocalizedString(@"Correctly select the module type to help the device configuration succeed. You could refer to the help in the module type selection", nil);
    return [GosCommon tableHeaderHeight:tableView text:text offset:24];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *text = NSLocalizedString(@"Correctly select the module type to help the device configuration succeed. You could refer to the help in the module type selection", nil);
    return [GosCommon tableHeaderView:tableView text:text offset:24];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"selectIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    if ([self hasSelected:indexPath.row]) {
        NSLog(@"选中的行, %zd", indexPath.row);
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.textLabel.text = self.modules[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self hasSelected:indexPath.row]) {
        //移除模块
        [self.selectedIndexs removeObject:self.configValueArray[indexPath.row]];
    }
    else {
        //添加模块
        [self.selectedIndexs addObject:self.configValueArray[indexPath.row]];
    }
    [tableView reloadData];
}

- (NSString *)moduleFile {
    if (GosCommon.isChinese) {
        return @"moduleTypeInfo.html";
    }
    return @"moduleTypeInfoEnglish.html";
}

- (void)onHelp {
    NSString *cachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *webfile = [cachePath stringByAppendingPathComponent:[self moduleFile]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:webfile]) { //ios11 required?
        webfile = [cachePath stringByAppendingPathComponent:@"wifi-help"];
        webfile = [webfile stringByAppendingPathComponent:[self moduleFile]];
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:webfile]) {
        GosWebController *webCtrl = [GosWebController controllerWithLocalFile:webfile];
        webCtrl.navigationItem.title = NSLocalizedString(@"Module Type Choose Tips", nil);
        [GosCommon safePushViewController:self.navigationController viewController:webCtrl animated:YES];
    }
}

- (IBAction)onOK:(id)sender {
    if (self.selectedIndexs.count > 0) {
        if (self.isSoftAPMode) {
            [GosConfigStart pushToSoftAP:self.navigationController configType:self.selectedIndexs];
        } else {
            [self performSegueWithIdentifier:@"toConfirm" sender:self.selectedIndexs];
        }
    } else {
        [GosCommon showAlertAutoDisappear:NSLocalizedString(@"Please select the type of module", nil)];
    }
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(NSArray *)sender {
    GizConfigAirlinkConfirm *confirmCtrl = segue.destinationViewController;
    confirmCtrl.airlinkConfigType = sender;
}


- (BOOL)hasSelected:(NSInteger)row {
    NSLog(@"self.selectedIndexs = %@", self.selectedIndexs);
    if (self.selectedIndexs.count == 0) {
        return NO;
    }
    // 拿到指定行的模组类型
    NSNumber *type =self.configValueArray[row];
    for (NSNumber *selectedType in self.selectedIndexs) {
        if ([selectedType isKindOfClass:[NSNumber class]]) {
            if (selectedType.integerValue == type.integerValue) {
                return YES;
            }
        }
    }
    return NO;
}

- (NSMutableArray *)selectedIndexs {
    if (!_selectedIndexs) {
        _selectedIndexs = [NSMutableArray array];
    }
    return _selectedIndexs;
}

@end
