//
//  simpleMovieModel.m
//  LFAPIManager
//
//  Created by 刘峰 on 2019/7/3.
//  Copyright © 2019年 刘峰. All rights reserved.
//

#import "simpleMovieModel.h"

@implementation simpleMovieModel

+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper{
    return @{
             @"movieId":@"id"
             };
}

@end
