//
//  TaskLoadedCell.m
//  MyTaskManager
//
//  Created by 蔡成汉 on 2017/3/2.
//  Copyright © 2017年 上海泰侠网络科技有限公司. All rights reserved.
//

#import "TaskLoadedCell.h"

@interface TaskLoadedCell ()

/**
 icon
 */
@property (nonatomic , strong) UIImageView *iconImageView;

@property (nonatomic , strong) UILabel *nameLabel;

@property (nonatomic , strong) UILabel *sizeLabel;

@end

@implementation TaskLoadedCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initialTaskLoadedCell];
    }
    return self;
}

-(void)initialTaskLoadedCell{
    _iconImageView = [[UIImageView alloc]init];
    _iconImageView.image = [UIImage imageNamed:@"file"];
    [self.contentView addSubview:_iconImageView];
    
    _nameLabel = [[UILabel alloc]init];
    _nameLabel.backgroundColor = [UIColor clearColor];
    _nameLabel.font = [UIFont systemFontOfSize:13];
    [self.contentView addSubview:_nameLabel];
    
    _sizeLabel = [[UILabel alloc]init];
    _sizeLabel.backgroundColor = [UIColor clearColor];
    _sizeLabel.font = [UIFont systemFontOfSize:14];
    _sizeLabel.textAlignment = NSTextAlignmentRight;
    [self.contentView addSubview:_sizeLabel];
    
    [_iconImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView.mas_top).offset(20);
        make.left.equalTo(self.contentView.mas_left).offset(17);
        make.width.equalTo(@31);
        make.height.equalTo(@35);
    }];
    
    [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_iconImageView.mas_right).offset(10);
        make.right.equalTo(self.contentView.mas_right).offset(-17);
        make.centerY.equalTo(_iconImageView.mas_centerY);
        make.height.equalTo(@25);
    }];
    
    [_sizeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_nameLabel.mas_bottom);
        make.left.equalTo(_nameLabel.mas_left);
        make.right.equalTo(_nameLabel.mas_right);
        make.bottom.equalTo(self.contentView.mas_bottom).offset(-8);
    }];
}

-(void)setTask:(MyTask *)task{
    if (task) {
        _nameLabel.text = task.fileName;
        _sizeLabel.text = [NSString stringWithFormat:@"%.2f M",task.totalBytesExpectedToWrite/1024.0/1024.0];
    }
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
