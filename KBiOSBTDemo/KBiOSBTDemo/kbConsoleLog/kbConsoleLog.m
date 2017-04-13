//
//  kbConsoleLog.m
//  TestDemoForKB
//
//  Created by lollipop on 2017/4/1.
//  Copyright © 2017年 lollipop. All rights reserved.
//

#import "kbConsoleLog.h"

@interface kbConsoleLog()

@property (nonatomic,copy)      UIWindow    *mainWindow;

@property (nonatomic,strong)    UITextView  *logView;

@end

@implementation kbConsoleLog

static kbConsoleLog *_consoleManager;

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        _consoleManager = [super allocWithZone:zone];
    });
    
    return _consoleManager;
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return _consoleManager;
}

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _consoleManager = [[self alloc] init];
    });
    
    return _consoleManager;
}

- (void)showLog:(NSString *)log {
    if ([NSThread isMainThread]) {
        [self show:log];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self show:log];   
        });
    }
}

- (void)show:(NSString *)log {
    [self initMainWindow];
    // 打印到控制台中
    NSLog(@"%@", log);
    
    NSMutableString *string = [_logView.text mutableCopy];
    [string appendFormat:@"\n %@",log];
    _logView.text = string;
    
    NSRange bottom = NSMakeRange(string.length - 1, 1);
    [_logView scrollRangeToVisible:bottom];
}

- (void)initMainWindow {
    if (_mainWindow) {
        return;
    }
    _mainWindow = [[UIWindow alloc] init];
    _mainWindow.rootViewController = [UIViewController new];
    _mainWindow.windowLevel = UIWindowLevelAlert;
    _mainWindow.userInteractionEnabled = NO;
    CGFloat rgbF = 30.0 / 255;
    _mainWindow.backgroundColor = [UIColor colorWithRed:rgbF green:rgbF blue:rgbF alpha:0.1];
    _mainWindow.frame = [UIScreen mainScreen].bounds;
    _logView = [[UITextView alloc] init];
    _logView.frame = _mainWindow.bounds;
    _logView.textColor = [UIColor blackColor];
    _logView.backgroundColor = [UIColor clearColor];
    _logView.text = @"0-----";
    [_mainWindow addSubview:_logView];
    _mainWindow.hidden = NO;
    [_mainWindow makeKeyWindow];
}
@end
