//
//  DownloadViewController.m
//  MyTaskManager
//
//  Created by 蔡成汉 on 2017/3/17.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import "DownloadViewController.h"
#import "TaskLoadingCell.h"
#import "TaskLoadedCell.h"
#import "TaskFailedCell.h"
#import "HeaderView.h"

@interface DownloadViewController ()<UITableViewDataSource,UITableViewDelegate,MyTaskManagerDelegate>

/**
 myTableView
 */
@property (nonatomic , strong) UITableView *myTableView;

/**
 downloading
 */
@property (nonatomic , strong) NSMutableArray *downloading;

/**
 downloaded
 */
@property (nonatomic , strong) NSMutableArray *downloaded;

/**
 filed
 */
@property (nonatomic , strong) NSMutableArray *filed;

/**
 dataArray
 */
@property (nonatomic , strong) NSMutableArray *downloadArray;

@end

@implementation DownloadViewController

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [MyTaskManager shareManager].delegate = self;
        [MyTaskManager shareManager].maxCount = 1;
        
        self.downloading = [NSMutableArray array];
        self.downloaded = [NSMutableArray array];
        self.filed = [NSMutableArray array];
        self.downloadArray = [NSMutableArray array];
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.tabBarController.navigationItem.title = @"任务下载";
    
    //设置左右按钮
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc]initWithTitle:@"开始全部" style:UIBarButtonItemStylePlain target:self action:@selector(startAll)];
    self.tabBarController.navigationItem.leftBarButtonItem = leftItem;
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]initWithTitle:@"取消全部" style:UIBarButtonItemStylePlain target:self action:@selector(cancleAll)];
    self.tabBarController.navigationItem.rightBarButtonItem = rightItem;
    
    [self reloadData];
}

-(void)startAll{
    [[MyTaskManager shareManager]startAll];
}

-(void)cancleAll{
    [[MyTaskManager shareManager]cancleAll];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _myTableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _myTableView.dataSource = self;
    _myTableView.delegate = self;
    _myTableView.tableFooterView = [UIView new];
    [self.view addSubview:_myTableView];
    
    [_myTableView registerClass:[TaskLoadingCell class] forCellReuseIdentifier:@"TaskLoadingCell"];
    [_myTableView registerClass:[TaskLoadedCell class] forCellReuseIdentifier:@"TaskLoadedCell"];
    [_myTableView registerClass:[TaskFailedCell class] forCellReuseIdentifier:@"TaskFailedCell"];
    [_myTableView registerClass:[HeaderView class] forHeaderFooterViewReuseIdentifier:@"HeaderView"];
    
    [_myTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    
    [self reloadData];
}

#pragma mark - UITableViewDataSource

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return self.downloadArray.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSArray *tpArray = [self.downloadArray objectAtIndex:section];
    return tpArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *tpArray = [self.downloadArray objectAtIndex:indexPath.section];
    if (indexPath.section == 0) {
        //完成
        TaskLoadedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskLoadedCell"];
        MyTask *task = [tpArray objectAtIndex:indexPath.row];
        cell.task = task;
        return cell;
    }else if (indexPath.section == 1){
        //下载中
        TaskLoadingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskLoadingCell"];
        MyTask *task = [tpArray objectAtIndex:indexPath.row];
        cell.task = task;
        return cell;
    }else{
        //下载失败
        TaskFailedCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskFailedCell"];
        MyTask *task = [tpArray objectAtIndex:indexPath.row];
        cell.task = task;
        return cell;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 70;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    HeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"HeaderView"];
    if (section == 0) {
        headerView.textLabel.text = @"下载完成";
        
    }else if (section == 1){
        headerView.textLabel.text = @"下载中";
    }else{
        headerView.textLabel.text = @"下载失败";
    }
    return headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath{
    return @"删除";
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *tpArray = [self.downloadArray objectAtIndex:indexPath.section];
    MyTask *task = [tpArray objectAtIndex:indexPath.row];
    [[MyTaskManager shareManager]deleteTask:task];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


-(NSString *)fileString{
    //lib
    NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)objectAtIndex:0];
    NSString *filePath = [libDir stringByAppendingPathComponent:@"MyDownloadPath"];
    NSFileManager* fileManager = [NSFileManager defaultManager];
    BOOL fileExist = [fileManager fileExistsAtPath:filePath];
    if (!fileExist) {
        //创建文件夹
        [fileManager createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return filePath;
}

#pragma mark - MyTaskManagerDelegate

-(BOOL)taskWillAdd:(MyTask *)task error:(NSError *)error{
    if (error) {
        NSLog(@"%@",error.domain);
    }
    return NO;
}

-(void)taskDidAdd:(MyTask *)task{
    NSLog(@"添加成功");
    [self reloadData];
}

-(void)taskDidStart:(MyTask *)task{
    NSLog(@"下载开始");
    [self reloadData];
}

-(void)taskDidSuspend:(MyTask *)task{
    NSLog(@"下载暂停");
    [self reloadData];
}

-(void)taskDidEnd:(MyTask *)task{
    if (task.error) {
        NSLog(@"下载失败");
    }else{
        NSLog(@"下载完成");
    }
    [self reloadData];
}

-(void)taskDidDelete:(MyTask *)task{
    NSLog(@"删除成功");
    [self reloadData];
}

-(void)updateProgress:(MyTask *)task{
    dispatch_async(dispatch_get_main_queue(), ^{
       //需要回到主线程，更新下载进度
        NSArray *cellArr = [_myTableView visibleCells];
        for (id obj in cellArr) {
            if([obj isKindOfClass:[TaskLoadingCell class]]) {
                TaskLoadingCell *cell = (TaskLoadingCell *)obj;
                if(cell.task == task) {
                    cell.task = task;
                }
            }
        }
    });
}

-(void)reloadData{
    self.downloaded = [MyTaskManager shareManager].finishedTasks;
    self.downloading = [MyTaskManager shareManager].downloadingTasks;
    self.filed = [MyTaskManager shareManager].failedTasks;
    [self.downloadArray removeAllObjects];
    [self.downloadArray addObject:self.downloaded];
    [self.downloadArray addObject:self.downloading];
    [self.downloadArray addObject:self.filed];
    [_myTableView reloadData];
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
