//
//  LFAPIManager.h
//  LFAPIManager
//
//  Created by 刘峰 on 2019/7/3.
//  Copyright © 2019年 刘峰. All rights reserved.
//

#import "AFHTTPSessionManager.h"
#import <ReactiveObjC.h>
#import "LFModels.h"


NS_ASSUME_NONNULL_BEGIN

typedef enum {
    APICachePloy_Server = 0, //获取服务器数据
    APICachePloy_Normal = 1, //先获取缓存数据,如果没有再获取服务器数据
    APICachePloy_Cache  = 2  //获取缓存数据
} APICachePloy;

@interface LFAPIManager : AFHTTPSessionManager

//网络状态
@property (nonatomic, assign) AFNetworkReachabilityStatus networkStatus;

//请求方式
@property(nonatomic, assign) APICachePloy cachePloy;

//单列方法
+ (instancetype)sharedManager;

/**
 演示示例

 @param start 便宜量
 @param pageSize 请求数据
 @return RACSignal
 */
- (RACSignal *)simpleGetMovieListWithStart:(NSInteger)start pageSize:(NSInteger)pageSize;

@end

NS_ASSUME_NONNULL_END
