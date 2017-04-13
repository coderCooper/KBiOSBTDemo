//
//  LSBuzzBTmanager.h
//  gene
//
//  Created by lollipop on 2017/4/7.
//  Copyright © 2017年 lesports. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

// 错误类型，后续根据厂商加上其他错误
typedef NS_ENUM(NSInteger,BuzzResult) {
    BuzzBTSuccess = 0,  // 成功
    BuzzBTFail,         // 失败
    BuzzBTInvalid,      // 目前蓝牙不可用
    BuzzTimeout,        // 此标志位只说明超时，并不说明没有搜到结果
};

typedef void (^LSBikeFailedBlock)(NSError *error);
typedef void (^LSBikeResultBlock)(BOOL result, NSError *error);

@protocol LSBuzzBTmanagerDelegate <NSObject>

/*
 * @descripe 当前蓝牙是否可用
 * @param available 当前蓝牙是否可用
 */
- (void)centralManagerDidUpdateState:(BOOL)available;

/*
 * @descripe 搜到蓝牙设备的回调，每次搜到一个新设备都会回调
 * @param isFinish 搜索是否结束
 * @param list 搜索当前搜索结果
 * @param error 参考BuzzError
 */
- (void)fetchDevice:(BOOL)isFinish device:(NSArray *)list withResult:(BuzzResult)error;

/*
 * @descripe 连接制定蓝牙设备结果的回调
 * @param error 参考BuzzError
 */
- (void)connectResult:(BuzzResult)result withError:(NSError *)error;

/*
 * @descripe 连接被断开，被动断开或者主动断开
 * @param error 参考BuzzError
 */
- (void)disConnectResult:(BuzzResult)result withError:(NSError *)error;

@end


@interface LSBuzzBTmanager : NSObject

@property (nonatomic, weak)  id<LSBuzzBTmanagerDelegate> delegate; // 部分回调

@property (nonatomic,assign) NSInteger scanTimeInterval;// 扫描时间

// 单例
+ (instancetype)sharedInstance;

/*
 *
 * 搜索并连接指定的蓝牙设备
 *
 */
- (BOOL)FinddevFiter:(BOOL)pp;//查找设备，pp为YES表示开uuid过滤，NO表示关闭

- (void)stopSearchDevice;//停止扫描设备

- (void)connectBuzzard:(CBPeripheral *)peripheral;//连接某项蓝牙设备

- (void)disconnectBuzzard:(CBPeripheral *)peripheral;//与某项设备断开连接

- (void)writeValue:(NSString *)command option:(NSString *)option;
@end
