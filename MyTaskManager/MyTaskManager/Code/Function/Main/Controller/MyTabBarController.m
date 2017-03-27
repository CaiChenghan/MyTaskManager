//
//  MyTabBarController.m
//  MyTaskManager
//
//  Created by 蔡成汉 on 2017/3/17.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import "MyTabBarController.h"
#import "TaskViewController.h"
#import "DownloadViewController.h"

@interface MyTabBarController ()

@end

@implementation MyTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    TaskViewController *taskViewController = [[TaskViewController alloc]init];
    UINavigationController *nav1 = [[UINavigationController alloc]initWithRootViewController:taskViewController];
    
    DownloadViewController *downloadViewController = [[DownloadViewController alloc]init];
    UINavigationController *nav2 = [[UINavigationController alloc]initWithRootViewController:downloadViewController];
    
    self.viewControllers = [NSArray arrayWithObjects:nav1,nav2, nil];
    
    nav1.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemBookmarks tag:0];
    nav2.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemDownloads tag:1];
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

@end
