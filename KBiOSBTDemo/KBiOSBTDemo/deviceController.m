//
//  deviceController.m
//  KBiOSBTDemo
//
//  Created by lollipop on 2017/4/11.
//  Copyright © 2017年 lollipop. All rights reserved.
//

#import "deviceController.h"
#import "LSBuzzBTmanager.h"

@interface deviceController ()

@property (weak, nonatomic) IBOutlet UILabel *textLabel;

@end

@implementation deviceController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)versionGet:(id)sender {
    [[LSBuzzBTmanager sharedInstance] writeValue:@"FF01051500" option:nil];
}

- (IBAction)ipGet:(id)sender {
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
