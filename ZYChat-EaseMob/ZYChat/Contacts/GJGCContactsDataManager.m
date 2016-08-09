//
//  GJGCContactsDataManager.m
//  ZYChat
//
//  Created by ZYVincent on 16/8/8.
//  Copyright © 2016年 ZYProSoft. All rights reserved.
//

#import "GJGCContactsDataManager.h"
#import "EMCursorResult.h"
#import "GJGCGroupInfoExtendModel.h"
#import "Base64.h"
#import "GJGCContactsBaseCell.h"
#import "GJGCMessageExtendGroupModel.h"

@interface GJGCContactsDataManager ()

@property (nonatomic,strong)NSMutableArray *sourceArray;

@end

@implementation GJGCContactsDataManager

- (instancetype)init
{
    if (self = [super init]) {
        
        self.sourceArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (NSInteger)totalSection
{
    return self.sourceArray.count;
}

- (GJGCContactsSectionModel *)sectionModelAtSectionIndex:(NSInteger)section
{
    return self.sourceArray[section];
}

- (void)updateSectionIsChangeExpandStateAtSection:(NSInteger)section
{
    GJGCContactsSectionModel *sectionModel = [self sectionModelAtSectionIndex:section];
    sectionModel.isExpand = !sectionModel.isExpand;
    [self.sourceArray replaceObjectAtIndex:section withObject:sectionModel];
    [self.delegate dataManagerRequireRefreshSection:section];
}

- (NSInteger)rowCountsInSection:(NSInteger)section
{
    NSArray *sectionArray = [self.sourceArray objectAtIndex:section];
    
    return sectionArray.count;
}

- (GJGCContactsContentModel *)contentModelAtIndexPath:(NSIndexPath *)indexPath
{
    GJGCContactsSectionModel *sectionModel = [self.sourceArray objectAtIndex:indexPath.section];
    
    return [sectionModel.rowData objectAtIndex:indexPath.row];
}

- (CGFloat)contentHeightAtIndexPath:(NSIndexPath *)indexPath
{
    GJGCContactsContentModel *contentModel = [self contentModelAtIndexPath:indexPath];
    return contentModel.contentHeight;
}

- (Class)cellClassAtIndexPath:(NSIndexPath*)indexPath
{
    GJGCContactsContentModel *contentModel = [self contentModelAtIndexPath:indexPath];
    return [GJGCContactsConst cellClassForContentType:contentModel.contentType];
}

- (NSString *)cellIdentifierAtIndexPath:(NSIndexPath *)indexPath
{
    GJGCContactsContentModel *contentModel = [self contentModelAtIndexPath:indexPath];
    return [GJGCContactsConst cellIdentifierForContentType:contentModel.contentType];
}

- (void)requireContactsList
{
    //获取联系人
    NSArray *friendList = [[EMClient sharedClient].contactManager getContacts];
    NSMutableArray *mFriendList = [NSMutableArray array];
    GJGCContactsSectionModel *friendSection = [[GJGCContactsSectionModel  alloc]init];
    friendSection.sectionTitle = @"我的好友";
    for (NSString *contact in friendList) {
        GJGCContactsContentModel *model = [[GJGCContactsContentModel alloc]init];
        model.contentHeight = 56.f;
        model.contentType = GJGCContactsContentTypeUser;
        model.nickname = contact;
        model.contentHeight = [self caculateHeightForContentModel:model];
        [mFriendList addObject:model];
    }
    friendSection.rowData = mFriendList;
    friendSection.isExpand = YES;
    [self.sourceArray addObject:friendSection];
    
    //获取群列表
    NSArray *groupList = [[EMClient sharedClient].groupManager getAllGroups];
    GJGCContactsSectionModel *groupSection = [[GJGCContactsSectionModel  alloc]init];
    groupSection.sectionTitle = @"我的群组";
    NSMutableArray *mGroupList = [NSMutableArray array];
    for (EMGroup *group in groupList) {
        GJGCContactsContentModel *model = [[GJGCContactsContentModel alloc]init];
        model.contentType = GJGCContactsContentTypeUser;
        model.groupId = group.groupId;
        model.isGroupChat = YES;
        
        NSData *extendData = [group.subject base64DecodedData];
        NSDictionary *extendDict = [NSKeyedUnarchiver unarchiveObjectWithData:extendData];
        
        GJGCGroupInfoExtendModel *groupInfoExtend = [[GJGCGroupInfoExtendModel alloc]initWithDictionary:extendDict error:nil];
        
        if(groupInfoExtend){
            model.nickname = groupInfoExtend.name;
            model.headThumb = groupInfoExtend.headUrl;
            model.summary = groupInfoExtend.simpleDescription;
            GJGCMessageExtendGroupModel *groupModel = [[GJGCMessageExtendGroupModel alloc]init];
            groupModel.groupName = groupInfoExtend.name;
            groupModel.groupHeadThumb = groupInfoExtend.headUrl;
            model.groupInfo = groupModel;
        }
        
        model.contentHeight = [self caculateHeightForContentModel:model];

        [mGroupList addObject:model];
    }
    groupSection.rowData = mGroupList;
    groupSection.isExpand = YES;
    [self.sourceArray addObject:groupSection];
    
    [self.delegate dataManagerrequireRefreshNow];
}

- (CGFloat)caculateHeightForContentModel:(GJGCContactsContentModel *)model
{
    Class cellClass = [GJGCContactsConst cellClassForContentType:model.contentType];
    GJGCContactsBaseCell *cell = [[cellClass alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    [cell setContentModel:model];
    return [cell cellHeight];
}

@end
