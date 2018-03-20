//
//  ZGNewMailViewController.m
//  ZGMailbox
//
//  Created by zzg on 2017/3/28.
//  Copyright © 2017年 zzg. All rights reserved.
//

#import "ZGNewMailViewController.h"

//custom views
#import "ZGComposeHeaderView.h"
#import "HPGrowingTextView.h"//自增长的textView
#import "ZGWriteMailAttachmentView.h"//插件视图

//邮件模块管理类
#import "ZGMailModule.h"

//拍照、照片选择
#import <TZImagePickerController/TZImagePickerController.h>
#import <TZImagePickerController/TZImageManager.h>

//图片浏览
#import "MWPhotoBrowser.h"

//model
#import "ZGMailMessage.h"

//邮件展示
#import "MCOMessageView.h"

//邮件协议
#import <MailCore/MCOIMAPMessage.h>
#import <MailCore/MCOMessageHeader.h>
#import <MailCore/MCOAddress.h>
#import <MailCore/MCOMessageBuilder.h>

//邮件模块管理工具类
#import "ZGMailModule.h"


typedef void (^DownloadCallback)(NSError * error);
#define IMAGE_PREVIEW_HEIGHT 300
#define IMAGE_PREVIEW_WIDTH 500

//static NSString *const MailBodyPlaceholder = @"\n\n\n发自我的海康MOA\n";
static NSString *const MailSignature = @"\n\n\n发自ZGMailBox";
static NSString *const ReplyAndForwardMailBodyPlaceholder = @"\n----------------原始邮件----------------\n";

@interface ZGNewMailViewController () <ZGComposeHeaderViewDelegate, TZImagePickerControllerDelegate, HPGrowingTextViewDelegate, ZGWriteMailAttachmentViewDelegate, MWPhotoBrowserDelegate, MCOMessageViewDelegate, MCOHTMLRendererIMAPDelegate> {
    MCOIMAPFetchContentOperation *operation;
}

@property (nonatomic, strong) UIBarButtonItem *sendBarButtonItem;//发送按钮

@property (nonatomic, strong) UIScrollView *myScrollView;
@property (nonatomic, strong) ZGComposeHeaderView *composeHeaderView;//header
@property (nonatomic, strong) HPGrowingTextView *mailWriteTextView;//正文输入
@property (nonatomic, strong) MCOMessageView *messageView;//原始邮件展示
@property (nonatomic, strong) ZGWriteMailAttachmentView *attachmentView;//附件展示
@property (nonatomic, strong) UILabel *loadingLabel;//加载中（原始邮件附件下载）

//附件数据
@property (nonatomic, strong) NSMutableArray *originMessageParts;//原始邮件附件数据（MCOIMAPPart），用于附件展示、编辑
@property (nonatomic, strong) NSMutableArray *originattachmentsFilenameArray;//原始邮件附件文件名数组
@property (nonatomic, strong) NSMutableArray *attachmentsFilenameArray;//附件文件名数组

@property (nonatomic, strong) NSMutableArray *selectedAssets;//已选中的图片数组


@property (nonatomic, strong) MASConstraint *mailWriteTextViewHeightConstraint;
@property (nonatomic, strong) MASConstraint *attachmentViewHeightConstraint;
@property (nonatomic, strong) MASConstraint *messageViewHeightConstraint;

@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;//触摸手势

@end

@implementation ZGNewMailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //添加子视图
    [self.view addSubview:self.myScrollView];
    [self.myScrollView addSubview:self.composeHeaderView];
    [self.myScrollView addSubview:self.mailWriteTextView];
    [self.myScrollView addSubview:self.attachmentView];
    //添加原始邮件加载视图：回复、转发、带有原始邮件的草稿、带有原始邮件的发件箱邮件
    if (self.newMailType == NewMailTypeReply || self.newMailType == NewMailTypeReplyAll || self.newMailType == NewMailTypeForward || (self.newMailType == NewMailTypeDraft && self.mailMessage.originImapMessage) || (self.newMailType == NewMailTypeSending && self.mailMessage.originImapMessage)) {
        //监听webview
        [self.messageView.webScrollView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:nil];
        [self.myScrollView addSubview:self.messageView];
    }

    [self layoutPageSubviews];
    [self setupNavigationBar];

    //scrollView添加tap手势
    self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizeTapGesture:)];
    self.tapGesture.numberOfTapsRequired = 1;
    [self.myScrollView addGestureRecognizer:self.tapGesture];
    
    
    [self setupViewData];
    
    //先设置messageID才能加载附件
    self.attachmentView.messageID = self.composeHeaderView.header.messageID;
    
    /**
     *  加载数据
     */
    if (self.newMailType == NewMailTypeReply || self.newMailType == NewMailTypeReplyAll || self.newMailType == NewMailTypeForward) {//回复邮件或者转发邮件，需要展示原始邮件
        //加载数据
        self.messageView.imapMessage = self.originImapMessage;
        
        //转发，展示原始邮件附件
        if (self.newMailType == NewMailTypeForward && self.originImapMessage.attachments.count > 0) {
            //设置附件个数
            [self.composeHeaderView setAttachmentNumber:self.originImapMessage.attachments.count];
            
            self.mailWriteTextView.hidden = YES;
            self.messageView.hidden = YES;
            
            //开始下载原始邮件附件
            [self startDownloadOriginMessageAttachments];
            
            //加载中...
            [self.myScrollView addSubview:self.loadingLabel];
            [self.loadingLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.leading.mas_equalTo(self.myScrollView.mas_leading).offset(15);
                make.top.mas_equalTo(self.composeHeaderView.mas_bottom).offset(20);
            }];
        }
    } else if (self.newMailType == NewMailTypeDraft || self.newMailType == NewMailTypeSending) {//草稿、发件箱邮件
        //初始化原始邮件数据
        if (self.mailMessage.originImapMessage) {
            self.originImapMessage = self.mailMessage.originImapMessage;
            
            //加载数据
            self.messageView.imapMessage = self.mailMessage.originImapMessage;
        } else {
            //originIMAPMessage为空，不加载原始邮件
        }
        
        //初始化附件数据
        self.originMessageParts = [NSMutableArray arrayWithArray:self.mailMessage.originMessageParts];
        self.originattachmentsFilenameArray = [NSMutableArray arrayWithArray:self.mailMessage.attachmentsFilenameArray];
        
        
        //设置附件个数
        NSUInteger count = self.mailMessage.originMessageParts.count + self.mailMessage.attachmentsFilenameArray.count;
        if (count > 0) {
            [self.composeHeaderView setAttachmentNumber:count];
            [self showAttachmentView];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.composeHeaderView headerViewBecomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    if (self.newMailType == NewMailTypeReply || self.newMailType == NewMailTypeReplyAll || self.newMailType == NewMailTypeForward || (self.newMailType == NewMailTypeDraft && self.mailMessage.originImapMessage) || (self.newMailType == NewMailTypeSending && self.mailMessage.originImapMessage)) {
        [self.messageView.webScrollView removeObserver:self forKeyPath:@"contentSize" context:nil];
    }
    
    [operation cancel];
    
    self.messageView.delegate = nil;
    self.messageView = nil;
}

#pragma mark - ZGComposeHeaderViewDelegate

- (void)composeHeaderView:(ZGComposeHeaderView *)composeHeaderView addContactsButtonPressed:(ZGMailAddressButton *)button {
//    HikContactSelectionViewController *contactSelectionVC = [[HikContactSelectionViewController alloc] init];
//    contactSelectionVC.delegate = self;
//    contactSelectionVC.selectionType = AddressBookForPluginSelectionTypeMultipleSelection;
//    contactSelectionVC.businessType = BusinessType_Mail;
//    
//    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:contactSelectionVC];
//    [self presentViewController:navVC animated:YES completion:nil];
}

- (void)composeHeaderView:(ZGComposeHeaderView *)composeHeaderView deleteAddressButton:(ZGMailAddressButton *)button {
    if ([self isRecipientArrayNull]) {
        self.sendBarButtonItem.enabled = NO;
    }
}

- (void)composeHeaderView:(ZGComposeHeaderView *)composeHeaderView isAddressTextFieldTobeEmpty:(BOOL)tobeEmpty {
    if (tobeEmpty) {
        //收件人为空，发送按钮不可用
        if ([self isRecipientArrayNull]) {
            self.sendBarButtonItem.enabled = NO;
        } else {
            self.sendBarButtonItem.enabled = YES;
        }
    } else {
        if (!self.sendBarButtonItem.enabled) {
            self.sendBarButtonItem.enabled = YES;
        }
    }
}

/**
 *  附件按钮点击
 *
 *  @param composeHeaderView
 *  @param button
 */
- (void)composeHeaderView:(ZGComposeHeaderView *)composeHeaderView attachmentButtonPressed:(UIButton *)button {
    [self showImagePickerController];
}

//#pragma mark - ZGMailSelectContactsViewControllerDelegate
//
//- (void)selectContactsVC:(ZGMailSelectContactsViewController *)selectContactsVC selectedContacts:(NSArray *)selectedContacts {
//    [self.composeHeaderView addAddressArrayToAddressEditView:selectedContacts];
//    if ([selectedContacts count] > 0) {
//        self.sendBarButtonItem.enabled = YES;
//    }
//}

#pragma mark - ZGContactSelectionViewControllerDelegate

- (void)selectedContactsList:(NSArray *)selectedContacts {
    [self.composeHeaderView addAddressArrayToAddressEditView:selectedContacts];
    if ([selectedContacts count] > 0) {
        self.sendBarButtonItem.enabled = YES;
    }
}

#pragma mark - TZImagePickerControllerDelegate -- 相册中选取照片代理

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    [picker dismissViewControllerAnimated:YES completion:nil];

    [self showHUDCoverNavbar:NO];
    
    [self.attachmentsFilenameArray removeAllObjects];
    
    [assets enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
        PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
        option.synchronous = YES;
        [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable data, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
            NSData *imageData = nil;
            if (isSelectOriginalPhoto) {
                imageData = data;
            } else {
                UIImage *image = [photos objectAtIndex:idx];
                imageData = UIImagePNGRepresentation(image);
            }
            NSURL *filePahth = [info objectForKey:@"PHImageFileURLKey"];
            NSString *fileName = [[NSFileManager defaultManager] displayNameAtPath:[filePahth path]];
            [self.attachmentsFilenameArray addObject:fileName];
            
            [[ZGMailModule sharedInstance] storeImageDataToDisk:imageData messageID:self.composeHeaderView.header.messageID imageName:fileName];
        }];
    }];
    //选中的图片数据
    [self.selectedAssets removeAllObjects];
    [self.selectedAssets addObjectsFromArray:assets];
    //设置附件个数
    [self.composeHeaderView setAttachmentNumber:[self totalAttachmentNumber]];
    
    //设置主题
    if (IsEmptyString(self.composeHeaderView.header.subject)) {
        MCOMessageHeader *header = self.composeHeaderView.header;
        NSString *imageName = self.attachmentsFilenameArray.firstObject;
        header.subject = [imageName stringByDeletingPathExtension];
        [self.composeHeaderView setHeader:header];
    }
    
    //更新附件视图
    [self showAttachmentView];
    
    [self hideHUD];
}

- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - HPGrowingTextViewDelegate

- (void)growingTextViewDidBeginEditing:(HPGrowingTextView *)growingTextView {
    [self.composeHeaderView headerViewResignFirstResponder];
}

- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    return YES;
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height {
    self.mailWriteTextViewHeightConstraint.offset = height;
    [UIView animateWithDuration:0.25 animations:^{
        [self.myScrollView layoutIfNeeded];
//        [self scrollToBottom];
        //始终显示输入光标
        float offsetY = self.composeHeaderView.height + self.mailWriteTextView.height - (self.myScrollView.height - self.myScrollView.contentInset.bottom);
        if (offsetY > 0) {
            self.myScrollView.contentOffset = CGPointMake(0, offsetY);
        } else {
        }
    }];
}

#pragma mark - ZGWriteMailAttachmentViewDelegate

/**
 *  原始邮件附件删除
 *
 *  @param attachmentView
 *  @param index
 */
- (void)writeMailAttachmentView:(ZGWriteMailAttachmentView *)attachmentView originMessageDeleteButtonPressed:(NSInteger)index {
    [self.view endEditing:YES];
    
    //删除附件数据
    [self.originMessageParts removeObjectAtIndex:index];
    //设置附件个数
    [self.composeHeaderView setAttachmentNumber:self.originMessageParts.count + self.attachmentsFilenameArray.count];
    //更新附件视图高度
    [self updateAttachmentViewHeight];
}

/**
 *  附件删除
 *
 *  @param attachmentView
 *  @param index
 */
- (void)writeMailAttachmentView:(ZGWriteMailAttachmentView *)attachmentView deleteButtonPressed:(NSInteger)index {
    [self.view endEditing:YES];

    //删除附件数据
    NSString *imageName = @"";
    if (self.originattachmentsFilenameArray.count > 0 && index < self.originattachmentsFilenameArray.count) {
        imageName = [self.originattachmentsFilenameArray objectAtIndex:index];
        [self.originattachmentsFilenameArray removeObjectAtIndex:index];
    } else {
        index = index - self.originattachmentsFilenameArray.count;
        
        imageName = [self.attachmentsFilenameArray objectAtIndex:index];
        [self.attachmentsFilenameArray removeObjectAtIndex:index];
        [self.selectedAssets removeObjectAtIndex:index];
    }
    //在原始邮件文件名数组和选中的文件名数组中都不存在才删除
    if (![self.originattachmentsFilenameArray containsObject:imageName] && ![self.attachmentsFilenameArray containsObject:imageName]) {
        [[ZGMailModule sharedInstance] removeImageFromDiskWithMessageID:self.composeHeaderView.header.messageID imageName:imageName];
    }
    
    //设置附件个数
    [self.composeHeaderView setAttachmentNumber:[self totalAttachmentNumber]];

    //更新附件视图高度
    [self updateAttachmentViewHeight];
}

/**
 *  添加附件cell点击
 *
 *  @param attachmentView
 */
- (void)addAttachmentCollectionViewCellPressed:(ZGWriteMailAttachmentView *)attachmentView {
    [self showImagePickerController];
}

/**
 *  附件点击
 *
 *  @param attachmentView
 *  @param index
 */
- (void)writeMailAttachmentView:(ZGWriteMailAttachmentView *)attachmentView didSelectItemAtIndex:(NSInteger)index {
    [self showAttachmentImagesWithCurrentIndex:index];
}

/**
 *  原始邮件附件点击
 *
 *  @param attachmentView
 *  @param index
 */
- (void)writeMailAttachmentView:(ZGWriteMailAttachmentView *)attachmentView didSelectOriginMessageItemAtIndex:(NSInteger)index {
//    ZGMessageAttachmentViewController *attachmentVC = [[ZGMessageAttachmentViewController alloc] init];
//    attachmentVC.message = self.originImapMessage;
//    attachmentVC.folder = self.originMessageFolder;
//    attachmentVC.session = self.session;
//    attachmentVC.part = [self.originMessageParts objectAtIndex:index];
//    [self.navigationController pushViewController:attachmentVC animated:YES];
    
    
    
    [self showTipText:@"不支持查看转发的原始邮件附件"];
}

#pragma mark - MWPhotoBrowserDelegate

- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser {
    return [self.attachmentsFilenameArray count];
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index {
    NSString *imageName = [self.attachmentsFilenameArray objectAtIndex:index];
    NSString *path = [[ZGMailModule sharedInstance] pathOfImageDataStoreWithMessageID:self.composeHeaderView.header.messageID imageName:imageName];
    MWPhoto *photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:path]];
    
    return photo;
}

- (id <MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser thumbPhotoAtIndex:(NSUInteger)index {
    NSString *imageName = [self.attachmentsFilenameArray objectAtIndex:index];
    NSString *path = [[ZGMailModule sharedInstance] pathOfImageDataStoreWithMessageID:self.composeHeaderView.header.messageID imageName:imageName];
    MWPhoto *photo = [MWPhoto photoWithURL:[NSURL fileURLWithPath:path]];
    
    return photo;
}

//- (void)photoBrowser:(MWPhotoBrowser *)photoBrowser actionButtonPressedForPhotoAtIndex:(NSUInteger)index {
//    
//}

#pragma mark - MCOMessageViewDelegate

- (void)MCOMessageView:(MCOMessageView *)view webViewDidFinishLoad:(UIWebView *)webView {

}

#pragma mark - IBAction 

- (IBAction)cancelButtonPressed:(id)sender {
    [self.view endEditing:YES];
    
    if ([self shouldShowSaveDraftAlertController]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

        NSString *notSaveTitle = @"";
        NSString *saveTitle = @"";
        if (self.newMailType == NewMailTypeDraft || self.newMailType == NewMailTypeSending) {//草稿、发件箱邮件再编辑
            notSaveTitle = @"放弃修改";
            saveTitle = @"保存修改";
        } else {
            notSaveTitle = @"不保存草稿";
            saveTitle = @"保存草稿";
        }
        UIAlertAction *notSaveAction = [UIAlertAction actionWithTitle:notSaveTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            if (self.newMailType == NewMailTypeDraft || self.newMailType == NewMailTypeSending) {//草稿、发件箱邮件再编辑
                //只是放弃修改，并不要删除本地的图片缓存
            } else {
                //删除当前邮件的图片附件缓存目录
                [[ZGMailModule sharedInstance] removeImageStoreDirectoryFromDiskForMessageID:self.composeHeaderView.header.messageID];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction *saveAction = [UIAlertAction actionWithTitle:saveTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self showHUDCoverNavbar:YES];
            
            if (self.newMailType == NewMailTypeSending || self.newMailType == NewMailTypeDraft) {
                //保存修改
                self.mailMessage.header = self.composeHeaderView.header;
                self.mailMessage.bodyText = self.mailWriteTextView.text;
                NSMutableArray *array = [[NSMutableArray alloc] initWithArray:self.originattachmentsFilenameArray];
                [array addObjectsFromArray:self.attachmentsFilenameArray];
                self.mailMessage.attachmentsFilenameArray = array;
                self.mailMessage.originImapMessage = self.originImapMessage;
                self.mailMessage.originMessageFolder = self.originMessageFolder;
                self.mailMessage.originMessageParts = self.originMessageParts;
                if (self.newMailType == NewMailTypeSending) {//发件箱邮件再编辑
                    [[ZGMailModule sharedInstance] insertOrUpdateMailMessageInUserDefaultForFolder:MailFolderTypeSending message:self.mailMessage];
                } else {//草稿邮件编辑再保存
                    [[ZGMailModule sharedInstance] insertOrUpdateMailMessageInUserDefaultForFolder:MailFolderTypeDraft message:self.mailMessage];
                }
            } else {//新建邮件保存
                //保存草稿
                ZGMailMessage *mailMessage = [[ZGMailMessage alloc] init];
                mailMessage.messageStatus = MailMessageStatus_Draft;
                mailMessage.header = self.composeHeaderView.header;
                mailMessage.bodyText = self.mailWriteTextView.text;
                mailMessage.originImapMessage = self.originImapMessage;
                mailMessage.originMessageFolder = self.originMessageFolder;
                mailMessage.originMessageParts = self.originMessageParts;
                NSMutableArray *array = [[NSMutableArray alloc] initWithArray:self.originattachmentsFilenameArray];
                [array addObjectsFromArray:self.attachmentsFilenameArray];
                mailMessage.attachmentsFilenameArray = array;
                [[ZGMailModule sharedInstance] insertOrUpdateMailMessageInUserDefaultForFolder:MailFolderTypeDraft message:mailMessage];
            }
            [self showSuccessTipText:@"保存草稿成功" completion:^{
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        }];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        
        [alertController addAction:notSaveAction];
        [alertController addAction:saveAction];
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)sendButtonPressed:(id)sender {
    //隐藏写邮件页面
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (self.newMailType == NewMailTypeDraft) {//草稿箱邮件点击发送之后，要从草稿箱移动到发件箱
        [[ZGMailModule sharedInstance] removeMailMessageFromUserDefaultForFolder:MailFolderTypeDraft messageID:self.composeHeaderView.header.messageID];
    } else {
    }
    
    __block NSString *bodyText = self.mailWriteTextView.text;
    if (self.newMailType == NewMailTypeReply || self.newMailType == NewMailTypeReplyAll || self.newMailType == NewMailTypeForward || (self.newMailType == NewMailTypeDraft && self.mailMessage.originImapMessage) || (self.newMailType == NewMailTypeSending && self.mailMessage.originImapMessage)) {
        
        NSMutableArray *array = [[NSMutableArray alloc] initWithArray:self.originattachmentsFilenameArray];
        [array addObjectsFromArray:self.attachmentsFilenameArray];
        //回复、转发、草稿、发件箱邮件
        [[ZGMailModule sharedInstance] sendMessageWithHeader:self.composeHeaderView.header
                                                     textBody:bodyText
                                                  attachments:array
                                                originMessage:self.originImapMessage
                                     originMessageAttachments:self.originMessageParts
                                      originMessageHtmlString:self.messageView.messageHtmlString
                                          originMessageFolder:self.originMessageFolder];
    } else {
        NSMutableArray *array = [[NSMutableArray alloc] initWithArray:self.originattachmentsFilenameArray];
        [array addObjectsFromArray:self.attachmentsFilenameArray];
        //发送新邮件
        [[ZGMailModule sharedInstance] sendMessageWithHeader:self.composeHeaderView.header
                                                     textBody:bodyText
                                                  attachments:array];
    }
}

/**
 *  单击事件
 *
 *  @param gesture
 */
- (void)didRecognizeTapGesture:(UITapGestureRecognizer *)gesture {
    [self.mailWriteTextView becomeFirstResponder];
}

#pragma mark - private method

/**
 *  设置约束
 */
- (void)layoutPageSubviews {
    [self.myScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(self.view);
        make.center.mas_equalTo(self.view);
    }];
    
    [self.composeHeaderView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.myScrollView);
        make.centerX.mas_equalTo(self.myScrollView);
        make.top.mas_equalTo(self.myScrollView);
        make.bottom.mas_equalTo(self.mailWriteTextView.mas_top);
    }];
    
    [self.mailWriteTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(self.myScrollView.mas_width);
        make.centerX.mas_equalTo(self.myScrollView);
        self.mailWriteTextViewHeightConstraint = make.height.mas_equalTo(100);
        make.top.mas_equalTo(self.composeHeaderView.mas_bottom);
    }];
    
    //回复邮件或者转发邮件，需要展示原始邮件
    //草稿邮件或者发件箱邮件，带有原始邮件的情况下，也要展示原始邮件
    if (self.newMailType == NewMailTypeReply || self.newMailType == NewMailTypeReplyAll || self.newMailType == NewMailTypeForward || (self.newMailType == NewMailTypeDraft && self.mailMessage.originImapMessage) || (self.newMailType == NewMailTypeSending && self.mailMessage.originImapMessage)) {
        [self.messageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.myScrollView.mas_width).offset(0);
            make.centerX.mas_equalTo(self.myScrollView);
            self.messageViewHeightConstraint = make.height.mas_equalTo(300);
            make.top.mas_equalTo(self.mailWriteTextView.mas_bottom);
        }];
        
        [self.attachmentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.myScrollView.mas_width);
            make.centerX.mas_equalTo(self.myScrollView);
            self.attachmentViewHeightConstraint = make.height.mas_equalTo(0);
            make.top.mas_equalTo(self.messageView.mas_bottom);
            make.bottom.mas_equalTo(self.myScrollView);
        }];
    } else {
        [self.attachmentView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(self.myScrollView.mas_width);
            make.centerX.mas_equalTo(self.myScrollView);
            self.attachmentViewHeightConstraint = make.height.mas_equalTo(0);
            make.top.mas_equalTo(self.mailWriteTextView.mas_bottom);
            make.bottom.mas_equalTo(self.myScrollView);
        }];
    }
}

/**
 *  设置title、headerView、正文
 */
- (void)setupViewData {
    NSString *subject = self.originImapMessage.header.subject;
    if (IsEmptyString(subject)) {
        subject = @"(无主题)";
    }
    switch (self.newMailType) {
            case NewMailTypeDefault:
        {
            self.title = @"写邮件";
            self.composeHeaderView.editViewType = MailAddressFlowEditViewTypeRecipient;
            if (self.recipientAddress) {
                MCOMessageHeader *header = [[MCOMessageHeader alloc] init];
                header.to = @[self.recipientAddress];
                [self.composeHeaderView setHeader:header];
                self.sendBarButtonItem.enabled = YES;
            }
            //初始化正文数据
            self.mailWriteTextView.text = MailSignature;
            [self.mailWriteTextView refreshHeight];
        }
            break;
            case NewMailTypeReply:
        {
            self.title = @"回复";
            //初始化header数据
            self.composeHeaderView.editViewType = MailAddressFlowEditViewTypeNone;
            MCOMessageHeader *header = [self.originImapMessage.header replyHeaderWithExcludedRecipients:nil];
            header.subject = [NSString stringWithFormat:@"回复：%@", subject];
            [self.composeHeaderView setHeader:header];
            //初始化正文数据
            [self.mailWriteTextView refreshHeight];
            [self.mailWriteTextView becomeFirstResponder];
            self.mailWriteTextView.text = [MailSignature stringByAppendingString:ReplyAndForwardMailBodyPlaceholder];
            self.mailWriteTextView.selectedRange = NSMakeRange(0, 0);

            self.sendBarButtonItem.enabled = YES;
        }
            break;
            case NewMailTypeReplyAll:
        {
            self.title = @"回复全部";
            //初始化header数据
            self.composeHeaderView.editViewType = MailAddressFlowEditViewTypeNone;
            MCOMessageHeader *header = [self.originImapMessage.header replyAllHeaderWithExcludedRecipients:nil];
            header.subject = [NSString stringWithFormat:@"回复：%@", subject];
            [self.composeHeaderView setHeader:header];
            //初始化正文数据
            [self.mailWriteTextView refreshHeight];
            [self.mailWriteTextView becomeFirstResponder];
            self.mailWriteTextView.text = [MailSignature stringByAppendingString:ReplyAndForwardMailBodyPlaceholder];
            self.mailWriteTextView.selectedRange = NSMakeRange(0, 0);
            
            self.sendBarButtonItem.enabled = YES;
        }
            break;
            case NewMailTypeForward:
        {
            self.title = @"转发";
            //初始化header数据
            self.composeHeaderView.editViewType = MailAddressFlowEditViewTypeRecipient;
            MCOMessageHeader *header = [self.originImapMessage.header forwardHeader];
            header.subject = [NSString stringWithFormat:@"转发：%@", subject];
            [self.composeHeaderView setHeader:header];
            //初始化正文数据
            self.mailWriteTextView.text = [MailSignature stringByAppendingString:ReplyAndForwardMailBodyPlaceholder];
            [self.mailWriteTextView refreshHeight];
        }
            break;
            case NewMailTypeDraft://草稿
            case NewMailTypeSending://发件箱
        {
            //初始化header数据
            self.composeHeaderView.editViewType = MailAddressFlowEditViewTypeNone;
            [self.composeHeaderView setHeader:self.mailMessage.header];
            if (self.mailMessage.header.to.count > 0 || self.mailMessage.header.cc.count > 0 || self.mailMessage.header.bcc.count > 0) {
                self.sendBarButtonItem.enabled = YES;
            }
            //初始化正文数据
            [self.mailWriteTextView refreshHeight];
            [self.mailWriteTextView becomeFirstResponder];
            self.mailWriteTextView.text = self.mailMessage.bodyText;
            self.mailWriteTextView.selectedRange = NSMakeRange(0, 0);
        }
            break;
        default:
            break;
    }
}

/**
 *  设置navbar上的搜索按钮
 */
- (void)setupNavigationBar {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed:)];
    
    self.navigationItem.rightBarButtonItem = self.sendBarButtonItem;
}

- (void)startDownloadOriginMessageAttachments {    
    [self downloadOriginMessageAttachmentAtIndex:0];
}

- (void)downloadOriginMessageAttachmentAtIndex:(NSUInteger)index {
    NSUInteger count = self.originImapMessage.attachments.count;
    if (index < count) {
        MCOIMAPPart *part = [self.originImapMessage.attachments objectAtIndex:index];
        NSString *path = [[ZGMailModule sharedInstance] cachePathForPart:part withMessageID:self.originImapMessage.header.messageID];
        NSData *cachedData = [NSData dataWithContentsOfFile:path];
        if (!cachedData) {//下载
            __weak typeof(self) weakSelf = self;
            
            operation = [self.session fetchMessageAttachmentOperationWithFolder:self.originMessageFolder uid:[self.originImapMessage uid] partID:[part partID] encoding:[part encoding]];
            [operation setProgress:^(unsigned int current, unsigned int maximum) {
                MCLog("progress content: %u/%u", current, maximum);
            }];
            
            [operation start:^(NSError *error, NSData *data) {
                __strong typeof(weakSelf) strongSelf = weakSelf;

                if ([error code] != MCOErrorNone) {
                    return;
                }
                NSAssert(data != NULL, @"data != nil");
                //保存数据到本地
                [[ZGMailModule sharedInstance] cacheData:data forPart:part withMessageID:strongSelf.originImapMessage.header.messageID];
                
                //数据添加到数组
                [strongSelf.originMessageParts addObject:part];
                
                [strongSelf downloadOriginMessageAttachmentAtIndex:index + 1];
            }];
        } else {//已下载
            //数据添加到数组
            [self.originMessageParts addObject:part];
            [self downloadOriginMessageAttachmentAtIndex:index + 1];
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            //全部附件下载结束
            self.mailWriteTextView.hidden = NO;
            self.messageView.hidden = NO;
            [self.loadingLabel removeFromSuperview];
            
            [self showAttachmentView];
        });
    }
}

- (void)scrollToBottom {
    float offsetY = self.composeHeaderView.height + self.mailWriteTextView.height - (self.myScrollView.height - self.myScrollView.contentInset.bottom);
    self.myScrollView.contentOffset = CGPointMake(0, offsetY);
}

/**
 *  展示图片选择页面
 */
- (void)showImagePickerController {    
    [self.view endEditing:YES];
    [self.composeHeaderView headerViewResignFirstResponder];

    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
    imagePickerVc.allowTakePicture = YES;
    imagePickerVc.allowPickingVideo = NO;
    imagePickerVc.maxImagesCount = 100;
    imagePickerVc.selectedAssets = self.selectedAssets;
    imagePickerVc.alwaysEnableDoneBtn = YES;
    imagePickerVc.autoDismiss = NO;
    [self presentViewController:imagePickerVc animated:YES completion:^{
    }];
}

- (void)showAttachmentImagesWithCurrentIndex:(NSInteger)index {
    // Create browser
    MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithDelegate:self];
    browser.displayActionButton = NO;
    browser.displayNavArrows = YES;
    browser.displaySelectionButtons = NO;
    browser.alwaysShowControls = NO;
    browser.zoomPhotosToFill = NO;
    browser.enableGrid = NO;
    browser.startOnGrid = NO;
    [browser setCurrentPhotoIndex:index];
    
    // Modal
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:browser];
    nc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:nc animated:YES completion:nil];
}

- (void)showAttachmentView {
    //更新数据
    NSMutableArray *array = [[NSMutableArray alloc] initWithArray:self.originattachmentsFilenameArray];
    [array addObjectsFromArray:self.attachmentsFilenameArray];
    self.attachmentView.originMessageAttachments = [[NSMutableArray alloc] initWithArray:self.originMessageParts copyItems:YES];
    self.attachmentView.attachmentsFilenameArray = array;
    
    //刷新附件视图
    [self.attachmentView reloadAttachmentView];
    
    //更新附件视图高度
    [self updateAttachmentViewHeight];
}

//监听触发
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentSize"]) {
        float height = [self.messageView.webScrollView contentSize].height;
        self.messageViewHeightConstraint.offset = height;
    } else if ([keyPath isEqualToString:@"contentOffset"]) {
       
    }
}

- (BOOL)shouldShowSaveDraftAlertController {
    if (self.newMailType == NewMailTypeDraft || self.newMailType == NewMailTypeSending) {
        return YES;
    } else {
        if (self.newMailType == NewMailTypeDefault) {//新邮件
            //有收件人||有主题||有正文||有附件，满足一个条件都要弹出保存草稿提示
            if (self.composeHeaderView.header.to.count > 0 || self.composeHeaderView.header.cc.count > 0 || self.composeHeaderView.header.bcc.count > 0 || self.composeHeaderView.header.subject.length > 0 || ![self.mailWriteTextView.text isEqualToString:MailSignature] || self.originMessageParts.count > 0 || self.attachmentsFilenameArray.count > 0) {
                return YES;
            } else {
                return NO;
            }
        } else {
            //有收件人||有主题||有正文||有附件，满足一个条件都要弹出保存草稿提示
            if (self.composeHeaderView.header.to.count > 0 || self.composeHeaderView.header.cc.count > 0 || self.composeHeaderView.header.bcc.count > 0 || self.composeHeaderView.header.subject.length > 0 || ![self.mailWriteTextView.text isEqualToString:[MailSignature stringByAppendingString:ReplyAndForwardMailBodyPlaceholder]] || self.originMessageParts.count > 0 || self.attachmentsFilenameArray.count > 0) {
                return YES;
            } else {
                return NO;
            }
        }
    }
}

- (void)updateAttachmentViewHeight {
    //更新附件视图高度
    NSUInteger totalCount = [self totalAttachmentNumber];
    if (totalCount == 0) {
        self.attachmentViewHeightConstraint.offset = 0;
        [self.myScrollView layoutIfNeeded];
        
        //添加单击手势
        [self.myScrollView addGestureRecognizer:self.tapGesture];
    } else {
        self.attachmentViewHeightConstraint.offset = [self.attachmentView calculateHeightOfAttachmentViewWithAttachmentCount:totalCount + 1];
        [self.myScrollView layoutIfNeeded];
        
        //移除单击手势
        [self.myScrollView removeGestureRecognizer:self.tapGesture];
    }
}

- (NSUInteger)totalAttachmentNumber {
    return self.originMessageParts.count + self.originattachmentsFilenameArray.count + self.attachmentsFilenameArray.count;
}

- (BOOL)isRecipientArrayNull {
    NSUInteger count = self.composeHeaderView.header.to.count + self.composeHeaderView.header.cc.count + self.composeHeaderView.header.bcc.count;
    if (count == 0) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - setter and getter

- (UIBarButtonItem *)sendBarButtonItem {
    if (_sendBarButtonItem == nil) {
        _sendBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStyleDone target:self action:@selector(sendButtonPressed:)];
        _sendBarButtonItem.enabled = NO;
    }
    
    return _sendBarButtonItem;
}

- (UIScrollView *)myScrollView {
    if (_myScrollView == nil) {
        _myScrollView = [[UIScrollView alloc] init];
        _myScrollView.backgroundColor = [UIColor whiteColor];
        _myScrollView.alwaysBounceVertical = YES;
    }
    
    return _myScrollView;
}

- (ZGComposeHeaderView *)composeHeaderView {
    if (_composeHeaderView == nil) {
        _composeHeaderView = [[ZGComposeHeaderView alloc] init];
        _composeHeaderView.backgroundColor = [UIColor clearColor];
        _composeHeaderView.delegate = self;
    }
    
    return _composeHeaderView;
}

- (UILabel *)loadingLabel {
    if (_loadingLabel == nil) {
        _loadingLabel = [[UILabel alloc] init];
        _loadingLabel.text = @"正在载入...";
        _loadingLabel.textColor = [UIColor colorWithHexString:@"969696" alpha:1.0f];
        _loadingLabel.font = [UIFont systemFontOfSize:17.0f];
    }
    
    return _loadingLabel;
}

- (HPGrowingTextView *)mailWriteTextView {
    if (_mailWriteTextView == nil) {
        _mailWriteTextView = [[HPGrowingTextView alloc] init];
        _mailWriteTextView.minHeight = 100;
        _mailWriteTextView.maxHeight = 10000;
        _mailWriteTextView.delegate = self;
        _mailWriteTextView.returnKeyType = UIReturnKeyDefault;
        _mailWriteTextView.contentInset = UIEdgeInsetsMake(20, 15, 20, 15);
        
        _mailWriteTextView.internalTextView.contentInset = UIEdgeInsetsZero;
        _mailWriteTextView.internalTextView.textContainer.lineFragmentPadding = 0;
        //调整行距
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineSpacing:4];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
        [_mailWriteTextView.internalTextView setTypingAttributes:attrsDictionary];
        
        _mailWriteTextView.font = [UIFont systemFontOfSize:17.0f];
    }
    
    return _mailWriteTextView;
}

- (ZGWriteMailAttachmentView *)attachmentView {
    if (_attachmentView == nil) {
        _attachmentView = [[ZGWriteMailAttachmentView alloc] init];
        _attachmentView.delegate = self;
    }
    
    return _attachmentView;
}

- (MCOMessageView *)messageView {
    if (_messageView == nil) {
        _messageView = [[MCOMessageView alloc] init];
        _messageView.delegate = self;
        _messageView.messageType = MessageTypeOriginal;//写邮件页面展示的都是原始邮件
        _messageView.session = self.session;
        _messageView.folder = self.originMessageFolder;
    }
    
    return _messageView;
}

- (NSMutableArray *)originMessageParts {
    if (_originMessageParts == nil) {
        _originMessageParts = [[NSMutableArray alloc] init];
    }
    
    return _originMessageParts;
}

- (NSMutableArray *)attachmentsFilenameArray {
    if (_attachmentsFilenameArray == nil) {
        _attachmentsFilenameArray = [[NSMutableArray alloc] init];
    }
    
    return _attachmentsFilenameArray;
}

- (NSMutableArray *)selectedAssets {
    if (_selectedAssets == nil) {
        _selectedAssets = [[NSMutableArray alloc] init];
    }
    
    return _selectedAssets;
}

@end
