//
//  ViewController.m
//  RACSingleDemo
//
//  Created by HaRi on 2018/6/20.
//  Copyright © 2018年 Hari. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveObjC/ReactiveObjC.h>

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UITextField *textField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    [self dictionarySignal];
    
    
}
#pragma mark 三
- (void)liftingSignal
{
    RACSignal *signalA = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        double delayInSeconds = 5.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds *NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [subscriber sendNext:@"A"];
        });
        return nil;
    }];
    RACSignal *signalB = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"B"];
        [subscriber sendNext:@"@Another B"];
        [subscriber sendCompleted];
        return nil;
    }];
    [self rac_liftSelector:@selector(doA:withB:) withSignals:signalA,signalB, nil];
}
// 它的意思是当signalA和signalB都至少sendNext过一次，接下来只要其中任意一个signal有了新的内容，doA:withB这个方法就会自动被触发。
- (void)doA:(NSString *)A withB:(NSString *)B
{
    NSLog(@"A:%@ and B:%@",A, B);
}
// 遍历数组
- (void)arraySignal
{
    NSArray *numbers = @[@1,@2,@3,@4];
    [numbers.rac_sequence.signal subscribeNext:^(id x) {
        NSLog(@"++++%@",x);
    }];
}
// 遍历字典
- (void)dictionarySignal
{
    NSDictionary *dict = @{@"name":@"xmg",@"age":@18};
    [dict.rac_sequence.signal subscribeNext:^(id x) {
        RACTupleUnpack(NSString *key,NSString *value) = x;
        NSLog(@"%@   %@",key,value);
    }];
    
}
// 字典转模型
- (void)dictionaryToModel
{
    NSArray *arr = @[@{@"name" : @"1"},@{@"name" : @"2"},@{@"name" : @"3"},@{@"name" : @"4"},@{@"name" : @"5"}];
    NSMutableArray *items = [NSMutableArray array];
    // 一 ：
    //    [arr.rac_sequence.signal subscribeNext:^(id x) {
    //        FlagItem *item = [FlagItem flagWithDict:x];
    //        [items addObject:items];
    //    }];
    // 二 ：当信号被订阅，会遍历集合中的原始值，映射成新值，并且保存到新的数组里
    //    NSArray *flags = [[arr.rac_sequence map:^id(id value) {
    //        return [FlagItem flagWithDict:value];
    //    }] array];
}

#pragma mark 一
// KVO
- (void)kvoSignal
{
    UIScrollView *scrolView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 200, 200, 400)];
    scrolView.contentSize = CGSizeMake(200, 800);
    scrolView.backgroundColor = [UIColor greenColor];
    [self.view addSubview:scrolView];
    [RACObserve(scrolView, contentOffset) subscribeNext:^(id x) {
        NSLog(@"success====");
    }];
}

// 通知
- (void)notificationSignal
{
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:@"postData" object:nil] subscribeNext:^(NSNotification *notification) {
        NSLog(@"---%@",notification.name);
        NSLog(@"----%@",notification.object);
    }];
}
// 代理
- (void)delegateSignal
{
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"RAC" message:@"RAC" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"other", nil];
    //    [[self rac_signalForSelector:@selector(alertView:clickedButtonAtIndex:) fromProtocol:@protocol(UIAlertViewDelegate)] subscribeNext:^(RACTuple *x) {
    //        NSLog(@"----%@",x.first);
    //         NSLog(@"----%@",x.second);
    //         NSLog(@"----%@",x.third);
    //    }];
    // 简写
    [[alertView rac_buttonClickedSignal] subscribeNext:^(id x) {
        NSLog(@"----%@",x);
    }];
    [alertView show];
    
}

// 手势
- (void)tapSignal
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]init];
    [[tap rac_gestureSignal] subscribeNext:^(id x) {
        NSLog(@"tap+++++++++");
    }];
    [self.view addGestureRecognizer:tap];
}

- (void)textSignal
{
    //    [[self.textField rac_signalForControlEvents:UIControlEventEditingChanged] subscribeNext:^(id x) {
    //        NSLog(@"change %@",x);
    //    }];
    // 简写
    [[self.textField rac_textSignal] subscribeNext:^(id x) {
        NSLog(@"%@====",x);
    }];
}

#pragma mark 二

// timeout
/*
 超时信号，当超出限定时间后会给订阅者发送error信号。
 由于在创建信号是限定了延迟3秒发送，但是加了timeout2秒的限定，所以这一定是一个超时信号。这个信号被订阅后，由于超时，不会执行订阅成功的输出x方法，而是跳到error的块输出了错误信息。timeout在用RAC封装网络请求时可以节省不少的代码量
 */
- (void)timeoutSignal
{
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[RACScheduler mainThreadScheduler] afterDelay:3 schedule:^{
            [subscriber sendNext:@"delay"];
            [subscriber sendCompleted];
            
        }];
        return nil;
    }] timeout:2 onScheduler:[RACScheduler mainThreadScheduler]];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"----%@",x);
    } error:^(NSError *error) {
        NSLog(@"+++++%@",error);
    }];
}
// ignore
/*
 忽略信号，指定一个任意类型的量（可以是字符串，数组等），当需要发送信号时讲进行判断，若相同则该信号会被忽略发送
 */
- (void)ignoreSignal
{
    [[self.textField.rac_textSignal ignore:@"good"] subscribeNext:^(id x) {
        NSLog(@"%@====",x);
    }];
}

// distinctUntilChanged
/*
 网络请求中为了减轻服务器压力，无用的请求我们应该尽可能不发送。distinctUntilChanged的作用是使RAC不会连续发送两次相同的信号，这样就解决了这个问题
 */
- (void)distinctUntilChangedSignal
{
    [[self.textField.rac_textSignal distinctUntilChanged] subscribeNext:^(id x) {
        NSLog(@"%@+++====",x);
    }];
}
// throttle 节流
/*
 在我们做搜索框的时候，有时候需求的时实时搜索，即用户每每输入字符，view都要求展现搜索结果。这时如果用户搜索的字符串较长，那么由于网络请求的延时可能造成UI显示错误，并且多次不必要的请求还会加大服务器的压力，这显然是不合理的，此时我们就需要用到节流
 */
- (void)throttleSignal
{
    [[self.textField.rac_textSignal throttle:0.5] subscribeNext:^(id x) {
        NSLog(@"----%@",x);
    }];
}

// take 获取， skip 跳过， repeat 重复发送信号。
/*
 takeLast 2 -- 获取最后两个
 takeLast takeUntil takeWhileBlock skipWhileBlock skipUntilBlock repeatWhileBlock
 */
- (void)takeSignanl
{
    // 获取 前2个信号
    RACSignal *signal = [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"1"];
        [subscriber sendNext:@"2"];
        [subscriber sendNext:@"3"];
        [subscriber sendNext:@"4"];
        [subscriber sendNext:@"5"];
        [subscriber sendCompleted];
        return nil;
    }]take:2];
    
    [signal subscribeNext:^(id x) {
        NSLog(@"+++++%@",x);
    } completed:^{
        NSLog(@"-----completed");
    }];
}

// filter 过滤 筛选出需要的信号变化
- (void)filterSignal
{
    [[self.textField.rac_textSignal filter:^BOOL(NSString *value) {
        return value.length > 3;
    }] subscribeNext:^(id x) {
        NSLog(@"----%@",x);
    }];
}

// map 信号的处理
- (void)dealSignal
{
    [[self.textField.rac_textSignal map:^id(NSString *value) {
        NSLog(@"---%@",value);
        return value;
        return @(value.length);
    }] subscribeNext:^(id x) {
        NSLog(@"+++%@",x);
    }];
}
// RACSignal 什么是信号
- (void)creatSignal
{
    // 创建信号
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@"signal"];
        [subscriber sendCompleted];
        [subscriber sendError:nil];
        return nil;
    }];
    
    // 订阅信号
    [signal subscribeNext:^(id x) {
        NSLog(@"x = %@",x);
    } error:^(NSError *error) {
        NSLog(@"error = %@", error);
    } completed:^{
        NSLog(@"completed");
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
