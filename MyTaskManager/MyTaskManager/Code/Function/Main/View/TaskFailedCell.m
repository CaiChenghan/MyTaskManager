//
//  TaskFailedCell.m
//  MyTaskManager
//
//  Created by 蔡成汉 on 2017/3/27.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import "TaskFailedCell.h"

@interface TaskFailedCell ()

@property (nonatomic , strong) UILabel *nameLabel;
@property (nonatomic , strong) UILabel *desLabel;
@property (nonatomic , strong) UIButton *downloadButton;

@end

@implementation TaskFailedCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initialTaskFailedCell];
    }
    return self;
}

-(void)initialTaskFailedCell{
    _nameLabel = [[UILabel alloc]init];
    _nameLabel.backgroundColor = [UIColor clearColor];
    _nameLabel.font = [UIFont systemFontOfSize:13];
    [self.contentView addSubview:_nameLabel];
    
    _desLabel = [[UILabel alloc]init];
    _desLabel.backgroundColor = [UIColor clearColor];
    _desLabel.font = [UIFont systemFontOfSize:12];
    _desLabel.text = @"下载失败";
    [self.contentView addSubview:_desLabel];
    
    _downloadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _downloadButton.backgroundColor = [UIColor clearColor];
    [_downloadButton addTarget:self action:@selector(downloadingButtonIsTouch) forControlEvents:UIControlEventTouchUpInside];
    [_downloadButton setImage:[UIImage imageNamed:@"menu_play"] forState:UIControlStateNormal];
    _downloadButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.contentView addSubview:_downloadButton];
    
    [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).with.offset(8);
        make.left.equalTo(self.contentView.mas_left).with.offset(10);
        make.right.equalTo(self.contentView.mas_right).with.offset(-50);
        make.height.equalTo(self.contentView.mas_height).with.multipliedBy(0.3);
    }];
    
    [_desLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_nameLabel.mas_bottom).offset(5);
        make.left.equalTo(_nameLabel.mas_left);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-8);
        make.right.equalTo(_nameLabel.mas_right);
    }];
    
    [_downloadButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.right.equalTo(self.contentView.mas_right).offset(-5);
        make.width.equalTo(@40);
        make.height.equalTo(@40);
    }];
}

-(void)setTask:(MyTask *)task{
    _task = task;
    _nameLabel.text = _task.fileName;
}

-(void)downloadingButtonIsTouch{
    //添加到队列中
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
