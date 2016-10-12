//
//  ViewController.m
//  NSTreadOperation
//
//  Created by 刘松洪 on 16/10/12.
//  Copyright © 2016年 刘松洪. All rights reserved.
//

#import "ViewController.h"

#define ImageUrl @"http://img05.tooopen.com/images/20141208/sy_76623349543.jpg"

@interface ViewController ()
{
    int _tickets;
    int _count;
    NSThread*_ticketsThreadone;
    NSThread*_ticketsThreadtwo;
//    NSCondition* ticketsCondition;
    NSLock *_theLock;
}

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initliationData];
    [self threadLock];//线程锁
    
    [self threadTest];//thread线程下载
}

- (void)initliationData {
    _count   = 0;
    _tickets = 100;
    _theLock = [[NSLock alloc]init];
    
}

- (void)threadLock {
    _ticketsThreadone = [[NSThread alloc]initWithTarget:self selector:@selector(sellTicket) object:nil];
    [_ticketsThreadone setName:@"线程1"];
    [_ticketsThreadone start];
    
    _ticketsThreadtwo = [[NSThread alloc]initWithTarget:self selector:@selector(sellTicket) object:nil];
    [_ticketsThreadtwo setName:@"线程2"];
    [_ticketsThreadtwo start];
}

- (void)sellTicket {
    while (1) {
            [_theLock lock];
        if (_tickets > 0) {
            [NSThread sleepForTimeInterval:0.05];
            _count = 100 - _tickets;
         NSLog(@"当前票数是:%d,售出:%d,线程名:%@",_tickets,_count,[[NSThread currentThread] name]);
            _tickets--;
        }else {
            break;
        }
            [_theLock unlock];
    }
    
}

- (void)threadTest {
    NSThread *thread = [[NSThread alloc]initWithTarget:self selector:@selector(downloadImage:) object:ImageUrl];
    [thread start];
}

- (void)downloadImage:(NSString *)url {

    NSURLRequest *request = [[NSURLRequest alloc]initWithURL:[NSURL URLWithString:ImageUrl] cachePolicy:0 timeoutInterval:60.0];
    NSURLSession *theSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSURLSessionDownloadTask *task =  [theSession downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
       NSData *data = [[NSData alloc]initWithContentsOfURL:location];
        UIImage *image = [[UIImage alloc]initWithData:data];
        if (image) {
            //利用NSTHread 的mainqueue来更新图片
            [self performSelectorOnMainThread:@selector(updateImage:) withObject:image waitUntilDone:YES modes:@[NSDefaultRunLoopMode]];
            /*
             [self updateImage:image];
             */
        }
    }];
    [task resume];
    
    [self performSelectorInBackground:@selector(backgroundTest) withObject:nil];
}

- (void)backgroundTest {
    NSLog(@"后台执行");
}

- (void)updateImage:(UIImage *)image {
    self.imageView.image = [[self class] image:image scaleSize:CGSizeMake(self.imageView.frame.size.width, self.imageView.frame.size.height)];
    /*   利用gcd的主线程方法更新图片
     dispatch_async(dispatch_get_main_queue(), ^{
     self.imageView.image = [[self class] image:image scaleSize:CGSizeMake(self.imageView.frame.size.width, self.imageView.frame.size.height)];
     });
     */
  
}

///压缩图片
+ (UIImage *)image:(UIImage *)image scaleSize:(CGSize)size {

    //图片上下文入栈
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();

    //处理图片的上下文出栈
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

//裁剪一定区域
+ (UIImage *)imageFromeImage:(UIImage *)image inRect:(CGRect)rect {
    CGImageRef sourceImageRef = [image CGImage];
    
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);
    
    return [UIImage imageWithCGImage:newImageRef];
}


+ (UIImage *)clipImage:(UIImage *)image toSize:(CGSize)size {
    //被裁剪的图片宽高比<=所需要的尺寸宽高比，以图片宽进行放大
    if (image.size.width * size.height <= image.size.height *size.width) {
        CGFloat width  = image.size.width;
        CGFloat height = image.size.width * size.height/size.width;
        return [self imageFromeImage:image inRect:CGRectMake(0, (image.size.height - height)/2, width, height)];
    }else {
        // 以被剪切图片的高度为基准，得到剪切范围的大小
        CGFloat width  = image.size.height * size.width / size.height;
        CGFloat height = image.size.height;
        
        // 调用剪切方法
        // 这里是以中心位置剪切，也可以通过改变rect的x、y值调整剪切位置
        return [self imageFromeImage:image inRect:CGRectMake((image.size.width -width)/2, 0, width, height)];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
