//
//  MyTaskManager.m
//  MyTaskManager
//
//  Created by 蔡成汉 on 2017/3/17.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import "MyTaskManager.h"
#import <objc/runtime.h>

typedef void (^ProgressCallBack)(MyTask *task);
typedef void (^StartCallBack)(MyTask *task);
typedef void (^FinishedCallBack)(MyTask *task);

static MyTaskManager *taskManager = nil;

@interface MyTaskManager ()

@property (nonatomic , strong , readwrite) NSMutableArray <MyTask *> *downloadingTasks;
@property (nonatomic , strong , readwrite) NSMutableArray <MyTask *> *finishedTasks;
@property (nonatomic , strong , readwrite) NSMutableArray <MyTask *> *failedTasks;

/**
 任务下载列表：只负责任务的下载
 */
@property (nonatomic , strong) NSMutableArray <NSURLSessionDownloadTask *> *taskList;

/**
 AFURLSessionManager
 */
@property (nonatomic , strong) AFURLSessionManager *manager;

/**
 临时任务存放路径
 */
@property (nonatomic , strong) NSString *tmpPath;

@property (nonatomic , copy) ProgressCallBack progressCallBack;
@property (nonatomic , copy) StartCallBack startCallBack;
@property (nonatomic , copy) FinishedCallBack finishedCallBack;

@end

@implementation MyTaskManager

/**
 create task manager
 
 @return task manager
 */
+(instancetype)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        taskManager = [[super allocWithZone:NULL]init];
    });
    return taskManager;
}

+(instancetype)allocWithZone:(struct _NSZone *)zone{
    return [MyTaskManager shareManager];
}

-(instancetype)copyWithZone:(NSZone *)zone{
    return [MyTaskManager shareManager];
}

-(instancetype)init{
    self = [super init];
    if (!self) {
        return nil;
    }
    self.finishedTasks = [NSMutableArray array];
    self.downloadingTasks = [NSMutableArray array];
    self.failedTasks = [NSMutableArray array];
    
    self.taskList = [NSMutableArray array];
    self.manager = [[AFURLSessionManager alloc]init];
    
    //加载已完成任务
    [self loadFinishedTask];
    //加载缓存任务
    [self loadTmpTask];
    //加载失败任务
    [self loadFailedTask];
    
    __weak typeof(self)WeakSelf = self;
    [self.manager setDownloadTaskDidWriteDataBlock:^(NSURLSession * _Nonnull session, NSURLSessionDownloadTask * _Nonnull downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        if (WeakSelf.downloadingTasks.count > 0) {
            for (int i = 0; i<self.downloadingTasks.count; i++) {
                MyTask *tpTask = [WeakSelf.downloadingTasks objectAtIndex:i];
                NSURLSessionDownloadTask *_downloadTask = [tpTask valueForKey:@"downloadTask"];
                if (_downloadTask == downloadTask) {
                    [tpTask setValue:[NSNumber numberWithUnsignedInteger:bytesWritten] forKey:@"bytesWritten"];
                    [tpTask setValue:[NSNumber numberWithUnsignedInteger:totalBytesWritten] forKey:@"totalBytesWritten"];
                    NSUInteger expectedToWrite = [[tpTask valueForKey:@"totalBytesExpectedToWrite"]unsignedIntegerValue];
                    if (expectedToWrite < totalBytesExpectedToWrite) {
                        [tpTask setValue:[NSNumber numberWithUnsignedInteger:totalBytesExpectedToWrite] forKey:@"totalBytesExpectedToWrite"];
                    }
                    //保存下载信息到文件
                    [WeakSelf saveTask:tpTask];
                    if (WeakSelf.progressCallBack) {
                        WeakSelf.progressCallBack(tpTask);
                    }
                }
            }
        }
    }];
    
    return self;
}

/**
 add one task
 
 @param task task
 */
-(void)addTask:(MyTask *)task{
    //检查任务是否已经下载：若已经下载，则block回调错误。若返回YES，则重新添加下载；若返回NO，则不做任何处理。
    //检查任务是否已经在队列中：若已在下载队列中，则block回调错误。若返回YES，则重新添加下载；若返回NO，则不做任何处理。
    //添加任务
    BOOL reload = NO;
    NSError *error = nil;
    task = [[MyTask alloc]initWithURL:task.url];
    [task setValue:self forKey:@"manager"];
    if ([self taskIsLoaded:task]) {
        //任务已下载
        error = [NSError errorWithDomain:@"任务已下载" code:0 userInfo:nil];
    }
    if ([self taskIsInTmp:task]) {
        //任务已在队列中
        error = [NSError errorWithDomain:@"任务已经在缓存中" code:0 userInfo:nil];
    }
    if ([self.delegate respondsToSelector:@selector(taskWillAdd:error:)]) {
        reload = [self.delegate taskWillAdd:task error:error];
    }
    if ((error && reload) || error == nil) {
        //重新下载 -- 需清理已存在的任务
        if (error) {
            [self delTask:task willDeleteCallBack:^(NSError *error) {
            } didDeleteCallBack:^{
            }];
        }
        [task setValue:[NSNumber numberWithUnsignedInteger:WatingDownload] forKey:@"state"];
        [self.downloadingTasks addObject:task];
        [self saveTask:task];
        if ([self.delegate respondsToSelector:@selector(taskDidAdd:)]) {
            [self.delegate taskDidAdd:task];
        }
    }
    [self runTask];
}

/**
 删除任务
 
 @param task 目标任务
 */
-(void)deleteTask:(MyTask *)task{
    //停止任务
    //删除文件
    [self delTask:task willDeleteCallBack:^(NSError *error) {
        if ([self.delegate respondsToSelector:@selector(taskWillDelete:error:)]) {
            [self.delegate taskWillDelete:task error:error];
        }
    } didDeleteCallBack:^{
        if ([self.delegate respondsToSelector:@selector(taskDidDelete:)]) {
            [self.delegate taskDidDelete:task];
        }
    }];
}

/**
 执行指定任务：当当前任务在执行队列中，则不予以操作；
 
 @param task 目标任务
 */
-(void)resume:(MyTask *)task{
    //判断可执行任务数是否达到最大值：如果没有达到最大值，则更改其状态优先下载；若达到了最大值，则终止一个任务让其等待，同时更改当前任务状态让其优先执行。
    //获取队列中正在执行、将要执行、等待执行的任务数
    NSInteger downloading_count = 0;
    NSInteger will_downloading_count = 0;
    NSInteger waiting_downloading_count = 0;
    for (int i = 0; i<self.downloadingTasks.count; i++) {
        MyTask *tpTask = [self.downloadingTasks objectAtIndex:i];
        if (tpTask.state == Downloading) {
            downloading_count = downloading_count + 1;
        }else if (tpTask.state == WillDownload){
            will_downloading_count = will_downloading_count + 1;
        }else if (tpTask.state == WatingDownload){
            waiting_downloading_count = waiting_downloading_count + 1;
        }
    }
    //获取可执行任务数
    NSInteger sepCount = self.maxCount - downloading_count;
    if (sepCount <= 0) {
        //队列已满，则终止一个任务
        if (downloading_count > 0) {
            NSInteger tp_count = downloading_count;
            for (int i = 0; i<self.downloadingTasks.count; i++) {
                MyTask *tpTask = [self.downloadingTasks objectAtIndex:i];
                if (tpTask.state == Downloading) {
                    tp_count = tp_count - 1;
                    if (tp_count == 0) {
                        [tpTask setValue:[NSNumber numberWithUnsignedInteger:WatingDownload] forKey:@"state"];
                        NSURLSessionDownloadTask *downloadTask = [tpTask valueForKey:@"downloadTask"];
                        [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                        }];
                        break;
                    }
                }
            }
        }
    }
    [task setValue:[NSNumber numberWithUnsignedInteger:WillDownload] forKey:@"state"];
    [self runTask];
}

/**
 暂停指定任务：如果任务正在执行中，同时将任务移动到等待队列中
 
 @param task 目标任务
 */
-(void)suspend:(MyTask *)task{
    [task setValue:[NSNumber numberWithUnsignedInteger:Suspended] forKey:@"state"];
    NSURLSessionDownloadTask *downloadTask = [task valueForKey:@"downloadTask"];
    [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
    }];
    [self runTask];
}

/**
 下载进度回调：回调多个任务下载进度，在子线程中
 
 @param callBack 下载进度回调
 */
-(void)downloadProgressCallBack:(void(^)(MyTask *task))callBack{
    self.progressCallBack = callBack;
}

/**
 下载开始回调
 
 @param callBack 下载开始回调
 */
-(void)downloadStartCallBack:(void(^)(MyTask *task))callBack{
    self.startCallBack = callBack;
}

/**
 下载结束回调
 
 @param callBack 下载结束回调
 */
-(void)downloadFinishedCallBack:(void(^)(MyTask *))callBack{
    self.finishedCallBack = callBack;
}

#pragma mark - 执行任务

/**
 执行任务
 */
-(void)runTask{
    if (self.downloadingTasks.count > 0) {
        //获取队列中正在执行、将要执行、等待执行的任务数
        NSInteger downloading_count = 0;
        NSInteger will_downloading_count = 0;
        NSInteger waiting_downloading_count = 0;
        for (int i = 0; i<self.downloadingTasks.count; i++) {
            MyTask *tpTask = [self.downloadingTasks objectAtIndex:i];
            if (tpTask.state == Downloading) {
                downloading_count = downloading_count + 1;
            }else if (tpTask.state == WillDownload){
                will_downloading_count = will_downloading_count + 1;
            }else if (tpTask.state == WatingDownload){
                waiting_downloading_count = waiting_downloading_count + 1;
            }
        }
        //获取可执行任务数
        NSInteger sepCount = self.maxCount - downloading_count;
        if (sepCount > 0) {
            //获取可执行任务数量
            if (will_downloading_count > sepCount) {
                //通常情况下会进入这个判断，但不执行for循环
                NSInteger t_count = will_downloading_count - sepCount;
                for (int i = 0; i<self.downloadingTasks.count; i++) {
                    MyTask *tpTask = [self.downloadingTasks objectAtIndex:i];
                    if (tpTask.state == WillDownload) {
                        [tpTask setValue:[NSNumber numberWithUnsignedInteger:WatingDownload] forKey:@"state"];
                        t_count = t_count - 1;
                        if (t_count <= 0) {
                            break;
                        }
                    }
                }
            }else{
                //从等待队列中，预取出指定数量的任务，更改状态，预下载
                NSInteger t_count = sepCount - will_downloading_count;
                if (t_count > 0) {
                    for (int i = 0; i<self.downloadingTasks.count; i++) {
                        MyTask *tpTask = [self.downloadingTasks objectAtIndex:i];
                        if (tpTask.state == WatingDownload) {
                            [tpTask setValue:[NSNumber numberWithUnsignedInteger:WillDownload] forKey:@"state"];
                            t_count = t_count - 1;
                            if (t_count <= 0) {
                                break;
                            }
                        }
                    }
                }
            }
            
            //任务预处理完毕、现在执行状态为WillDownload的任务
            NSInteger t_count = sepCount;
            for (int i = 0; i<self.downloadingTasks.count; i++) {
                MyTask *tpTask = [self.downloadingTasks objectAtIndex:i];
                if (tpTask.state == WillDownload) {
                    if (![tpTask valueForKey:@"manager"]) {
                        [tpTask setValue:self forKey:@"manager"];
                    }
                    [self downloadTask:tpTask];
                    t_count = t_count - 1;
                    if (t_count <= 0) {
                        break;
                    }
                }
            }
        }
    }
}

/**
 执行任务
 */
-(void)startAll{
    [self runTask];
}

/**
 取消任务：取消所有
 */
-(void)cancleAll{
    //需要将所有将要下载的任务设置为等待状态；正在下载的任务暂停下载
    NSInteger tpMaxCount = self.maxCount;
    self.maxCount = 0;
    if (self.downloadingTasks.count > 0) {
        for (int i = 0; i<self.downloadingTasks.count; i++) {
            MyTask *task = [self.downloadingTasks objectAtIndex:i];
            if (task.state == WillDownload) {
                [task setValue:[NSNumber numberWithUnsignedInteger:WatingDownload] forKey:@"state"];
            }
            if (task.state == Downloading) {
                [task setValue:[NSNumber numberWithUnsignedInteger:WatingDownload] forKey:@"state"];
                NSURLSessionDownloadTask *downloadTask = [task valueForKey:@"downloadTask"];
                [downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
                }];
            }
        }
    }
    self.maxCount = tpMaxCount;
}

#pragma mark - 下载任务

-(void)downloadTask:(MyTask *)task{
    NSURLSessionDownloadTask *downloadTask = [self dolTask:task progress:^(NSProgress *downloadProgress) {
        if ([self.delegate respondsToSelector:@selector(updateProgress:)]) {
            [self.delegate updateProgress:task];
        }
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return [NSURL fileURLWithPath:task.filePath];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(updateProgress:)]) {
            [self.delegate updateProgress:task];
        }
        if (task.state == Suspended) {
            //暂停任务
            if ([self.delegate respondsToSelector:@selector(taskDidSuspend:)]) {
                [self.delegate taskDidSuspend:task];
            }
        }else if(task.state == Downloading){
            [task setValue:error forKey:@"error"];
            if (error) {
                //下载出错
                if (![self taskIsInFailed:task]) {
                    [self.failedTasks addObject:task];
                }
                [task setValue:[NSNumber numberWithInteger:Failed] forKey:@"state"];
            }else{
                //正常下载
                [self.finishedTasks addObject:task];
                [task setValue:[NSNumber numberWithInteger:Completed] forKey:@"state"];
            }
            [self.downloadingTasks removeObject:task];
            [self saveTask:task];
            if ([self.delegate respondsToSelector:@selector(taskDidEnd:)]) {
                [self.delegate taskDidEnd:task];
            }
        }
        if (task.state != WatingDownload) {
            [self runTask];
        }
    }];
    [task setValue:[NSNumber numberWithUnsignedInteger:Downloading] forKey:@"state"];
    [downloadTask resume];
    
    if ([self.delegate respondsToSelector:@selector(taskDidStart:)]) {
        [self.delegate taskDidStart:task];
    }
}

-(NSURLSessionDownloadTask *)dolTask:(MyTask *)task
      progress:(void(^)(NSProgress *downloadProgress))downloadProgressBlock destination:(NSURL * (^)(NSURL *targetPath, NSURLResponse *response))destination
completionHandler:(void (^)(NSURLResponse *response, NSURL *filePath, NSError *error))completionHandler{
    NSURLSessionDownloadTask *downloadTask = nil;
    NSData *resumeData = nil;
    NSString *tmpPath = [task valueForKey:@"tmpPath"];
    if (tmpPath && tmpPath.length>0) {
        //已在缓存中，则从缓存中继续下载；
        NSData *tmpData = [NSData dataWithContentsOfFile:[NSHomeDirectory() stringByAppendingPathComponent:tmpPath]];
        if (tmpData) {
            NSMutableDictionary *resumeDataDict = [NSMutableDictionary dictionary];
            NSMutableURLRequest *newResumeRequest = [NSMutableURLRequest requestWithURL:task.url];
            [newResumeRequest addValue:[NSString stringWithFormat:@"bytes=%ld-",tmpData.length] forHTTPHeaderField:@"Range"];
            NSData *newResumeRequestData = [NSKeyedArchiver archivedDataWithRootObject:newResumeRequest];
            [resumeDataDict setValue:[task.url absoluteString] forKey:@"NSURLSessionDownloadURL"];
            [resumeDataDict setObject:[NSNumber numberWithInteger:tmpData.length]forKey:@"NSURLSessionResumeBytesReceived"];
            [resumeDataDict setObject:newResumeRequestData forKey:@"NSURLSessionResumeCurrentRequest"];
            [resumeDataDict setObject:[[NSHomeDirectory() stringByAppendingPathComponent:tmpPath] lastPathComponent]forKey:@"NSURLSessionResumeInfoTempFileName"];
            resumeData = [NSPropertyListSerialization dataWithPropertyList:resumeDataDict format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
        }
    }
    if (resumeData && resumeData.length > 0) {
        //在缓存中，则断点下载
        downloadTask = [self.manager downloadTaskWithResumeData:resumeData progress:^(NSProgress * _Nonnull downloadProgress) {
            downloadProgressBlock(downloadProgress);
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return destination(targetPath,response);
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            completionHandler(response,filePath,error);
        }];
        [task setValue:downloadTask forKey:@"downloadTask"];
    }else{
        //不在缓存中，则重新下载；
        NSURLRequest *request = [NSURLRequest requestWithURL:task.url];
        downloadTask = [self.manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
            downloadProgressBlock(downloadProgress);
        } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
            return destination(targetPath,response);
        } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
            completionHandler(response,filePath,error);
        }];
        [task setValue:downloadTask forKey:@"downloadTask"];
        [self loadTmp:task];
    };
    return downloadTask;
}

-(void)delTask:(MyTask *)task willDeleteCallBack:(void(^)(NSError *error))willDeleteCallBack didDeleteCallBack:(void(^)(void))didDeleteCallBack{
    if (![task valueForKey:@"manager"]) {
        [task setValue:self forKey:@"manager"];
    }
    NSURLSessionDownloadTask *downloadTask = [task valueForKey:@"downloadTask"];
    [downloadTask cancel];
    if ([[NSFileManager defaultManager]fileExistsAtPath:task.filePath]) {
        //删除文件
        NSError *error;
        [[NSFileManager defaultManager]removeItemAtPath:task.filePath error:&error];
        if (error) {
            willDeleteCallBack(error);
        }
        //更新plist文件
        NSString *tpPath = [self.tmpPath stringByAppendingPathComponent:@"FinishedTask.plist"];
        NSMutableArray *tpArray = [[NSMutableArray alloc] initWithContentsOfFile:tpPath];
        if (tpArray) {
            for (int i = 0; i<tpArray.count; i++) {
                NSDictionary *tpDic = [tpArray objectAtIndex:i];
                if ([[tpDic objectForKey:@"url"]isEqualToString:[task.url absoluteString]]) {
                    [tpArray removeObject:tpDic];
                    break;
                }
            }
        }
        [tpArray writeToFile:tpPath atomically:YES];
        for (int i = 0; i<self.finishedTasks.count; i++) {
            MyTask *tpTask = [self.finishedTasks objectAtIndex:i];
            if ([[tpTask.url absoluteString]isEqualToString:[task.url absoluteString]]) {
                [self.finishedTasks removeObject:tpTask];
                break;
            }
        }
    }
    NSString *path = [self.tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",[task valueForKey:@"saveName"]]];
    if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
        //删除文件
        NSError *error;
        [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
        if (error) {
            willDeleteCallBack(error);
        }
        //更新数据
        for (int i = 0; i<self.downloadingTasks.count; i++) {
            MyTask *tpTask = [self.downloadingTasks objectAtIndex:i];
            if ([[tpTask.url absoluteString]isEqualToString:[task.url absoluteString]]) {
                NSString *tmpPath = [tpTask valueForKey:@"tmpPath"];
                if (tmpPath) {
                    [[NSFileManager defaultManager]removeItemAtPath:[NSHomeDirectory() stringByAppendingPathComponent:tmpPath] error:nil];
                }
                [self.downloadingTasks removeObject:tpTask];
                break;
            }
        }
    }
    NSString *failedPath = [self.tmpPath stringByAppendingPathComponent:@"FailedTask.plist"];
    NSMutableArray *failedArray = [NSMutableArray arrayWithContentsOfFile:failedPath];
    if (failedArray) {
        for (int i=0; i<failedArray.count; i++) {
            NSDictionary *tpDic = [failedArray objectAtIndex:i];
            if ([[tpDic objectForKey:@"url"]isEqualToString:[task.url absoluteString]]) {
                [failedArray removeObject:tpDic];
                break;
            }
        }
        [failedArray writeToFile:failedPath atomically:YES];
        
        for (int i = 0; i<self.failedTasks.count; i++) {
            MyTask *tpTask = [self.failedTasks objectAtIndex:i];
            if ([[tpTask.url absoluteString]isEqualToString:[task.url absoluteString]]) {
                [self.failedTasks removeObject:tpTask];
                break;
            }
        }
    }
    didDeleteCallBack();
}

#pragma mark - 任务是否已经下载

-(BOOL)taskIsLoaded:(MyTask *)task{
    return [[NSFileManager defaultManager]fileExistsAtPath:task.filePath];
}

#pragma mark - 任务是否在缓存中

-(BOOL)taskIsInTmp:(MyTask *)task{
    NSString *path = [self.tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",[task valueForKey:@"saveName"]]];
    return [[NSFileManager defaultManager]fileExistsAtPath:path];
}

#pragma mark - 任务是否已在失败队列中

-(BOOL)taskIsInFailed:(MyTask *)task{
    NSString *tpPath = [self.tmpPath stringByAppendingPathComponent:@"FailedTask.plist"];
    NSArray *tpArray = [NSArray arrayWithContentsOfFile:tpPath];
    for (int i = 0; i<tpArray.count; i++) {
        MyTask *tpTask = [self getDicTask:[tpArray objectAtIndex:i]];
        if ([[tpTask valueForKey:@"saveName"] isEqualToString:[task valueForKey:@"saveName"]]) {
            return YES;
            break;
        }
    }
    return NO;
}


#pragma mark - 加载完成任务
-(void)loadFinishedTask{
    NSString *finishPlistPath = [self.tmpPath stringByAppendingPathComponent:@"FinishedTask.plist"];
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:finishPlistPath];
    if (fileExist) {
        NSMutableArray *array = [[NSMutableArray alloc] initWithContentsOfFile:finishPlistPath];
        for (NSDictionary *dic in array) {
            //添加结果
            MyTask *tpTask = [self getDicTask:dic];
            [tpTask setValue:[NSNumber numberWithUnsignedInteger:Completed] forKey:@"state"];
            [self.finishedTasks addObject:tpTask];
        }
    }
}

#pragma mark - 加载缓存任务
-(void)loadTmpTask{
    NSError *error;
    NSArray *filelist = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.tmpPath error:&error];
    if(!error){
        NSMutableArray *array = [[NSMutableArray alloc]init];
        for(NSString *file in filelist) {
            NSString *filetype = [file  pathExtension];
            if([filetype isEqualToString:@"plist"]){
                if (![file isEqualToString:@"FinishedTask.plist"] && ![file isEqualToString:@"FailedTask.plist"]) {
                    NSDictionary *tpDic = [NSDictionary dictionaryWithContentsOfFile:[self.tmpPath stringByAppendingPathComponent:file]];
                    [array addObject:[self getDicTask:tpDic]];
                }
            }
        }
        NSArray *tasks = [self sortbyTime:array];
        [self.downloadingTasks addObjectsFromArray:tasks];
    }
}

#pragma mark - 加载失败任务
-(void)loadFailedTask{
    NSString *FailedTaskPath = [self.tmpPath stringByAppendingPathComponent:@"FailedTask.plist"];
    BOOL fileExist = [[NSFileManager defaultManager] fileExistsAtPath:FailedTaskPath];
    if (fileExist) {
        NSMutableArray *array = [[NSMutableArray alloc] initWithContentsOfFile:FailedTaskPath];
        for (NSDictionary *dic in array) {
            //添加结果
            MyTask *tpTask = [self getDicTask:dic];
            [tpTask setValue:[NSNumber numberWithUnsignedInteger:Failed] forKey:@"state"];
            [self.failedTasks addObject:tpTask];
        }
    }
}

/**
 根据时间进行排序
 
 @param array 任务队列
 @return 新队列
 */
- (NSArray *)sortbyTime:(NSArray *)array
{
    NSArray *sorteArray1 = [array sortedArrayUsingComparator:^(id obj1, id obj2){
        MyTask *task1 = (MyTask *)obj1;
        MyTask *task2 = (MyTask *)obj2;
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *date1 = [df dateFromString:task1.time];
        NSDate *date2 = [df dateFromString:task2.time];
        if ([[date1 earlierDate:date2]isEqualToDate:date2]) {
            return (NSComparisonResult)NSOrderedDescending;
        }
        if ([[date1 earlierDate:date2]isEqualToDate:date1]) {
            return (NSComparisonResult)NSOrderedAscending;
        }
        return (NSComparisonResult)NSOrderedSame;
    }];
    return sorteArray1;
}


#pragma mark - 获取已完成/缓存任务

-(MyTask *)getDicTask:(NSDictionary *)dic{
    MyTask *task = [[MyTask alloc]initWithURL:[NSURL URLWithString:[dic objectForKey:@"url"]]];
    [task setValue:self forKey:@"manager"];
    [task setValue:[NSNumber numberWithUnsignedInteger:WatingDownload] forKey:@"state"];
    [task setValue:[dic objectForKey:@"totalBytesWritten"] forKey:@"totalBytesWritten"];
    [task setValue:[dic objectForKey:@"totalBytesExpectedToWrite"] forKey:@"totalBytesExpectedToWrite"];
    [task setValue:[dic objectForKey:@"tmpPath"] forKey:@"tmpPath"];
    [task setValue:[dic objectForKey:@"time"] forKey:@"time"];
    return task;
}



#pragma mark - 保存任务
-(void)saveTask:(MyTask *)task{
    if (task.state == WatingDownload || task.state == Downloading) {
        //下载中
        NSString *path = [self.tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",[task valueForKey:@"saveName"]]];
        NSMutableDictionary *tpDic = [NSMutableDictionary dictionary];
        [tpDic setValue:[task.url absoluteString] forKey:@"url"];
        [tpDic setValue:task.fileName forKey:@"fileName"];
        [tpDic setValue:task.fileType forKey:@"fileType"];
        [tpDic setValue:[NSNumber numberWithUnsignedInteger:task.totalBytesWritten] forKey:@"totalBytesWritten"];
        [tpDic setValue:[NSNumber numberWithUnsignedInteger:task.totalBytesExpectedToWrite] forKey:@"totalBytesExpectedToWrite"];
        [tpDic setValue:[task valueForKey:@"saveName"] forKey:@"saveName"];
        [tpDic setValue:[task valueForKey:@"tmpPath"] forKey:@"tmpPath"];
        [tpDic setValue:task.time forKey:@"time"];
        [tpDic writeToFile:path atomically:YES];
    }else if (task.state == Completed){
        //下载完成
        NSString *path = [self.tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",[task valueForKey:@"saveName"]]];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
        }
        
        NSMutableArray *array = [NSMutableArray array];
        for (MyTask *task in self.finishedTasks) {
            NSMutableDictionary *tpDic = [NSMutableDictionary dictionary];
            [tpDic setValue:[task.url absoluteString] forKey:@"url"];
            [tpDic setValue:task.fileName forKey:@"fileName"];
            [tpDic setValue:task.fileType forKey:@"fileType"];
            [tpDic setValue:[NSNumber numberWithUnsignedInteger:task.totalBytesWritten] forKey:@"totalBytesWritten"];
            [tpDic setValue:[NSNumber numberWithUnsignedInteger:task.totalBytesExpectedToWrite] forKey:@"totalBytesExpectedToWrite"];
            [tpDic setValue:[task valueForKey:@"saveName"] forKey:@"saveName"];
            [tpDic setValue:[task valueForKey:@"tmpPath"] forKey:@"tmpPath"];
            [tpDic setValue:task.time forKey:@"time"];
            [array addObject:tpDic];
        }
        NSString *tpPath = [self.tmpPath stringByAppendingPathComponent:@"FinishedTask.plist"];
        [array writeToFile:tpPath atomically:YES];
    }else if (task.state == Failed){
        //下载失败 -- 删除文件、tmp和plist
        if ([[NSFileManager defaultManager]fileExistsAtPath:task.filePath]) {
            [[NSFileManager defaultManager]removeItemAtPath:task.filePath error:nil];
        }
        NSString *tmpPath = [task valueForKey:@"tmpPath"];
        if (tmpPath && tmpPath.length >0) {
            if ([[NSFileManager defaultManager]fileExistsAtPath:[NSHomeDirectory() stringByAppendingPathComponent:tmpPath]]) {
                [[NSFileManager defaultManager]removeItemAtPath:[NSHomeDirectory() stringByAppendingPathComponent:tmpPath] error:nil];
            }
        }
        NSString *path = [self.tmpPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",[task valueForKey:@"saveName"]]];
        if ([[NSFileManager defaultManager]fileExistsAtPath:path]) {
            [[NSFileManager defaultManager]removeItemAtPath:path error:nil];
        }
        NSMutableArray *array = [NSMutableArray array];
        for (MyTask *task in self.failedTasks) {
            NSMutableDictionary *tpDic = [NSMutableDictionary dictionary];
            [tpDic setValue:[task.url absoluteString] forKey:@"url"];
            [tpDic setValue:task.fileName forKey:@"fileName"];
            [tpDic setValue:task.fileType forKey:@"fileType"];
            [tpDic setValue:[NSNumber numberWithUnsignedInteger:task.totalBytesWritten] forKey:@"totalBytesWritten"];
            [tpDic setValue:[NSNumber numberWithUnsignedInteger:task.totalBytesExpectedToWrite] forKey:@"totalBytesExpectedToWrite"];
            [tpDic setValue:[task valueForKey:@"saveName"] forKey:@"saveName"];
            [tpDic setValue:[task valueForKey:@"tmpPath"] forKey:@"tmpPath"];
            [tpDic setValue:task.time forKey:@"time"];
            [array addObject:tpDic];
        }
        NSString *tpPath = [self.tmpPath stringByAppendingPathComponent:@"FailedTask.plist"];
        [array writeToFile:tpPath atomically:YES];
    }
}

#pragma mark - 获取临时缓存路径

/**
 获取缓存路径
 
 @param task task
 */
-(void)loadTmp:(MyTask *)task{
    NSURLSessionDownloadTask *downloadTask = [task valueForKey:@"downloadTask"];
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([downloadTask class], &outCount);
    for (i = 0; i<outCount; i++) {
        objc_property_t property = properties[i];
        const char* char_f =property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:char_f];
        if ([@"downloadFile" isEqualToString:propertyName]) {
            id propertyValue = [downloadTask valueForKey:(NSString *)propertyName];
            unsigned int downloadFileoutCount, downloadFileIndex;
            objc_property_t *downloadFileproperties = class_copyPropertyList([propertyValue class], &downloadFileoutCount);
            for (downloadFileIndex = 0; downloadFileIndex < downloadFileoutCount; downloadFileIndex++) {
                objc_property_t downloadFileproperty = downloadFileproperties[downloadFileIndex];
                const char* downloadFilechar_f =property_getName(downloadFileproperty);
                NSString *downloadFilepropertyName = [NSString stringWithUTF8String:downloadFilechar_f];
                if([@"path" isEqualToString:downloadFilepropertyName]){
                    id downloadFilepropertyValue = [propertyValue valueForKey:(NSString *)downloadFilepropertyName];
                    if(downloadFilepropertyValue){
                        NSString *tmpPath = [downloadFilepropertyValue stringByReplacingOccurrencesOfString:NSHomeDirectory() withString:@""];
                        [task setValue:tmpPath forKey:@"tmpPath"];
                    }
                    break;
                }
            }
            free(downloadFileproperties);
        }else {
            continue;
        }
    }
    free(properties);
}


#pragma mark - get方法，获取数据

/**
 获取最大并发数

 @return 最大并发数
 */
-(NSInteger)maxCount{
    if (!_maxCount) {
        _maxCount = 1;
    }
    return _maxCount;
}


/**
 获取下载路径

 @return 下载路径
 */
-(NSString *)path{
    if (!_path) {
        _path = [self createPath:@"MyTaskManager/DownloadPath"];
    }
    return _path;
}

/**
 获取临时文件路径

 @return 临时文件路径
 */
-(NSString *)tmpPath{
    if (!_tmpPath) {
        _tmpPath = [self createPath:@"MyTaskManager/TmpPath"];
    }
    return _tmpPath;
}

/**
 获取文件路径

 @param fileName 文件名
 @return 文件路径
 */
-(NSString *)filePath:(NSString *)fileName{
    return [self.path stringByAppendingPathComponent:fileName];
}

/**
 创建文件夹

 @param path 文件夹名
 @return 创建的文件夹
 */
-(NSString *)createPath:(NSString *)path{
    NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *filePath = [libDir stringByAppendingPathComponent:path];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL fileExist = [fileManager fileExistsAtPath:filePath];
    if (!fileExist) {
        BOOL result = [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        if (!result) {
            return nil;
        }
    }
    return filePath;
}

@end
