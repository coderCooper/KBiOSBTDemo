//
//  kbConsoleLog.h
//  TestDemoForKB
//
//  Created by lollipop on 2017/4/1.
//  Copyright © 2017年 lollipop. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface kbConsoleLog : NSObject

+ (instancetype)sharedInstance;

- (void)showLog:(NSString *)log;

@end
