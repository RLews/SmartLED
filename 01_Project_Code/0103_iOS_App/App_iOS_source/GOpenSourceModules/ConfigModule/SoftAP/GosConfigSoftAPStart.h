//
//  GizConfigSoftAPStart.h
//  NewFlow
//
//  Created by GeHaitong on 16/1/13.
//  Copyright © 2016年 gizwits. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GosConfigSoftAPStart : UIViewController

@property (assign, nonatomic) BOOL isNewInterface;
@property (assign, nonatomic) BOOL isBindInterface;
@property (strong, nonatomic) NSArray *softapConfigType;

- (IBAction)onOpenConfig:(id)sender;

@end
