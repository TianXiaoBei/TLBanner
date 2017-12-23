### 代码示例

```

#import "ViewController.h"
#import "TLBannerView.h"

@interface ViewController ()<TLBannerViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSArray *images = @[@"1.jpg",@"2.jpg",@"3.jpg",@"4.jpg",@"5.jpg",@"6.jpg"];
    //images = @[@"1.jpg"];
    
    //第1种创建方式
    TLBannerView *bannerV1 = [[TLBannerView alloc] init];
    bannerV1.images = images;
    bannerV1.scrollDuration = 1;
    bannerV1.delegate = self;
    //block 代理 任君选择
    [bannerV1 setSelectedBlock:^(TLBannerView *bannerV, NSInteger index) {
        NSLog(@"点击的索引：SelectedBlock = %ld",(long)index);
    }];
    
    [self.view addSubview:bannerV1];
    [bannerV1 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(10);
        make.right.offset(-10);
        make.top.offset(64);
        make.height.offset(200);
    }];
    
    //第2种创建方式
    TLBannerView *bannerV2 = [[TLBannerView alloc] initWithImages:images scrollDuration:3];
    bannerV2.delegate = self;
    //block 代理 任君选择
    [bannerV2 setSelectedBlock:^(TLBannerView *bannerV, NSInteger index) {
        NSLog(@"点击的索引：SelectedBlock = %ld",(long)index);
    }];
    
    [self.view addSubview:bannerV2];
    [bannerV2 mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(10);
        make.right.offset(-10);
        make.top.offset(274);
        make.height.offset(200);
    }];
    
}

-(void)bannerView:(TLBannerView *)bannerView indexFromClickedPicture:(NSInteger)index{
    NSLog(@"点击的索引：indexFromClickedPicture = %ld",(long)index);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end

```