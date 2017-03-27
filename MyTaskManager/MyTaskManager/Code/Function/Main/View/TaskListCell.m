//
//  TaskListCell.m
//  MyTaskManager
//
//  Created by 蔡成汉 on 2017/3/2.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import "TaskListCell.h"

@interface TaskListCell ()

@property (nonatomic , strong) UILabel *titleLabel;

@property (nonatomic , strong) UIButton *addButton;

@end

@implementation TaskListCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initialTaskListCell];
    }
    return self;
}

-(void)initialTaskListCell{
    _titleLabel = [[UILabel alloc]init];
    [self.contentView addSubview:_titleLabel];
    
    _addButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_addButton setTitle:@"下载" forState:UIControlStateNormal];
    [_addButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_addButton setBackgroundColor:[UIColor colorWithRed:245.0/255.0 green:76.0/255.0 blue:72.0/255.0 alpha:1]];
    _addButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [_addButton addTarget:self action:@selector(addButtonIsTouch) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_addButton];
    
    [_titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(10);
        make.left.equalTo(self.contentView.mas_left).offset(17);
        make.right.equalTo(self.contentView.mas_right).offset(-60);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-5);
    }];
    
    [_addButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_titleLabel.mas_right).offset(5);
        make.right.equalTo(self.contentView.mas_right).offset(-17);
        make.height.equalTo(@25);
        make.centerY.equalTo(_titleLabel.mas_centerY);
    }];
}

-(void)setTask:(MyTask *)task{
    _task = task;
    _titleLabel.text = task.fileName;
}

-(void)addButtonIsTouch{
    [[MyTaskManager shareManager]addTask:_task];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
