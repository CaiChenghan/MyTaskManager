//
//  TaskViewController.m
//  MyTaskManager
//
//  Created by 蔡成汉 on 2017/3/17.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import "TaskViewController.h"
#import "TaskListCell.h"

@interface TaskViewController ()<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic , strong) UITableView *myTableView;

@property (nonatomic , strong) NSMutableArray *dataArray;

@end

@implementation TaskViewController

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _dataArray = [NSMutableArray arrayWithArray:[self createTaskArray]];
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.tabBarController.navigationItem.title = @"任务列表";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _myTableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _myTableView.dataSource = self;
    _myTableView.delegate = self;
    _myTableView.tableFooterView = [UIView new];
    [self.view addSubview:_myTableView];
    
    [_myTableView registerClass:[TaskListCell class] forCellReuseIdentifier:@"TaskListCell"];
    
    [_myTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.dataArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    TaskListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskListCell"];
    cell.task = [self.dataArray objectAtIndex:indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

-(NSArray *)createTaskArray{
    NSMutableArray *tpArray = [NSMutableArray array];
    NSURL *url1 = [NSURL URLWithString:@"http://sw.bos.baidu.com/sw-search-sp/softwareee/50045684f7da6/QQ_mac_5.4.1.dmg"];
    MyTask *task1 = [[MyTask alloc]initWithURL:url1];
    [tpArray addObject:task1];
    
    NSURL *url2 = [NSURL URLWithString:@"http://sw.bos.baidu.com/sw-search-sp/software/de4fe04c2280e/SogouInput_mac_4.0.0.3127.dmg"];
    MyTask *task2 = [[MyTask alloc]initWithURL:url2];
    [tpArray addObject:task2];
    
    NSURL *url3 = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1489478928412&di=8f26723ddceec775cbeab789f54d4496&imgtype=0&src=http%3A%2F%2Fimg.taopic.com%2Fuploads%2Fallimg%2F110731%2F1283-110I10Z55764.jpg"];
    MyTask *task3 = [[MyTask alloc]initWithURL:url3];
    [tpArray addObject:task3];
    
    NSURL *url4 = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1489478928414&di=b5a21234a686ae792f3f56caedc4fed7&imgtype=0&src=http%3A%2F%2Fpic.qiantucdn.com%2F58pic%2F18%2F30%2F22%2F19P58PICdxw_1024.jpg"];
    MyTask *task4 = [[MyTask alloc]initWithURL:url4];
    [tpArray addObject:task4];
    
    NSURL *url5 = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1489478928416&di=66cc8bb508fbac4c8769516b00d0f84e&imgtype=0&src=http%3A%2F%2Fimg15.3lian.com%2F2015%2Ff2%2F50%2Fd%2F71.jpg"];
    MyTask *task5 = [[MyTask alloc]initWithURL:url5];
    [tpArray addObject:task5];
    
    NSURL *url6 = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1489478928416&di=3866d6608faad0efde69f5cc1d599b9e&imgtype=0&src=http%3A%2F%2Fpic73.nipic.com%2Ffile%2F20150724%2F9448607_174837076000_2.jpg"];
    MyTask *task6 = [[MyTask alloc]initWithURL:url6];
    [tpArray addObject:task6];
    
    NSURL *url7 = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1489478928415&di=b6ea5e091434ebdf2a14d0edf6c450d6&imgtype=0&src=http%3A%2F%2Fpic17.nipic.com%2F20111015%2F4695500_224140299162_2.jpg"];
    MyTask *task7 = [[MyTask alloc]initWithURL:url7];
    [tpArray addObject:task7];
    
    NSURL *url8 = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1489478928412&di=b89aa11f760ace66c0236751d96f154b&imgtype=0&src=http%3A%2F%2Fpic13.nipic.com%2F20110324%2F2531170_161545930116_2.jpg"];
    MyTask *task8 = [[MyTask alloc]initWithURL:url8];
    [tpArray addObject:task8];
    
    NSURL *url9 = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1489478928411&di=710a46605b3a15412caca4779aeb4f9c&imgtype=0&src=http%3A%2F%2Fpic15.nipic.com%2F20110801%2F3009023_170610172126_2.jpg"];
    MyTask *task9 = [[MyTask alloc]initWithURL:url9];
    [tpArray addObject:task9];
    
    NSURL *url10 = [NSURL URLWithString:@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1489479036751&di=05a238f4222bf03929e94f43878b0e9d&imgtype=0&src=http%3A%2F%2Fimg05.tooopen.com%2Fimages%2F20150701%2Ftooopen_sy_132481769552.jpg"];
    MyTask *task10 = [[MyTask alloc]initWithURL:url10];
    [tpArray addObject:task10];
    
    return tpArray;
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
