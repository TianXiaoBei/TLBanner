//
//  TLBannerView.m
//  TLBannerView
//
//  Created by Tianlong on 2017/6/22.
//  Copyright © 2017年 Tianlong. All rights reserved.
//

#import "TLBannerView.h"

#define DefaultScrollDuration 5 //默认轮播的时间间隔
/** 弱引用宏 */
#define WS(weakSelf)  __weak __typeof(&*self)weakSelf = self;

@interface TLBannerView ()<UIScrollViewDelegate>

@property (nonatomic , weak) TLScrollView *scrollView;
@property (nonatomic , weak) UIPageControl *pageContol;
/** 当前图片的索引 */
@property (nonatomic , assign) NSInteger curIndex;
/** 定时器 */
@property (nonatomic, strong) NSTimer *scrollTimer;
/** 是否自动播放 */
@property (nonatomic , assign) BOOL autoPlay;

/** init方法专用数据源 */
@property (nonatomic , strong) NSArray *privateImages;
/** init方法专用轮播间隔 */
@property (nonatomic , assign) NSTimeInterval privateDuration;
/** 通过init方法创建的banner，不设置 scrollDuration */
@property (nonatomic , assign) BOOL fromInit;
@end

@implementation TLBannerView

static  CGFloat criticalValue = .2f;

/** 默认自动滚动 <=1张 图片时隐藏pagecontrol，并且不自动滚动  ； >1张 时显示pagecontrol
 @param duration 播放间隔
 */
-(instancetype)initWithImages:(NSArray *)images scrollDuration:(NSTimeInterval)duration{
    if (self = [super init]) {
        self.fromInit = YES;
        self.privateImages = [NSArray arrayWithArray:images];
        self.privateDuration = duration;
        if (duration <= 0) {
            //默认5秒调轮播一张图
            self.privateDuration = DefaultScrollDuration;
        }
        
        //开启banner之旅
        [self startInitBanner];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
//        if (!self.fromInit) {
//            //默认5秒调轮播一张图
//            self.scrollDuration = DefaultScrollDuration;
//        }
        
        //开启banner之旅
        [self startBanner];
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]){
        
//        if (!self.fromInit) {
//            //默认5秒调轮播一张图
//            self.scrollDuration = DefaultScrollDuration;
//        }
        
        //开启banner之旅
        [self startBanner];
    }
    return self;
}


#pragma mark - 点击图片
-(void)tapImage{
    if ([self.delegate respondsToSelector:@selector(bannerView:indexFromClickedPicture:)]) {
        [self.delegate bannerView:self indexFromClickedPicture:self.curIndex];
    }
    //NSLog(@" 点击的index  = %ld",(long)self.curIndex);
}

#pragma mark - lazyLoad：懒加载
-(TLScrollView *)scrollView{
    if (_scrollView == nil) {
        TLScrollView *scrollV = [[TLScrollView alloc] init];
        _scrollView = scrollV;
        _scrollView.backgroundColor = [UIColor whiteColor];
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        
        WS(ws);
        [_scrollView setTapImageBlcok:^() {
            [ws tapImage];
            if (ws.selectedBlock) {
                ws.selectedBlock(ws,ws.curIndex);
            }
            //点击图片的时候，先停止定时器，取消因连续点击开启定时器的任务，在开启定时器，代表结束点击
            [ws pauseTimer];
            [NSObject cancelPreviousPerformRequestsWithTarget:ws selector:@selector(startTimer) object:nil];
            [ws performSelector:@selector(startTimer) withObject:nil afterDelay:ws.scrollDuration > 0 ? ws.scrollDuration : ws.privateDuration];
        }];
        [self addSubview:_scrollView];
    }
    return _scrollView;
}

-(UIPageControl *)pageContol{
    if (_pageContol == nil) {
        //创建pagecontrol
        UIPageControl *pageContol = [[UIPageControl alloc] init];
        _pageContol = pageContol;
        _pageContol.pageIndicatorTintColor = [UIColor whiteColor];
        _pageContol.currentPageIndicatorTintColor = [UIColor redColor];
        [self addSubview:_pageContol];
    }
    return _pageContol;
}

-(NSTimer *)scrollTimer{
    
    if (_scrollTimer == nil) {
        
        _scrollTimer = [NSTimer scheduledTimerWithTimeInterval:self.scrollDuration
                                                        target:self
                                                      selector:@selector(scrollTimerDidFired:)
                                                      userInfo:nil
                                                       repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_scrollTimer forMode:NSRunLoopCommonModes];
    }
    return _scrollTimer;
}

#pragma mark - setImages / setScrollDuration / setPrivateDuration
-(void)setImages:(NSArray *)images{
    _images = images;
    [self startBanner];
}

-(void)setScrollDuration:(NSTimeInterval)scrollDuration{
    
    _scrollDuration = scrollDuration;
    
    if (_scrollDuration <= 0) {
        _scrollDuration = DefaultScrollDuration;
    }
    
    [self destroyTimer];
    //重新设置轮播间隔
    self.scrollTimer = [NSTimer scheduledTimerWithTimeInterval:scrollDuration
                                                    target:self
                                                  selector:@selector(scrollTimerDidFired:)
                                                  userInfo:nil
                                                   repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.scrollTimer forMode:NSRunLoopCommonModes];
    
    if (self.images.count <= 1) {
        [self pauseTimer];
    }
}

-(void)setPrivateDuration:(NSTimeInterval)privateDuration{
    
    _privateDuration = privateDuration;
    if (_privateDuration <= 0) {
        _privateDuration = DefaultScrollDuration;
    }
    
    [self destroyTimer];
    //重新设置轮播间隔
    self.scrollTimer = [NSTimer scheduledTimerWithTimeInterval:privateDuration
                                                        target:self
                                                      selector:@selector(scrollTimerDidFired:)
                                                      userInfo:nil
                                                       repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.scrollTimer forMode:NSRunLoopCommonModes];
    
    if (self.privateImages.count <= 1) {
        [self pauseTimer];
    }
}

#pragma mark - 开启banner
/** 核心代码：添加对scrollview的contentoffset的监听，处理不同数量图片加pagecontrol 和定时器的逻辑 */
-(void)startBanner{
    
    if (self.images == nil) return;
    
    if(self.images.count > 1){
        
        self.autoPlay = YES;
        self.curIndex = 1;
        self.scrollView.scrollEnabled = YES;
        self.pageContol.hidden = NO;
        
        /** 大于1张图片时是在scrollview中设置的contentsize */
        
        if (self.autoPlay && self.scrollDuration > 0) {
            [self startTimer];
        }
    }
    else if (self.images.count == 1){
        
        self.autoPlay = NO;
        self.curIndex = 0;
        self.scrollView.scrollEnabled = NO;
        self.pageContol.hidden = YES;
        self.scrollView.contentSize =  CGSizeMake(CGRectGetWidth(self.scrollView.bounds), 0);
        
        if (self.autoPlay && self.scrollDuration > 0) {
            [self startTimer];
        }
    }
    else{
        self.autoPlay = NO;
        self.scrollView.scrollEnabled = NO;
        self.pageContol.hidden = YES;
        self.scrollView.contentSize = CGSizeZero;
        
        [self pauseTimer];
    }
    [self.pageContol setNumberOfPages:self.images.count];
    //添加对scrollview的contentOffset的监听
    [self addObservers];
}

#pragma mark - 开启init方法创建的banner之旅
-(void)startInitBanner{
    
    if (self.privateImages == nil) return;
    
    if(self.privateImages.count > 1){
        
        self.autoPlay = YES;
        self.curIndex = 1;
        self.scrollView.scrollEnabled = YES;
        self.pageContol.hidden = NO;
        
        /** 大于1张图片时是在scrollview中设置的contentsize */
        
        if (self.autoPlay && self.scrollDuration > 0) {
            [self startTimer];
        }
    }
    else if (self.privateImages.count == 1){
        
        self.autoPlay = NO;
        self.curIndex = 0;
        self.scrollView.scrollEnabled = NO;
        self.pageContol.hidden = YES;
        self.scrollView.contentSize =  CGSizeMake(CGRectGetWidth(self.scrollView.bounds), 0);
        
        if (self.autoPlay && self.scrollDuration > 0) {
            [self startTimer];
        }
    }
    else{
        self.autoPlay = NO;
        self.scrollView.scrollEnabled = NO;
        self.pageContol.hidden = YES;
        self.scrollView.contentSize = CGSizeZero;
        
        [self pauseTimer];
    }
    [self.pageContol setNumberOfPages:self.privateImages.count];
    //添加对scrollview的contentOffset的监听
    [self addObservers];
}

#pragma mark - 无限轮播核心代码（不包含定时器的）
/** 计算当前观看图片的索引 */
- (void)caculateCurIndex {
    if (self.images.count > 0) {
        
        CGFloat pointX = self.scrollView.contentOffset.x;
        
        if (pointX > 2 * CGRectGetWidth(self.scrollView.bounds) - criticalValue) {
            self.curIndex = (self.curIndex + 1) % self.images.count;
        }
        else if (pointX < criticalValue) {
            self.curIndex = (self.curIndex + self.images.count - 1) % self.images.count;
        }
    }
    else{
        if (self.privateImages.count > 0) {
            CGFloat pointX = self.scrollView.contentOffset.x;
            
            if (pointX > 2 * CGRectGetWidth(self.scrollView.bounds) - criticalValue) {
                self.curIndex = (self.curIndex + 1) % self.privateImages.count;
            }
            else if (pointX < criticalValue) {
                self.curIndex = (self.curIndex + self.privateImages.count - 1) % self.privateImages.count;
            }
        }
    }
    
    //设置pagecontrol
    [self.pageContol setCurrentPage:self.curIndex];
    //NSLog(@"当前选中的索引：%ld",(long)self.curIndex);
}


/** 设置 curIndex */
- (void)setCurIndex:(NSInteger)curIndex {
    
    _curIndex = curIndex;
    
    if (self.images.count > 0) {
        NSInteger imageCount = self.images.count;
        if (imageCount > 0) {
            NSInteger leftIndex = (curIndex + imageCount - 1) % imageCount;
            NSInteger rightIndex= (curIndex + 1) % imageCount;
            
            self.scrollView.leftV.image = [UIImage imageNamed:self.images[leftIndex]];
            self.scrollView.midV.image = [UIImage imageNamed:self.images[curIndex]];
            self.scrollView.rightV.image = [UIImage imageNamed:self.images[rightIndex]];
        }
    }
    else{
        if (self.privateImages.count > 0) {
            NSInteger imageCount = self.privateImages.count;
            if (imageCount > 0) {
                NSInteger leftIndex = (curIndex + imageCount - 1) % imageCount;
                NSInteger rightIndex= (curIndex + 1) % imageCount;
                
                self.scrollView.leftV.image = [UIImage imageNamed:self.privateImages[leftIndex]];
                self.scrollView.midV.image = [UIImage imageNamed:self.privateImages[curIndex]];
                self.scrollView.rightV.image = [UIImage imageNamed:self.privateImages[rightIndex]];
            }
        }
    }
    
    //复位scrollview的contentoffset
    [self resetContentOffset];
}

/** 复位scrollview */
- (void)resetContentOffset {
    self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(self.scrollView.bounds), 0);
}


#pragma mark - KVO 监听 contentOffset的变化 来重新计算当前的索引
- (void)addObservers {
    [self.scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        [self caculateCurIndex];
    }
}

- (void)removeObservers {
    [self.scrollView removeObserver:self forKeyPath:@"contentOffset"];
}

#pragma mark - layoutSubviews：布局子控件
-(void)layoutSubviews{
    [super layoutSubviews];
    
    WS(ws);
    [self.scrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.right.offset(0);
        make.width.offset(ws.bounds.size.width);
        make.height.offset(ws.bounds.size.height);
    }];
    
    [self.pageContol mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(ws.mas_centerX);
        make.bottom.offset(-20);
        make.height.offset(10);
    }];
}

#pragma mark - 定时器的相关逻辑 - UIScrollViewDelegate
/** 定时器调用的方法 */
- (void)scrollTimerDidFired:(NSTimer *)timer {
    
    if (self.scrollView.contentOffset.x < CGRectGetWidth(self.scrollView.bounds) - criticalValue || self.scrollView.contentOffset.x > CGRectGetWidth(self.scrollView.bounds) + criticalValue) {
        [self resetContentOffset];
    }
    CGPoint newOffset = CGPointMake(self.scrollView.contentOffset.x + CGRectGetWidth(self.scrollView.bounds), self.scrollView.contentOffset.y);
    [self.scrollView setContentOffset:newOffset animated:YES];
}

/** 开启定时器 */
-(void)startTimer{
    
    if (self.scrollTimer != nil && self.autoPlay) {
        [self.scrollTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:self.privateDuration > 0 ? self.privateDuration : self.scrollDuration]];
    }
}

/** 暂停定时器 */
-(void)pauseTimer{
    if (self.scrollTimer != nil) {
        [self.scrollTimer setFireDate:[NSDate distantFuture]];
    }
}

/** 销毁定时器 */
-(void)destroyTimer{
    [self.scrollTimer invalidate];
    self.scrollTimer = nil;
}

/** 开始拖拽 */
-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    //开始拖拽，暂停定时器
    [self pauseTimer];
}

/** 滚动中 */
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{}

/** 松手后，停止拖拽：先执行这个方法 1步 */
-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset{}

/** 松手后，停止拖拽：在执行这个方法 2步 */
-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{}

/** 松手后，停止拖拽：最后执行这个方法 3步 */
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self startTimer];
}


-(void)dealloc{
    [self removeObservers];
    [self destroyTimer];
}
@end


#pragma mark - TLScrollView - @implementation
@implementation TLScrollView
//固定的3个imageView实现无线轮播
static CGFloat FixedViewCount = 3;

-(instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        UIImageView *leftV = [[UIImageView alloc] init];
        self.leftV = leftV;
        self.leftV.userInteractionEnabled = YES;
        [self addSubview:leftV];
        
        UITapGestureRecognizer *tapLeft = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
        [self.leftV addGestureRecognizer:tapLeft];
        
        
        UIImageView *midV = [[UIImageView alloc] init];
        self.midV = midV;
        self.midV.userInteractionEnabled = YES;
        [self addSubview:midV];
        
        UITapGestureRecognizer *tapMid = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
        [self.midV addGestureRecognizer:tapMid];
        
        
        UIImageView *rightV = [[UIImageView alloc] init];
        self.rightV = rightV;
        self.rightV.userInteractionEnabled = YES;
        [self addSubview:rightV];
        
        UITapGestureRecognizer *tapRight = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapImage:)];
        [self.rightV addGestureRecognizer:tapRight];
        
    }
    return self;
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder{
    if(self = [super initWithCoder:aDecoder]){
        UIImageView *leftV = [[UIImageView alloc] init];
        self.leftV = leftV;
        [self addSubview:leftV];
        
        UIImageView *midV = [[UIImageView alloc] init];
        self.midV = midV;
        [self addSubview:midV];
        
        UIImageView *rightV = [[UIImageView alloc] init];
        self.rightV = rightV;
        [self addSubview:rightV];
    }
    return self;
}

-(void)tapImage:(UIGestureRecognizer *)tap{
    if (self.tapImageBlcok) {
        self.tapImageBlcok();
    }
}


-(void)layoutSubviews{
    [super layoutSubviews];
    
    self.contentSize = CGSizeMake(self.bounds.size.width*FixedViewCount, 0);
    
    WS(ws);
    if (self.bounds.size.width > 0 && self.bounds.size.height > 0) {
        [self.leftV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(0);
            make.top.offset(0);
            make.height.mas_equalTo(ws);
            make.width.mas_equalTo(ws);
        }];
        
        [self.midV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(ws.bounds.size.width);
            make.top.offset(0);
            make.height.mas_equalTo(ws);
            make.width.mas_equalTo(ws);
        }];
        
        
        [self.rightV mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(ws.bounds.size.width*2);
            make.top.offset(0);
            make.height.mas_equalTo(ws);
            make.width.mas_equalTo(ws);
        }];
    }
}

@end
