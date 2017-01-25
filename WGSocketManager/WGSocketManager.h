//
//  WGSocketManager.h
//  Demo
//
//  Created by VS on 23/01/2017.
//  Copyright © 2017 JianWei. All rights reserved.
//

#import <Foundation/Foundation.h>
@class WGSocketManager;

@protocol WGSocketManagerProtocol <NSObject>

@optional

/**
 * 代理方法1. 与服务器连接成功时会调用
 * 参数 socketManager 本管理者
 */
- (void)connectSucceededToServerWithSocketManager:(nonnull WGSocketManager *)socketManager;

/**
 * 代理方法2. 接收到服务器发送的数据时会调用
 * 参数 socketManager 本管理者
 * 参数 data 所收到的数据(NSArray / NSDictionary)
 * 参数 dataLength 所收到的数据长度(字节)
 */
- (void)socketManager:(nonnull WGSocketManager *)socketManager receiveData:(nonnull id)data dataLength:(NSInteger)dataLength;

/**
 * 代理方法3. 与服务器连接失败时会调用(试图与不存在的服务器连接时也会调用)
 * 参数 socketManager 本管理者
 */
- (void)connectFailedToServerWithSocketManager:(nonnull WGSocketManager *)socketManager;

@end

@interface WGSocketManager : NSObject

/** 代理 */
@property (nonatomic, weak, nullable) id<WGSocketManagerProtocol> delegate;
/** 总共发送数据量(单位:M) */
@property (nonatomic, assign, readonly) double sentTotalData;
/** 总共接收数据量(单位:M) */
@property (nonatomic, assign, readonly) double gotTotalData;

/**
 * 获取 Socket管理者 单例
 * 返回 本管理者
 */
+ (nonnull __kindof WGSocketManager *)manager;

/**
 * 与服务器连接
 * 参数 IP 服务器地址
 * 参数 port 服务器端口
 */
- (void)connectToServerWithIP:(nonnull NSString *)IP andPort:(NSInteger)port;

/**
 * 断开与服务器的连接
 */
- (void)disconnectToServer;

/**
 * 向服务器发送数据
 * 参数 data 要发送的内容数据(NSArray / NSDictionary)
 */
- (void)sendToServerWithData:(nonnull id)data;

@end
