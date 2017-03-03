//
//  WGSocketManager.m
//  Demo
//
//  Created by VS on 23/01/2017.
//  Copyright © 2017 JianWei. All rights reserved.
//

#import "WGSocketManager.h"
#import "WGDataManager.h"
#import "WGEncodeManager.h"
#import "WGCompressManager.h"

// 数据类型 1 -> JSON
#define kDataType 1
// 加密类型 0 -> 无加密 1 -> 异或加密
#define kEncodeType 0
// 压缩类型 0 -> 无压缩 1 -> ZIP压缩
#define kCompressType 0
// 密钥
#define kEncodeKey @"Veeco"

// 异步到串行子队列操作
#define kAsyncSSub(args) dispatch_async(self.sSubQueue, ^{args;});
// 同步回主队列操作
#define kSyncMain(args) dispatch_sync(dispatch_get_main_queue(), ^{args;});

@interface WGSocketManager () <NSStreamDelegate>

/** 输入流 */
@property (nonatomic, strong, nullable) NSInputStream *inputStream;
/** 输出流 */
@property (nonatomic, strong, nullable) NSOutputStream *outputStream;
/** 未读取数据 */
@property (nonatomic, strong, nonnull) NSMutableData *tempReadDataM;
/** 单次接收数据长度(服务器告知) */
@property (nonatomic, assign) NSInteger readDataLength;
/** 单次发送数据长度(告知服务器) */
@property (nonatomic, assign) NSInteger writeDataLength;
/** 未成功发出数据 */
@property (nonatomic, strong, nullable) NSData *tempWriteData;
/** 串行子队列 */
@property (nonatomic, strong) dispatch_queue_t sSubQueue;
/** 是否已经连接成功 */
@property (nonatomic, assign, getter=isConnected) BOOL connected;

@end

@implementation WGSocketManager

#pragma mark - <懒加载>

/**
 * 懒加载 串行子队列
 */
- (dispatch_queue_t)sSubQueue {
    
    if (!_sSubQueue) {
        
         self.sSubQueue = dispatch_queue_create("sSubQueue", DISPATCH_QUEUE_SERIAL);
    }
    return _sSubQueue;
}

/**
 * 懒加载 缓存已接收数据
 */
- (NSMutableData *)tempReadDataM {
    
    if (!_tempReadDataM) {
        
        self.tempReadDataM = [NSMutableData data];
    }
    return _tempReadDataM;
}

#pragma mark - <常规逻辑>

/**
 * 获取 Socket管理者 单例
 * 返回 本管理者
 */
+ (nonnull __kindof WGSocketManager *)manager {

    return [self allocWithZone:NULL];
}

- (id)copyWithZone:(struct _NSZone *)zone {
    
    return [[self class] allocWithZone:zone];
}

+ (id)allocWithZone:(struct _NSZone *)zone {
    
    static id _manager;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        _manager = [[super allocWithZone:NULL] init];
    });
    return _manager;
}

/**
 * 与服务器连接
 * 参数 IP 服务器地址
 * 参数 port 服务器端口
 */
- (void)connectToServerWithIP:(nonnull NSString *)IP andPort:(NSInteger)port {
    
    // 每次连接前先断开与服务器的连接
    [self disconnectToServer];
    
    // 异步到串行子队列操作
    kAsyncSSub(
               
               // 过滤
               if (IP.length == 0 || port == 0) return;
               
               // 定义C语言输入输出流
               CFReadStreamRef readStream;
               CFWriteStreamRef writeStream;
               
               // 创建连接
               CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)IP, (int)port, &readStream, &writeStream);
               
               // 把C语言的输入输出流转化成OC对象
               self.inputStream = (__bridge NSInputStream *)readStream;
               self.outputStream = (__bridge NSOutputStream *)writeStream;
               
               // 设置代理
               self.inputStream.delegate = self;
               self.outputStream.delegate = self;
               
               // 把输入输入流添加到主运行循环(不添加主运行循环, 代理有可能不工作)
               [self.inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
               [self.outputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
               
               // 打开输入输出流
               [self.inputStream open];
               [self.outputStream open];
               )
}

/**
 * 断开与服务器的连接
 */
- (void)disconnectToServer {
    
    // 异步到串行子队列操作
    kAsyncSSub(
               
               // 过滤
               if (!self.isConnected) return;
               
               // 清空缓存数据
               self.tempReadDataM = [NSMutableData data];
               self.tempWriteData = [NSData data];
               self.readDataLength = 0;
               
               // 关闭输入输出流
               [self.inputStream close];
               [self.outputStream close];
               
               // 从主运行循环移除
               [self.inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
               [self.outputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
               
               // 重置状态
               self.connected = NO;
               )
}

/**
 * 向服务器发送数据
 * 参数 data 要发送的内容数据(NSArray / NSDictionary)
 */
- (void)sendToServerWithData:(nonnull id)data {

    // 异步到串行子队列操作
    kAsyncSSub(
    
              // 过滤
              if (!self.isConnected || data == nil) return;
    
              // 获取要发送的二进制数据
              NSData *sendData = [self getSendDataFromOriginData:data];
              
              // 发送数据
              [self sendDataToServerWithData:sendData];
              )
}

#pragma mark - <转换相关处理>

/**
 * int类型 -> Byte类型数组
 * 参数 intValue int类型
 * 参数 ByteArr 转换后的Byte类型数组容器
 */
- (void)convertToByteFromIntValue:(NSInteger)intValue andByteArr:(nonnull Byte *)ByteArr {
    
    ByteArr[0] = (intValue >> 24) & 255;
    ByteArr[1] = (intValue >> 16) & 255;
    ByteArr[2] = (intValue >> 8) & 255;
    ByteArr[3] = intValue & 255;
}

/**
 * Byte类型数组 -> int类型
 * 参数 byteArr Byte类型数组
 * 返回 int类型
 */
- (NSInteger)convertToIntFromByteArr:(nonnull Byte *)byteArr {
    
    Byte byte1 = byteArr[0];
    Byte byte2 = byteArr[1];
    Byte byte3 = byteArr[2];
    Byte byte4 = byteArr[3];
    
    return byte1 << 8 | byte2 << 8 | byte3 << 8 | byte4;
}

#pragma mark - <发送相关处理>

/**
 * 根据要发送的内容数据获取要发送的二进制数据
 * 参数 data 要发送的内容数据(NSArray / NSDictionary)
 * 返回 要发送的二进制数据
 */
- (nonnull NSData *)getSendDataFromOriginData:(nonnull id)originData {
    
    // 获取要发送的主体二进制数据
    NSData *bodyData = [self getDataWithDataType:kDataType encodeType:kEncodeType compressType:kCompressType data:originData];
    
    // 把要发送的主体二进制数据长度转成字节数组
    Byte ByteArr[4];
    [self convertToByteFromIntValue:bodyData.length + 7 andByteArr:ByteArr];
    
    // 以字节数组形式设置头部数据
    Byte headArr[] = {ByteArr[0], ByteArr[1], ByteArr[2], ByteArr[3], kDataType, kEncodeType, kCompressType};
    
    // 转换成头部数据
    NSMutableData *headDataM = [NSMutableData dataWithBytes:headArr length:sizeof(headArr)];
    
    // 拼接数据
    [headDataM appendData:bodyData];
    
    return [NSData dataWithData:headDataM];
}

/**
 * 根据一系列参数获取要发送的主体二进制数据
 * 参数 dataType 数据类型
 * 参数 encodeType 加密类型
 * 参数 compressType 压缩类型
 * 参数 data 要发送的内容数据(NSArray / NSDictionary)
 * 返回 要发送的主体二进制数据
 */
- (nonnull NSData *)getDataWithDataType:(Byte)dataType encodeType:(Byte)encodeType compressType:(Byte)compressType data:(nonnull id)data {
    
    NSData *newData;
    
    // 1. 转换格式
    newData = [WGDataManager writeWithData:data andDataType:dataType];
    
    // 2. 加密处理
    newData = [WGEncodeManager writeWithData:newData encodeType:encodeType encodeKey:kEncodeKey];
    
    // 3. 压缩处理
    newData = [WGCompressManager writeWithData:newData andCompressType:compressType];
    
    return newData;
}

/**
 * 向服务器发送数据
 * 参数 data 要发送的二进制数据
 */
- (void)sendDataToServerWithData:(NSData *)data {
    
    // 如果要发送的数据长度为0 直接return
    if (data.length == 0) return;
    
    // 记录要发送的数据长度
    self.writeDataLength = data.length;
    
    // 发送数据 并获取实际发送数据字节长度
    NSInteger writedDataLength = [_outputStream write:data.bytes maxLength:data.length];
    
    // 增加判断以防异常崩溃
    if (writedDataLength == -1) return;
    
    // 如果未能完全发出 缓存未发送数据
    if (writedDataLength != data.length) {
        
        self.tempWriteData = [data subdataWithRange:NSMakeRange(writedDataLength, data.length - writedDataLength)];
    }
    // 否则清空缓存未发送数据
    else {
        
        self.tempWriteData = nil;
    }
}

#pragma mark - <接收相关处理>

/**
 * 读取服务器发出的数据
 */
- (void)readData {

    // 建立一个缓冲区 可以放1024个字节
    Byte bufArr[1024];
    
    // 接收数据 并获取实际获取数据字节长度
    NSInteger readDataLength = [self.inputStream read:bufArr maxLength:sizeof(bufArr)];

    // 增加判断以防异常崩溃
    if (readDataLength == -1) return;
    
    // 从缓冲区中抽出数据并叠加
    [self.tempReadDataM appendData:[NSData dataWithBytes:bufArr length:readDataLength]];
    
    // 分析数据
    [self analyseData];
}

/**
 * 分析数据
 */
- (void)analyseData {
    
    // 抽取叠加数据后字节长度小于4则返回
    if (self.tempReadDataM.length < 4) return;
    
    // 1. 获取数据真实字节长度
    if (self.readDataLength == 0) {
        
        Byte byteArr[4];
        [self.tempReadDataM getBytes:byteArr length:4];
        self.readDataLength = [self convertToIntFromByteArr:byteArr];
    }
    // 如果还没接收完全或者被告知长度不大于7则返回(注意:不能把 < 换成 != 因为有可能会把下一条数据也读进来)
    if (self.tempReadDataM.length < self.readDataLength || self.readDataLength <= 7) return;

    // 解析辅助信息
    Byte assistantArr[3];
    [self.tempReadDataM getBytes:assistantArr range:NSMakeRange(4, sizeof(assistantArr))];
    
    // 2. 获取数据类型
    Byte dataType = assistantArr[0];
    
    // 3. 获取加密方式
    Byte encodeType = assistantArr[1];
    
    // 4. 获取压缩方式
    Byte compressType = assistantArr[2];
    
    // 5. 解析正式数据
    NSData *regularData = [self.tempReadDataM subdataWithRange:NSMakeRange(7, self.readDataLength - 7)];
    [self disposeDataWithDataType:dataType encodeType:encodeType compressType:compressType bodyData:regularData];
    
    // 6. 处理有可能接收到的下一条数据
    if (self.tempReadDataM.length > self.readDataLength) {
        
        // 缓存下一条数据
        NSData *tempData = [self.tempReadDataM subdataWithRange:NSMakeRange(self.readDataLength, self.tempReadDataM.length - self.readDataLength)];
        self.tempReadDataM = [NSMutableData dataWithData:tempData];
        
        self.readDataLength = 0;
        
        // 递归分析数据
        [self analyseData];
    }
    // 清空缓存数据
    else {
    
        self.tempReadDataM = [NSMutableData data];
        self.readDataLength = 0;
    }
}

/**
 * 处理收到的数据
 * 参数 dataType 数据类型
 * 参数 encodeType 加密方式
 * 参数 compressType 压缩方式
 * 参数 bodyData 接收到的主体数据
 */
- (void)disposeDataWithDataType:(Byte)dataType encodeType:(Byte)encodeType compressType:(Byte)compressType bodyData:(nonnull NSData *)bodyData {
    
    // 1. 解压
    bodyData = [WGCompressManager readWithData:bodyData andCompressType:compressType];
    
    // 2. 解密
    bodyData = [WGEncodeManager readWithData:bodyData encodeType:encodeType encodeKey:kEncodeKey];
    
    // 3. 转换格式
    id result = [WGDataManager readWithDada:bodyData andDataType:dataType];

    // 更新接收流量统计
    _gotTotalData += (double)self.readDataLength / 1024 / 1024;

    // 同步回主队列操作
    kSyncMain(
               // 代理方法2. 接收到服务器发送的数据时会调用
               if ([self.delegate respondsToSelector:@selector(socketManager:receiveData:dataLength:)]) {
                   
                   [self.delegate socketManager:self receiveData:result dataLength:self.readDataLength];
               }
               )
}

#pragma mark - <NSStreamDelegate>

/**
 * 代理方法:监听与服务器的连接状态
 * 参数 aStream 输入输出流
 * 参数 eventCode 状态参数
 */
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode {

    /*
     NSStreamEventOpenCompleted = 1UL << 0,      输入输出流打开完成
     NSStreamEventHasByteAvailable = 1UL << 1,   有字节可读
     NSStreamEventHasSpaceAvailable = 1UL << 2,  可以发送字节
     NSStreamEventErrorOccurred = 1UL << 3,      连接出现错误
     NSStreamEventEndEncountered = 1UL << 4      连接结束
     */
    
    switch(eventCode) {
            
        // 1. 输入输出流打开完成
        case NSStreamEventOpenCompleted:
            
            break;
            
        // 2. 有字节可读
        case NSStreamEventHasBytesAvailable:

            // 异步到串行子队列中读取服务器发出的数据
            {
                kAsyncSSub([self readData])
            }
            break;
        
        // 3. 可以发送字节
        case NSStreamEventHasSpaceAvailable:
            
            if (!self.isConnected) {
                
                // 设置连接状态
                self.connected = YES;

                // 代理方法1. 与服务器连接成功时会调用
                if ([self.delegate respondsToSelector:@selector(connectSucceededToServerWithSocketManager:)]) {
                    
                    [self.delegate connectSucceededToServerWithSocketManager:self];
                }
            }
            // 异步到串行子队列中补发未发送数据
            if (self.tempWriteData) {
            
                kAsyncSSub([self sendDataToServerWithData:self.tempWriteData])
            }
            // 更新发送流量统计
            else {
            
                _sentTotalData += (double)self.writeDataLength / 1024 / 1024;
                self.writeDataLength = 0;
            }
            break;
        
        // 4. 连接出现错误
        case NSStreamEventErrorOccurred:
            
            // 断开连接
            [self disconnectToServer];
            
            // 调用代理方法3. 与服务器连接失败时会调用(试图与不存在的服务器连接时也会调用)
            if ([self.delegate respondsToSelector:@selector(connectFailedToServerWithSocketManager:)]) {
                
                [self.delegate connectFailedToServerWithSocketManager:self];
            }
            break;
        
        // 5. 连接结束
        case NSStreamEventEndEncountered:
            
            // 断开连接
            [self disconnectToServer];
            
            // 调用代理方法3. 与服务器连接失败时会调用(试图与不存在的服务器连接时也会调用)
            if ([self.delegate respondsToSelector:@selector(connectFailedToServerWithSocketManager:)]) {
                
                [self.delegate connectFailedToServerWithSocketManager:self];
            }
            break;
            
        default:
            
            break;
    }
}

@end
