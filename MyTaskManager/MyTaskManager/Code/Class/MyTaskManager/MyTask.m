//
//  MyTask.m
//  MyTaskManager
//
//  Created by 蔡成汉 on 2017/3/17.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import "MyTask.h"
#import <CommonCrypto/CommonDigest.h>

@interface MyTask ()
{
    NSDate *_last_date;
    NSUInteger _last_file_received_size;
}
@property (nonatomic , strong , readwrite) NSURL *url;
@property (nonatomic , strong , readwrite) NSURL *imageUrl;
@property (nonatomic , assign , readwrite) TaskState state;
@property (nonatomic , strong , readwrite) NSString *fileName;
@property (nonatomic , strong , readwrite) NSString *fileType;
@property (nonatomic , strong , readwrite) NSString *filePath;
@property (nonatomic , assign , readwrite) NSUInteger bytesWritten;
@property (nonatomic , assign , readwrite) NSUInteger totalBytesWritten;
@property (nonatomic , assign , readwrite) NSUInteger totalBytesExpectedToWrite;
@property (nonatomic , strong , readwrite) NSString *speed;
@property (nonatomic , strong , readwrite) NSString *time;
@property (nonatomic , strong , readwrite) NSError *error;

@property (nonatomic , weak) MyTaskManager *manager;

/**
 downloadTask
 */
@property (nonatomic , strong) NSURLSessionDownloadTask *downloadTask;

/**
 保存文件名
 */
@property (nonatomic , strong) NSString *saveName;

/**
 缓存文件存储路径
 */
@property (nonatomic , strong) NSString *tmpPath;

@end

@implementation MyTask

/**
 重写init方法
 
 @param url 任务url
 @return 实例化的task
 */
-(instancetype)initWithURL:(NSURL *)url{
    self = [super init];
    if (!self) {
        return nil;
    }
    _last_date = [NSDate date];
    _last_file_received_size = 0;
    self.url = url;
    self.state = WatingDownload;
    self.fileName = [[url absoluteString]lastPathComponent];
    self.fileType = self.fileName.pathExtension;
    NSDateFormatter *tpDateformatter=[[NSDateFormatter alloc]init];
    [tpDateformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    self.time = [tpDateformatter stringFromDate:[NSDate date]];
    self.saveName = [self stringMD5:[url absoluteString]];
    self.tmpPath = @"";
    return self;
}

-(void)setManager:(MyTaskManager *)manager{
    _manager = manager;
    _filePath = self.filePath;
}

-(NSString *)filePath{
    return [self.manager.path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",self.saveName,self.fileType]];
}

/**
 set

 @param totalBytesWritten totalBytesWritten
 */
-(void)setTotalBytesWritten:(NSUInteger)totalBytesWritten{
    _totalBytesWritten = totalBytesWritten;
    [self caculateSpeed];
}

/**
 下载速度计算
 */
-(void)caculateSpeed{
    NSDate *currentDate = [NSDate date];
    if ([currentDate timeIntervalSinceDate:_last_date] >= 1) {
        NSTimeInterval tpTime = [currentDate timeIntervalSinceDate:_last_date];
        NSUInteger tpData = _totalBytesWritten - _last_file_received_size;
        _last_date = currentDate;
        _last_file_received_size = _totalBytesWritten;
        NSUInteger tpReceivedDataSpeed = tpData/tpTime;
        NSString *tpSpeed;
        if (tpReceivedDataSpeed<1024.0) {
            tpSpeed = [NSString stringWithFormat:@"%.2f B/S",(float)tpReceivedDataSpeed];
        }else if (tpReceivedDataSpeed < 1024.0*1024.0){
            tpSpeed = [NSString stringWithFormat:@"%.2f K/S",tpReceivedDataSpeed/1024.0];
        }else{
            tpSpeed = [NSString stringWithFormat:@"%.2f M/S",tpReceivedDataSpeed/1024.0/1024.0];
        }
        self.speed = tpSpeed;
    }
}

/**
 *  NSStringmd5加密
 *
 *  @return NSString
 */
-(NSString *)stringMD5:(NSString *)md5String
{
    const char *cStr = [md5String UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

@end
