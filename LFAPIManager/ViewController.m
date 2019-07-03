//
//  ViewController.m
//  LFAPIManager
//
//  Created by 刘峰 on 2019/7/3.
//  Copyright © 2019年 刘峰. All rights reserved.
//

#import "ViewController.h"
#import "LFAPIManager.h"


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 演示示例
    LFAPIManager *manager = [LFAPIManager sharedManager];
    
//    @weakify(self);
    //请求缓存 请求缓存不存在错误,所以没有error block回调
    manager.cachePloy = APICachePloy_Cache;
    [[manager simpleGetMovieListWithStart:0 pageSize:20] subscribeNext:^(id x) {
//        @strongify(self);
        NSLog(@"请求缓存数据成功 %@",x);
    }];
    
    //请求服务器
    manager.cachePloy = APICachePloy_Server;
    [[manager simpleGetMovieListWithStart:0 pageSize:20] subscribeNext:^(id x) {
//        @strongify(self);
        NSLog(@"请求服务器数据成功 %@",x);
    } error:^(NSError *error) {
//        @strongify(self);
        NSLog(@"请求服务器数据失败 %@",error);
    }];
}


@end
