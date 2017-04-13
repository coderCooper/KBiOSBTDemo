//
//  centralController.m
//  KBiOSBTDemo
//
//  Created by lollipop on 2017/4/11.
//  Copyright © 2017年 lollipop. All rights reserved.
//

#import "centralController.h"
#import "LSBuzzBTmanager.h"

@interface centralController ()<LSBuzzBTmanagerDelegate>

@property (nonatomic,strong) NSArray *devList;

@end

@implementation centralController

- (void)viewDidLoad {
    [super viewDidLoad];
    [LSBuzzBTmanager sharedInstance].delegate = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [[LSBuzzBTmanager sharedInstance] FinddevFiter:YES];
    });
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.devList.count;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellInden = @"cellInden";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellInden];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:0 reuseIdentifier:cellInden];
    }
    CBPeripheral *ppp = self.devList[indexPath.row];
    cell.textLabel.text = ppp.name;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CBPeripheral *ppp = self.devList[indexPath.row];
    [[LSBuzzBTmanager sharedInstance] connectBuzzard:ppp];
}

/*
 * @descripe 当前蓝牙是否可用
 * @param available 当前蓝牙是否可用
 */
- (void)centralManagerDidUpdateState:(BOOL)available {
    NSLog(@"--centralManagerDidUpdateState--");
}

/*
 * @descripe 搜到蓝牙设备的回调，每次搜到一个新设备都会回调
 * @param isFinish 搜索是否结束
 * @param list 搜索当前搜索结果
 * @param error 参考BuzzError
 */
- (void)fetchDevice:(BOOL)isFinish device:(NSArray *)list withResult:(BuzzResult)error {
    self.devList = list;
    [self.tableView reloadData];
}

/*
 * @descripe 连接制定蓝牙设备结果的回调
 * @param error 参考BuzzError
 */
- (void)connectResult:(BuzzResult)result withError:(NSError *)error {
    if (result == BuzzBTSuccess) {
        [self performSegueWithIdentifier:@"pushToDetail" sender:nil];
    }
}

/*
 * @descripe 连接被断开，被动断开或者主动断开
 * @param error 参考BuzzError
 */
- (void)disConnectResult:(BuzzResult)result withError:(NSError *)error {
    
}

@end
