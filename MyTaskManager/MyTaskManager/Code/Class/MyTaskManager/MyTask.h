//
//  MyTask.h
//  MyTaskManager
//
//  Created by 蔡成汉 on 2017/3/17.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,TaskState) {
    WillDownload = 0,
    WatingDownload = 1,
    Downloading = 2,
    Suspended = 3,
    Completed = 4,
    Failed = 5
};

@interface MyTask : NSObject

@property (nonatomic , strong , readonly) NSURL *url;
@property (nonatomic , assign , readonly) TaskState state;
@property (nonatomic , strong , readonly) NSString *fileName;
@property (nonatomic , strong , readonly) NSString *fileType;
@property (nonatomic , strong , readonly) NSString *filePath;
@property (nonatomic , assign , readonly) NSUInteger bytesWritten;
@property (nonatomic , assign , readonly) NSUInteger totalBytesWritten;
@property (nonatomic , assign , readonly) NSUInteger totalBytesExpectedToWrite;
@property (nonatomic , strong , readonly) NSString *speed;
@property (nonatomic , strong , readonly) NSString *time;
@property (nonatomic , strong , readonly) NSError *error;

/**
 重写init方法

 @param url 任务url
 @return 实例化的task
 */
-(instancetype)initWithURL:(NSURL *)url;

@end
