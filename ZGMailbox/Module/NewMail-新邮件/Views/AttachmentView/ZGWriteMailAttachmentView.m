//
//  ZGWriteMailAttachmentView.m
//  ZGMailbox
//
//  Created by zzg on 2017/4/26.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGWriteMailAttachmentView.h"

//cells
#import "ZGWriteMailFileAttachmentCollectionViewCell.h"
#import "ZGWriteMailImageAttachmentCollectionViewCell.h"
#import "ZGAddAttachmentCollectionViewCell.h"

#import "ZGMailModule.h"

//常量
static NSString *const WriteMailImageAttachmentCollectionViewCellIdentifier = @"WriteMailImageAttachmentCollectionViewCellIdentifier";
static NSString *const WriteMailFileAttachmentCollectionViewCellIdentifier = @"WriteMailFileAttachmentCollectionViewCellIdentifier";
static NSString *const AddAttachmentCollectionViewCellIdentifier = @"AddAttachmentCollectionViewCellIdentifier";

@interface ZGWriteMailAttachmentView () <UICollectionViewDelegate, UICollectionViewDataSource, ZGWriteMailImageAttachmentCollectionViewCellDelegate, ZGWriteMailFileAttachmentCollectionViewCellDelegate>

@property (nonatomic, strong) UICollectionView *myCollectionView;

@end

@implementation ZGWriteMailAttachmentView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubview:self.myCollectionView];
        
        [self layoutViewSubviews];
    }
    
    return self;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.originMessageAttachments count] > 0 && indexPath.row < self.originMessageAttachments.count) {//原始邮件附件点击
        if (self.delegate && [self.delegate respondsToSelector:@selector(writeMailAttachmentView:didSelectOriginMessageItemAtIndex:)]) {
            [self.delegate writeMailAttachmentView:self didSelectOriginMessageItemAtIndex:indexPath.row];
        }
    } else if (indexPath.row == self.attachmentsFilenameArray.count + self.originMessageAttachments.count) {//点击加号
        if (self.delegate && [self.delegate respondsToSelector:@selector(addAttachmentCollectionViewCellPressed:)]) {
            [self.delegate addAttachmentCollectionViewCellPressed:self];
        }
    } else {//附件点击
        if (self.delegate && [self.delegate respondsToSelector:@selector(writeMailAttachmentView:didSelectItemAtIndex:)]) {
            [self.delegate writeMailAttachmentView:self didSelectItemAtIndex:indexPath.row - self.originMessageAttachments.count];
        }
    }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.originMessageAttachments count] > 0 && indexPath.row < self.originMessageAttachments.count) {//文件
        ZGWriteMailFileAttachmentCollectionViewCell *cell = (ZGWriteMailFileAttachmentCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        UIImage *image = [UIImage imageNamed:@"attachment_bg_pressed"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
        cell.backgroudImageView.image = image;
    } else if (indexPath.row == self.originMessageAttachments.count + self.attachmentsFilenameArray.count) {//加号
        ZGAddAttachmentCollectionViewCell *cell = (ZGAddAttachmentCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        UIImage *image = [UIImage imageNamed:@"attachment_bg_pressed"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
        cell.backgroudImageView.image = image;
    } else {
    }
    
    return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.originMessageAttachments count] > 0 && indexPath.row < self.originMessageAttachments.count) {//文件
        ZGWriteMailFileAttachmentCollectionViewCell *cell = (ZGWriteMailFileAttachmentCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        UIImage *image = [UIImage imageNamed:@"attachment_bg"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
        cell.backgroudImageView.image = image;
    } else if (indexPath.row == self.originMessageAttachments.count + self.attachmentsFilenameArray.count) {//加号
        ZGAddAttachmentCollectionViewCell *cell = (ZGAddAttachmentCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
        UIImage *image = [UIImage imageNamed:@"attachment_bg"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
        cell.backgroudImageView.image = image;
    } else {
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.originMessageAttachments count] + [self.attachmentsFilenameArray count] + 1;//最后一个是加号
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.attachmentsFilenameArray.count + self.originMessageAttachments.count) {//加号
        ZGAddAttachmentCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:AddAttachmentCollectionViewCellIdentifier forIndexPath:indexPath];
       
        return cell;
    } else {
        if ([self.originMessageAttachments count] > 0 && indexPath.row < self.originMessageAttachments.count) {
            ZGWriteMailFileAttachmentCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:WriteMailFileAttachmentCollectionViewCellIdentifier forIndexPath:indexPath];
            cell.delegate = self;
            cell.part = [self.originMessageAttachments objectAtIndex:indexPath.row];
           
            return cell;
        } else {
            ZGWriteMailImageAttachmentCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:WriteMailImageAttachmentCollectionViewCellIdentifier forIndexPath:indexPath];
            cell.delegate = self;
            cell.indexPath = indexPath;
            NSString *imageName = [self.attachmentsFilenameArray objectAtIndex:indexPath.row - self.originMessageAttachments.count];
            NSString *path = [[ZGMailModule sharedInstance] pathOfImageDataStoreWithMessageID:self.messageID imageName:imageName];
            NSData *data = [NSData dataWithContentsOfFile:path];
            
            cell.attachmentPreviewImageView.image = [self croppingImage:[UIImage imageWithData:data]];
            
//            NSData *data = [self.attachmentsDataArray objectAtIndex:indexPath.row - self.originMessageAttachments.count];
            cell.imageData = data;
            cell.imageName = imageName;
           
            return cell;
        }
    }
}

#pragma mark - ZGWriteMailImageAttachmentCollectionViewCellDelegate

- (void)writeMailImageAttachmentCollectionViewCell:(ZGWriteMailImageAttachmentCollectionViewCell *)attachmentViewCell deleteButtonPressed:(UIButton *)button {
    NSInteger index = [self.attachmentsFilenameArray indexOfObject:attachmentViewCell.imageName];
//    NSInteger index = button.tag - self.originMessageAttachments.count;

    if (self.delegate && [self.delegate respondsToSelector:@selector(writeMailAttachmentView:deleteButtonPressed:)]) {
        [self.delegate writeMailAttachmentView:self deleteButtonPressed:index];
    }
//    [self.attachmentsPhotosArray removeObjectAtIndex:index];
//    [self.attachmentsDataArray removeObjectAtIndex:index];
    [self.attachmentsFilenameArray removeObjectAtIndex:index];
    
    //补上前面的原始邮件数据个数
    index = index + self.originMessageAttachments.count;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.myCollectionView deleteItemsAtIndexPaths:@[indexPath]];
    
    [self.myCollectionView reloadData];
}

#pragma mark - ZGWriteMailAttachmentCollectionViewCellDelegate

- (void)writeMailFileAttachmentCollectionViewCell:(ZGWriteMailFileAttachmentCollectionViewCell *)attachmentViewCell deleteButtonPressed:(UIButton *)button {
    NSInteger index = [self.originMessageAttachments indexOfObject:attachmentViewCell.part];
    if (self.delegate && [self.delegate respondsToSelector:@selector(writeMailAttachmentView:originMessageDeleteButtonPressed:)]) {
        [self.delegate writeMailAttachmentView:self originMessageDeleteButtonPressed:index];
    }
    [self.originMessageAttachments removeObjectAtIndex:index];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.myCollectionView deleteItemsAtIndexPaths:@[indexPath]];
    
    [self.myCollectionView reloadData];
}

#pragma mark - public method 

- (void)reloadAttachmentView {
    [self.myCollectionView reloadData];
}

- (float)calculateHeightOfAttachmentViewWithAttachmentCount:(NSInteger)count {
    NSInteger lineNumer = count / 2;
    if (count % 2 != 0) {//不是2的倍数
        lineNumer += 1;
    } else {
        
    }
    float height = lineNumer * 120 + 12;
    
    return height;
}

#pragma mark - private method

- (void)layoutViewSubviews {
    [self.myCollectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.mas_width).offset(-30);
        make.height.mas_equalTo(self);
        make.center.mas_equalTo(self);
    }];
}

/**
 *  裁剪图片
 *
 *  @param image <#image description#>
 *
 *  @return <#return value description#>
 */
- (UIImage *)croppingImage:(UIImage *)image {
    CGSize size = CGSizeMake((ScreenWidth - 30 - 6) / 2, 114.0f);
    float height = image.size.width * (size.height / size.width);
    CGRect rect = CGRectMake(0, (image.size.height - height) / 2.0f, image.size.width, height);
    
    CGImageRef imageRef = image.CGImage;
    CGImageRef imagePartRef = CGImageCreateWithImageInRect(imageRef, rect);
    UIImage *cropImage = [UIImage imageWithCGImage:imagePartRef];
    CGImageRelease(imagePartRef);
    
    return cropImage;
}

#pragma mark - setter and getter 

- (UICollectionView *)myCollectionView {
    if (_myCollectionView == nil) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake((ScreenWidth - 30 - 6) / 2, 114);
        flowLayout.minimumLineSpacing = 6;
        flowLayout.minimumInteritemSpacing = 6;
        [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
        _myCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _myCollectionView.backgroundColor = [UIColor whiteColor];
        _myCollectionView.delegate = self;
        _myCollectionView.dataSource = self;
        _myCollectionView.scrollEnabled = NO;
        
        [_myCollectionView registerClass:[ZGWriteMailImageAttachmentCollectionViewCell class] forCellWithReuseIdentifier:WriteMailImageAttachmentCollectionViewCellIdentifier];
        [_myCollectionView registerClass:[ZGWriteMailFileAttachmentCollectionViewCell class] forCellWithReuseIdentifier:WriteMailFileAttachmentCollectionViewCellIdentifier];
        [_myCollectionView registerClass:[ZGAddAttachmentCollectionViewCell class] forCellWithReuseIdentifier:AddAttachmentCollectionViewCellIdentifier];
    }
    
    return _myCollectionView;
}

@end
