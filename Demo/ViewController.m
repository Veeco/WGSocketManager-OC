//
//  ViewController.m
//  Demo
//
//  Created by VS on 23/01/2017.
//  Copyright © 2017 JianWei. All rights reserved.
//

#import "ViewController.h"
#import "WGSocketManager.h"

@interface ViewController ()<WGSocketManagerProtocol>

/** 内容输出控件 */
@property (weak, nonatomic) IBOutlet UITextView *contentTextView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [WGSocketManager manager].delegate = self;
}

/**
 * 监听link按钮点击
 */
- (IBAction)link {
    
    NSString *host = @"192.168.1.123";
    NSInteger port = 6666;
    
    // 连接服务器
    [[WGSocketManager manager] connectToServerWithIP:host andPort:port];
}

/**
 * 监听send按钮点击
 */
- (IBAction)send {
    
    NSDictionary *dic = @{@"name":@"Veeco"};
    
    // 发送数据
    [[WGSocketManager manager] sendToServerWithData:dic];
}

/**
 * 监听cut按钮点击
 */
- (IBAction)cut {
    
    // 断开连接
    [[WGSocketManager manager] disconnectToServer];
}

/**
 * 监听clear按钮点击
 */
- (IBAction)clear {
    
    // 清空输出控件
    self.contentTextView.text = nil;
}

#pragma mark - <WGSocketManagerProtocol>

/**
 * 代理方法1. 与服务器连接成功时会调用
 * 参数 socketManager 本管理者
 */
- (void)connectSucceededToServerWithSocketManager:(nonnull WGSocketManager *)socketManager {

    self.contentTextView.text = [NSString stringWithFormat:@"%@\n连接成功", self.contentTextView.text];
}

/**
 * 代理方法2. 接收到服务器发送的数据时会调用
 * 参数 socketManager 本管理者
 * 参数 data 所收到的数据(NSArray / NSDictionary)
 * 参数 dataLength 所收到的数据长度(字节)
 */
- (void)socketManager:(nonnull WGSocketManager *)socketManager receiveData:(nonnull id)data dataLength:(NSInteger)dataLength {

    self.contentTextView.text = [NSString stringWithFormat:@"%@\n收到的数据字节长度为%zd\n%@\n", self.contentTextView.text, dataLength, data];
}

/**
 * 代理方法3. 与服务器连接失败时会调用(试图与不存在的服务器连接时也会调用)
 * 参数 socketManager 本管理者
 */
- (void)connectFailedToServerWithSocketManager:(nonnull WGSocketManager *)socketManager {

    self.contentTextView.text = [NSString stringWithFormat:@"%@\n连接失败", self.contentTextView.text];
}

@end
