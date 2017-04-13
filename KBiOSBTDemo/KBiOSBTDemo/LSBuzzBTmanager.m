//
//  LSBuzzBTmanager.m
//  gene
//
//  Created by lollipop on 2017/4/7.
//  Copyright © 2017年 lesports. All rights reserved.
//

#import "LSBuzzBTmanager.h"
#import "kbConsoleLog.h"

#define UUID_CONTROL_SERVICE            @"00001201-0000-1000-8000-************"
#define UUID_LISTEN_CHARACTERISTICS     @"33333333-616D-6261-5F69-************"
#define UUID_CONTROL_CHARACTERISTICS    @"11111111-616D-6261-5F69-************"

@interface LSBuzzBTmanager() <CBCentralManagerDelegate,CBPeripheralDelegate> {
    
    CBCentralManager *centerManager;
    CBPeripheral *activePeripheral;
    CBCharacteristic *readCharacteristic;
    CBCharacteristic *controlCharacteristic;
}

@property (nonatomic,strong) NSMutableArray *devLists;

@end

@implementation LSBuzzBTmanager

+ (instancetype)sharedInstance {
    static LSBuzzBTmanager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[LSBuzzBTmanager alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        centerManager = [[CBCentralManager alloc]initWithDelegate:self queue:nil];
    }
    return self;
}

#pragma mark 搜索蓝牙设备相关
- (BOOL)FinddevFiter:(BOOL)ppp {
    // 蓝牙不可用
    if (centerManager.state != CBManagerStatePoweredOn) {
        if (_delegate && [_delegate respondsToSelector:@selector(fetchDevice:device:withResult:)]) {
            [_delegate fetchDevice:NO device:nil withResult:BuzzBTInvalid];
        }
        return NO;
    }
    
    // 开始搜索
    NSArray *serviceUUIDs = nil;
    if (ppp) {  // 过滤
//        serviceUUIDs = @[[CBUUID UUIDWithString:@""]];
    }
    [centerManager scanForPeripheralsWithServices:serviceUUIDs options:nil];
    if (_scanTimeInterval == 0) {
        _scanTimeInterval = 20;
    }
    // 先取消之前的延时
    [LSBuzzBTmanager cancelPreviousPerformRequestsWithTarget:self selector:@selector(scanTimeOut) object:self];
    // 重新执行超时
    [self performSelector:@selector(scanTimeOut) withObject:self afterDelay:_scanTimeInterval];
    return YES;
}

- (void)stopSearchDevice {
    [centerManager stopScan];
}


- (void)connectBuzzard:(CBPeripheral *)peripheral {
    [centerManager connectPeripheral:peripheral options:nil];
}

- (void)disconnectBuzzard:(CBPeripheral *)peripheral {
    [centerManager cancelPeripheralConnection:peripheral];
    activePeripheral = nil;
}

- (void)scanTimeOut {
    [centerManager stopScan];
    if (_delegate && [_delegate respondsToSelector:@selector(fetchDevice:device:withResult:)]) {
        [_delegate fetchDevice:YES device:_devLists withResult:BuzzTimeout];
    }
}

- (void)writeValue:(NSString *)command option:(NSString *)option {
    
    if (activePeripheral.state != CBPeripheralStateConnected) {
        NSLog(@"peripheral disconnected");
        return;
    }

    NSData *data;
    if (option.length > 0) {
        data = [self command:command withOption:option];
    } else {
        data = [self dataFromHexString:command];
    }
    NSString *msg = [NSString stringWithFormat:@"Write command %@ on peripheral %@(%@)", data, activePeripheral.name, activePeripheral.identifier];
    NSLogK(msg);
    [activePeripheral writeValue:data forCharacteristic:controlCharacteristic type:CBCharacteristicWriteWithResponse];
}

#pragma mark - getter
- (NSMutableArray *)devLists{
    if (!_devLists) {
        _devLists = [[NSMutableArray alloc] init];
    }
    return _devLists;
}

#pragma mark CBCentralManagerDelegate
- (void)centralManagerDidUpdateState:(CBCentralManager *)central{
    BOOL isAvaliable = NO;
    if (central.state == CBManagerStatePoweredOn) {
        isAvaliable = YES;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(centralManagerDidUpdateState:)]) {
        [_delegate centralManagerDidUpdateState:isAvaliable];
    }
}
// 扫描到设备
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    if (!peripheral.name ) {
        return;
    }
    if (peripheral.name == 0) {
        return;
    }
    NSString *msg = [NSString stringWithFormat:@"--name = %@ \n %@",peripheral.name,advertisementData];
    NSLogK(msg);
    // 如果已经被搜索，就不新加入
    if ([self.devLists containsObject:peripheral]) {
        return;
    }
    // 1.信号过滤，信号太弱连不上
    // 2.名称过滤
    // 根据startScanBuzzard方法中扫描结果 再看是否需要增加过滤逻辑
    [self.devLists addObject:peripheral];
    if (_delegate && [_delegate respondsToSelector:@selector(fetchDevice:device:withResult:)]) {
        [_delegate fetchDevice:NO device:_devLists withResult:BuzzBTSuccess];
    }
}

// 连接设备
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSString *msg = [NSString stringWithFormat:@"-didConnectPeripheral-%@",peripheral.name];
    NSLogK(msg);
    activePeripheral = peripheral;
    if (_delegate && [_delegate respondsToSelector:@selector(connectResult:withError:)]) {
        [_delegate connectResult:BuzzBTSuccess withError:nil];
    }
    NSArray *services = nil;// @[[CBUUID UUIDWithString:@""]];
    activePeripheral.delegate = self;
    [activePeripheral discoverServices:services];
}

// 连接设备失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSString *msg = [NSString stringWithFormat:@"-didFailToConnectPeripheral-%@",peripheral.name];
    NSLogK(msg);
    if (_delegate && [_delegate respondsToSelector:@selector(connectResult:withError:)]) {
        [_delegate connectResult:BuzzBTFail withError:error];
    }
}

// 丢失连接
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    NSString *msg = [NSString stringWithFormat:@"-didDisconnectPeripheral-%@",peripheral.name];
    NSLogK(msg);
    activePeripheral = nil;
    if (_delegate && [_delegate respondsToSelector:@selector(disConnectResult:withError:)]) {
        [_delegate disConnectResult:BuzzBTFail withError:error];
    }
}

// 服务
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    if (error) {
        NSString *msg = [NSString stringWithFormat:@"did discover peripheral:%@(%@) service error : %@", peripheral.name, peripheral.identifier, error.localizedDescription];
        NSLogK(msg);
        return;
    }
    NSString *msg = [NSString stringWithFormat:@"did discover peripheral:%@(%@) service %@", peripheral.name, peripheral.identifier, peripheral.services];
    NSLogK(msg);
    for (CBService *service in peripheral.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:UUID_CONTROL_SERVICE]]) {
            [peripheral discoverCharacteristics:@[[CBUUID UUIDWithString:UUID_CONTROL_CHARACTERISTICS],[CBUUID UUIDWithString:UUID_LISTEN_CHARACTERISTICS]] forService:service];
            break;
        }
    }
}

// periperal discoverCharacteristics:(nullable NSArray<CBUUID *> *)characteristicUUIDs forService:(CBService *)service;
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    if (error) {
        NSString *msg = [NSString stringWithFormat:@"peripheral %@(%@) did discover characteristic error %@", peripheral.name, peripheral.identifier, error.localizedDescription];
        NSLogK(msg);
        return;
    }
    
    NSString *msg = [NSString stringWithFormat:@"peripheral %@(%@) did discover characteristics %@", peripheral.name, peripheral.identifier, service.characteristics];
    NSLogK(msg);
    for (CBCharacteristic *chara in service.characteristics) {
        if ([chara.UUID isEqual:[CBUUID UUIDWithString:UUID_LISTEN_CHARACTERISTICS]]) {
            [peripheral setNotifyValue:YES forCharacteristic:chara];
            readCharacteristic = chara;
        } else if ([chara.UUID isEqual:[CBUUID UUIDWithString:UUID_CONTROL_CHARACTERISTICS]]) {
            controlCharacteristic = chara;
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSData *data = characteristic.value;
    NSString *response = [self valueStringWithResponse:data];
    NSString *msg = [NSString stringWithFormat:@"command did get response:%@", response];
    NSLogK(msg);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSString *msg = [NSString stringWithFormat:@"didWriteValueForCharacteristic:%@", error];
    NSLogK(msg);
}

#pragma mark 发送和接收数据解析相关，以下是针对我目前项目中蓝牙功能的封装，不一定适用其他项目
- (NSData *)command:(NSString *)hexCommand withOption:(NSString *)option{
    
    NSData *optionData = [option dataUsingEncoding:NSUTF8StringEncoding];
    
    NSInteger totalLength = optionData.length + 5;
    
    NSString *hexOptionString = [self dataToHex:optionData];
    
    NSString *lengthString = [NSString stringWithFormat:@"%X",(int)totalLength];
    
    //最长只支持 255 长度的命令
    if (lengthString.length==1) {
        lengthString = [NSString stringWithFormat:@"0%@",lengthString];
    }
    
    NSString *hexCommandString = [NSString stringWithFormat:hexCommand,lengthString,hexOptionString];
    
    NSData *commandData = [self dataFromHexString:hexCommandString];
    
    return commandData;
}

- (NSData *)dataFromHexString:(NSString *)hexString {
    const char *chars = [hexString UTF8String];
    long i = 0, len = hexString.length;
    
    NSMutableData *data = [NSMutableData dataWithCapacity:len / 2];
    char byteChars[3] = {'\0','\0','\0'};
    unsigned long wholeByte;
    
    while (i < len) {
        byteChars[0] = chars[i++];
        byteChars[1] = chars[i++];
        wholeByte = strtoul(byteChars, NULL, 16);
        [data appendBytes:&wholeByte length:1];
    }
    
    return data;
}

- (NSString *)dataToHex:(NSData *)data {
    NSUInteger i, len;
    unsigned char *buf, *bytes;
    
    len = data.length;
    bytes = (unsigned char*)data.bytes;
    buf = malloc(len*2);
    
    for (i=0; i<len; i++) {
        buf[i*2] = itoh((bytes[i] >> 4) & 0xF);
        buf[i*2+1] = itoh(bytes[i] & 0xF);
    }
    
    return [[NSString alloc] initWithBytesNoCopy:buf
                                          length:len*2
                                        encoding:NSUTF8StringEncoding
                                    freeWhenDone:YES];
}

static inline char itoh(int i) {
    if (i > 9) 
        return 'A' + (i - 10);
    return '0' + i;
}


/*
 *   把返回命令里的传递值拿出来
 */
- (NSString *)valueStringWithResponse:(NSData *)data {
    //NSData *ad = [NSData dataWithBytes:0x00 length:2];
    if (data.length <= 5) {
        return nil;
    }
    NSData *tailData = [data subdataWithRange:NSMakeRange(data.length-1, 1)];
    if ([tailData isEqualToData:[NSData dataWithBytes:"\0" length:1]]) {
        if (data.length > 6) {
            NSData *valueData = [data subdataWithRange:NSMakeRange(4, data.length-5)];
            NSString *valueString = [[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding];
            return valueString;
        }
    } else {
        if (data.length > 5) {
            NSData *valueData = [data subdataWithRange:NSMakeRange(4, data.length-4)];
            NSString *valueString = [[NSString alloc] initWithData:valueData encoding:NSUTF8StringEncoding];
            return valueString;
        }
    }
    return nil;
}

@end
