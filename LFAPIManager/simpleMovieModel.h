//
//  simpleMovieModel.h
//  LFAPIManager
//
//  Created by 刘峰 on 2019/7/3.
//  Copyright © 2019年 刘峰. All rights reserved.
//

#import "LFBaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface simpleMovieModel : LFBaseModel

@property(nonatomic,copy) NSString *alt;

@property(nonatomic,assign) long movieId;

@property(nonatomic,copy) NSString *title;

@property(nonatomic,assign) NSInteger year;

@end

NS_ASSUME_NONNULL_END
