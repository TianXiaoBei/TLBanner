//
//  TLBannerView.h
//  TLBannerView
//
//  Created by Tianlong on 2017/6/22.
//  Copyright © 2017年 Tianlong. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Masonry.h"

typedef enum : NSUInteger {
    TLBannerTypeCarousel,//轮播
    TLBannerTypeBrowser,//相册浏览
} TLBannerType;


#pragma mark - TLScrollView
@class TLImageView;
@interface TLScrollView : UIScrollView
@property (nonatomic , weak) UIImageView *leftV;
@property (nonatomic , weak) UIImageView *midV;
@property (nonatomic , weak) UIImageView *rightV;
@property (nonatomic , assign) TLBannerType bannerType;
@property (nonatomic , copy) void (^tapImageBlcok)(void);
@property (nonatomic , copy) void (^clickedCoverBtn)(void);
@end

#pragma mark - TLBannerViewDelegate
@class TLBannerView;
@protocol TLBannerViewDelegate <NSObject>
@optional
/**
 @param bannerView 轮播视图
 @param index 点击的索引
 */
-(void)bannerView:(TLBannerView *)bannerView indexFromClickedPicture:(NSInteger)index;
@end


#pragma mark - TLBannerView
@interface TLBannerView : UIView
/**
 轮播的时间间隔
 */
@property (nonatomic , assign) NSTimeInterval scrollDuration;
@property (nonatomic , strong) NSArray *images;
@property (nonatomic , assign) TLBannerType bannerType;
@property (nonatomic , weak) id<TLBannerViewDelegate> delegate;
@property (nonatomic , copy) void (^selectedBlock)(TLBannerView *bannerV,NSInteger index);

/** 默认自动滚动 <=1张 图片时隐藏pagecontrol，并且不自动滚动  ； >1张 时显示pagecontrol
 @param duration 播放间隔
 @param images 图片数据源
 */
-(instancetype)initWithImages:(NSArray *)images scrollDuration:(NSTimeInterval)duration;

/** 开启定时器 */
-(void)startTimer;
/** 暂停定时器 */
-(void)pauseTimer;
/** 销毁定时器 */
-(void)destroyTimer;

@end
