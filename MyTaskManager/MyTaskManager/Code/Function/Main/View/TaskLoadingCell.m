//
//  TaskLoadingCell.m
//  MyTaskManager
//
//  Created by 蔡成汉 on 2017/3/2.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import "TaskLoadingCell.h"

@interface TaskLoadingCell ()

/**
 nameLabel
 */
@property (nonatomic , strong) UILabel *nameLabel;
@property (nonatomic , strong) UIProgressView *progressView;
@property (nonatomic , strong) UILabel *progressLabel;
@property (nonatomic , strong) UILabel *speedLabel;
@property (nonatomic , strong) UIButton *downloadButton;

@end

@implementation TaskLoadingCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initialMyTableViewCell];
    }
    return self;
}

-(void)initialMyTableViewCell{
    _nameLabel = [[UILabel alloc]init];
    _nameLabel.backgroundColor = [UIColor clearColor];
    _nameLabel.font = [UIFont systemFontOfSize:13];
    [self.contentView addSubview:_nameLabel];
    
    _progressView = [[UIProgressView alloc]init];
    _progressView.tintColor = [UIColor colorWithRed:245.0/255.0 green:76.0/255.0 blue:72.0/255.0 alpha:1];
    [self.contentView addSubview:_progressView];
    
    _progressLabel = [[UILabel alloc]init];
    _progressLabel.backgroundColor = [UIColor clearColor];
    _progressLabel.font = [UIFont systemFontOfSize:12];
    _progressLabel.text = @"0.0";
    [self.contentView addSubview:_progressLabel];
    
    _speedLabel = [[UILabel alloc]init];
    _speedLabel.backgroundColor = [UIColor clearColor];
    _speedLabel.font = [UIFont systemFontOfSize:12];
    _speedLabel.text = @"";
    _speedLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:_speedLabel];
    
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
    
    [_progressView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_nameLabel.mas_bottom).with.offset(5);
        make.left.equalTo(_nameLabel.mas_left);
        make.right.equalTo(_nameLabel.mas_right);
        make.height.equalTo(@2);
    }];
    
    [_progressLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_progressView.mas_bottom).with.offset(5);
        make.left.equalTo(_progressView.mas_left);
        make.right.equalTo(_progressView.mas_right).offset(-100);
        make.bottom.equalTo(self.contentView.mas_bottom).with.offset(-5);
    }];
    
    [_speedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_progressLabel.mas_top);
        make.left.equalTo(_progressLabel.mas_right);
        make.width.equalTo(@100);
        make.height.equalTo(_progressLabel.mas_height);
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
    float progress = ((float)_task.totalBytesWritten/(float)(_task.totalBytesExpectedToWrite));
    if (progress>0) {
        _progressView.progress = progress;
    }else{
        _progressView.progress = 0;
    }
    if (_task.totalBytesWritten > 0) {
        NSString *progressStr = [NSString stringWithFormat:@"(%.2f%@)",progress*100,@"%"];
        NSString *sizeStr = [NSString stringWithFormat:@"%.2fM/%.2fM",_task.totalBytesWritten/1024.0/1024.0,_task.totalBytesExpectedToWrite/1024.0/1024.0];
        _progressLabel.text = [NSString stringWithFormat:@"%@ %@",sizeStr,progressStr];
    }else{
        _progressLabel.text = @"";
    }
    if (_task.state == WatingDownload) {
        _speedLabel.text = @"等待";
        [_downloadButton setImage:[UIImage imageNamed:@"menu_play"] forState:UIControlStateNormal];
    }else if (_task.state == Suspended){
        _speedLabel.text = @"暂停";
        [_downloadButton setImage:[UIImage imageNamed:@"menu_play"] forState:UIControlStateNormal];
    }else{
        _speedLabel.text = task.speed;
        [_downloadButton setImage:[UIImage imageNamed:@"menu_pause"] forState:UIControlStateNormal];
    }
}

-(void)downloadingButtonIsTouch{
    if (_task) {
        if (_task.state == Downloading) {
            //正在下载，那么就暂停掉
            [_downloadButton setImage:[UIImage imageNamed:@"menu_pause"] forState:UIControlStateNormal];
            [self suspend];
        }else{
            //执行下载
            [_downloadButton setImage:[UIImage imageNamed:@"menu_play"] forState:UIControlStateNormal];
            [self resume];
        }
    }
}

//执行下载
-(void)resume{
    [[MyTaskManager shareManager]resume:_task];
}

//暂停
-(void)suspend{
    [[MyTaskManager shareManager]suspend:_task];
}

#pragma mark - 下载速度计算


- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
