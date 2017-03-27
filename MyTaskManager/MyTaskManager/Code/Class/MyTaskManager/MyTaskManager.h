//
//  MyTaskManager.h
//  MyTaskManager
//
//  Created by 蔡成汉 on 2017/3/17.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyTask.h"

@protocol MyTaskManagerDelegate;

@interface MyTaskManager : NSObject<NSCopying>

@property (nonatomic , weak) id<MyTaskManagerDelegate>delegate;

/**
 任务最大并发数，默认为1
 */
@property (nonatomic , assign) NSInteger maxCount;

/**
 下载目录
 */
@property (nonatomic , strong) NSString *path;

/**
 正在执行中的任务：等待下载、将要下载、正在下载
 */
@property (nonatomic , strong , readonly) NSMutableArray <MyTask *> *downloadingTasks;

/**
 下载完成的任务
 */
@property (nonatomic , strong , readonly) NSMutableArray <MyTask *> *finishedTasks;

/**
 下载失败的任务
 */
@property (nonatomic , strong , readonly) NSMutableArray <MyTask *> *failedTasks;

/**
 create task manager
 
 @return task manager
 */
+(instancetype)shareManager;

/**
 add one task

 @param task task
 */
-(void)addTask:(MyTask *)task;

/**
 删除任务
 
 @param task 目标任务
 */
-(void)deleteTask:(MyTask *)task;

/**
 执行指定任务：当当前任务在执行队列中，则不予以操作；
 
 @param task 目标任务
 */
-(void)resume:(MyTask *)task;

/**
 暂停指定任务：如果任务正在执行中，同时将任务移动到等待队列中
 
 @param task 目标任务
 */
-(void)suspend:(MyTask *)task;

/**
 执行任务
 */
-(void)startAll;

/**
 取消任务：取消所有
 */
-(void)cancleAll;

/**
 下载进度回调：回调多个任务下载进度，在子线程中

 @param callBack 下载进度回调
 */
-(void)downloadProgressCallBack:(void(^)(MyTask *task))callBack;


@end


@protocol MyTaskManagerDelegate <NSObject>

@optional

-(BOOL)taskWillAdd:(MyTask *)task error:(NSError *)error;
-(void)taskDidAdd:(MyTask *)task;
-(void)taskWillDelete:(MyTask *)task error:(NSError *)error;
-(void)taskDidDelete:(MyTask *)task;
-(void)taskDidStart:(MyTask *)task;
-(void)taskDidSuspend:(MyTask *)task;
-(void)taskDidEnd:(MyTask *)task;
-(void)updateProgress:(MyTask *)task;

@end
