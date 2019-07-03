//
//  LFAPIManager.m
//  LFAPIManager
//
//  Created by 刘峰 on 2019/7/3.
//  Copyright © 2019年 刘峰. All rights reserved.
//

#import "LFAPIManager.h"
#import <YYCache.h>
#import <AFNetworkActivityIndicatorManager.h>
#import <NSObject+YYModel.h>

#ifdef DEBUG
//测试环境
NSString *const kHostUrl = @"http://www.liulongbin.top:3005";
#else
//正式环境
NSString *const kHostUrl = @"http://www.liulongbin.top:3005";
#endif

typedef enum {
    RequestMethod_Post = 0, //post请求
    RequestMethod_Get = 1, //get请求
} RequestMethod;



//标示
NSString *const kErrorDomain = @"kErrorDomain";
//服务器内部错误
NSInteger const kErrorException = 500;
//无网络
NSInteger const kNotNetwordException = 6666;

@interface LFAPIManager()

//缓存
@property (nonatomic,strong) YYCache *cache;

@end

@implementation LFAPIManager

+ (instancetype)sharedManager{
    static dispatch_once_t onceToken;
    static LFAPIManager *instance;
    dispatch_once(&onceToken, ^{
        instance = [self manager];
    });
    return instance;
}

// AFHTTPSessionManager 创建的时候会调用initWithBaseURL方法,所以对此方法在子类中进行重写,配置基本的参数设置相关
- (instancetype)initWithBaseURL:(NSURL *)url{
    self = [super initWithBaseURL:url];
    if (self) {
        self.requestSerializer = [[AFJSONRequestSerializer alloc] init];
        self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html", nil];
        //初始化YYCache,缓存数据
        self.cache = [YYCache cacheWithName:@"cache_data"];
        
        //设置https证书
#ifdef DEBUG
        NSLog(@"测试环境不添加https证书认证");
#else
        [self setSecurityPolicy:[self customSecurityPolicy]];
#endif
        //监听当前网络
        [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
        AFNetworkReachabilityManager *networkManager = [AFNetworkReachabilityManager sharedManager];
        [networkManager startMonitoring];
        [networkManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            self.networkStatus = status;
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:{
                    NSLog(@"未知");
                    break;
                }
                case AFNetworkReachabilityStatusNotReachable:{
                    NSLog(@"无网络");
                    break;
                }
                case AFNetworkReachabilityStatusReachableViaWiFi:{
                    NSLog(@"WiFi网络");
                    break;
                }
                case AFNetworkReachabilityStatusReachableViaWWAN:{
                    NSLog(@"无线网络");
                    break;
                }
                default:
                    break;
            }
        }];
    }
    return self;
}

+ (AFSecurityPolicy *)customSecurityPolicy {
    // 先导入证书 证书由服务端生成，具体由服务端人员操作
    NSString *path = [[NSBundle mainBundle] pathForResource:@"public" ofType:@"cer"];//证书的路径 xx.cer
    NSData *cerData = [NSData dataWithContentsOfFile:path];
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    // AFSSLPinningModeNone: 代表客户端无条件地信任服务器端返回的证书。
    // AFSSLPinningModePublicKey: 代表客户端会将服务器端返回的证书与本地保存的证书中，PublicKey的部分进行校验；如果正确，才继续进行。
    // AFSSLPinningModeCertificate: 代表客户端会将服务器端返回的证书和本地保存的证书中的所有内容，包括PublicKey和证书部分，全部进行校验；如果正确，才继续进行。
    securityPolicy.allowInvalidCertificates = NO;
    // 是否允许无效证书（也就是自建的证书），默认为NO 如果是需要验证自建证书，需要设置为YES
    securityPolicy.validatesDomainName = YES;
    //validatesDomainName 是否需要验证域名，默认为YES;
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    securityPolicy.pinnedCertificates = [[NSSet alloc] initWithObjects:cerData, nil];
    return securityPolicy;
}

//在此方法里面添加请求公共参数
- (NSDictionary *)headerParameters{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    //bundleId
    NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    [parameters setObject:bundleId forKey:@"bundleId"];
    //设备类型
    [parameters setObject:@"MOBILE" forKey:@"deviceType"];
    //设备型号
    [parameters setObject:[[UIDevice currentDevice] model] forKey:@"deviceModel"];
    //系统版本
    [parameters setObject:[UIDevice currentDevice].systemVersion forKey:@"osVersion:"];
    //系统类型
    [parameters setObject:@"IOS" forKey:@"osType"];
    //版本
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [parameters setObject:version forKey:@"appVersion"];
    //发布渠道
#ifdef DEBUG
    [parameters setObject:@"DEBUG" forKey:@"releaseChannel"];
#else
    [parameters setObject:@"RELEASE" forKey:@"releaseChannel"];
#endif
    return parameters;
}

- (RACSignal *)customRequestWithMethod:(RequestMethod)method
                            parameters:(NSDictionary *)parameters
                               apiName:(NSString *)apiName
                           resultClass:(Class)resultClass
                                   url:(NSString *)url{
    NSString *requestString = [url stringByAppendingPathComponent:apiName];
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionary];
    //添加公共参数
    NSDictionary *headParameters = [self headerParameters];
    [requestParameters addEntriesFromDictionary:headParameters];
    
    //添加请求参数
    if (parameters && parameters.count > 0) {
        [requestParameters addEntriesFromDictionary:parameters];
    }
    
    //判断当前的请求模式,如果不是从服务器请求,根据请求的参数和接口名取出上次缓存的数据
    id cacheData = self.cachePloy != APICachePloy_Server ? [self.cache objectForKey:[self cacheKeyWithParameters:parameters apiName:apiName]] : nil;
    switch (self.cachePloy) {
            //缓存模式直接把上次请求的数据返回
        case APICachePloy_Cache:
            return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                [subscriber sendNext:cacheData];
                [subscriber sendCompleted];
                return nil;
            }];
            break;
            //Normal模式,如果本地有数据,直接返回,否则请求服务器
        case APICachePloy_Normal:
            if (cacheData) {
                return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
                    [subscriber sendNext:cacheData];
                    [subscriber sendCompleted];
                    return nil;
                }];
            }
            break;
        default:
            break;
    }
    @weakify(self);
    RACSignal *requestSignal = [RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        @strongify(self);
        if (method == RequestMethod_Get) {
            NSURLSessionDataTask *sessionTask = [self GET:requestString parameters:requestParameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [subscriber sendNext:responseObject];
                [subscriber sendCompleted];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [subscriber sendError:error];
            }];
            return [RACDisposable disposableWithBlock:^{
                [sessionTask cancel];
            }];
        }else{
            NSURLSessionDataTask *sessionTask = [self POST:requestString parameters:parameters progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                [subscriber sendNext:responseObject];
                [subscriber sendCompleted];
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                [subscriber sendError:error];
            }];
            return [RACDisposable disposableWithBlock:^{
                [sessionTask cancel];
            }];
        }
    }];
    return [[requestSignal catch:^RACSignal *(NSError *error) {
        //捕获异常,有可能无网络,或者服务器内部错误,直接创建一个错误的信号返回
        if (self.networkStatus > 0) {
            //有网络
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"请求失败,请稍后再试"};
            NSError *customError = [NSError errorWithDomain:kErrorDomain code:error.code userInfo:userInfo];
            return [RACSignal error:customError];
        }else{
            //无网络
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"当前无网络,请检查网络"};
            NSError *customError = [NSError errorWithDomain:kErrorDomain code:kNotNetwordException userInfo:userInfo];
            return [RACSignal error:customError];
        }
    }] flattenMap:^RACSignal *(id data) {
        //请求成功,这里这个data就是服务器返回的数据 flattenMap这个block主要处理的是将json格式数据转化成model然后返回给界面使用
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            @strongify(self);
            //这里要和服务端约定请求状态码和返回的数据格式
//            NSString *code = data[@"code"];
//            if ([code isEqualToString:@"ok"]) {
            id resultObj = data[@"subjects"];
            if (resultObj) {
                //如果传递的class是LFBaseModel的子类,才解析成对象,否则不做处理
                if (resultObj && resultClass && [resultClass isSubclassOfClass:LFBaseModel.class]) {
                    if ([resultObj isKindOfClass:[NSArray class]]) {
                        resultObj = [NSArray modelArrayWithClass:resultClass json:resultObj];
                    }else{
                        resultObj = [resultClass modelWithJSON:resultObj];
                    }
                }else{
                    //未传递classl对象,数据不解析，有些接口直接返回基础类型，这里不需要转换
                    if ([resultObj isKindOfClass:NSNull.class]) {
                        resultObj = nil;
                    }
                }
                if (resultObj) {
                    [self.cache setObject:resultObj forKey:[self cacheKeyWithParameters:parameters apiName:apiName]];
                }
                [subscriber sendNext:resultObj];
            }else{
                //和服务器正常通信，有可能接口参数出错或者登录的时候账号密码等错误
                NSString *content = data[@"message"] ? data[@"message"] : @"";
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : content};
                NSError *error = [NSError errorWithDomain:kErrorDomain code:kErrorException userInfo:userInfo];
                [subscriber sendError:error];
            }
            [subscriber sendCompleted];
            return nil;
        }];
    }];
}

- (NSString *)cacheKeyWithParameters:(NSDictionary *)parameters apiName:(NSString *)apiName{
    return [NSString stringWithFormat:@"%@%@",apiName,parameters ? parameters : @""];
}


/**
 演示示例
 
 @param start 偏移量
 @param pageSize 请求数据
 @return RACSignal
 */
- (RACSignal *)simpleGetMovieListWithStart:(NSInteger)start pageSize:(NSInteger)pageSize{
    NSString *apiName = @"/api/v2/movie/top250";
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    [parameters setValue:@(start) forKey:@"start"];
    [parameters setValue:@(pageSize) forKey:@"count"];
    return [self customRequestWithMethod:RequestMethod_Get parameters:parameters apiName:apiName resultClass:simpleMovieModel.class url:kHostUrl];
}


@end
