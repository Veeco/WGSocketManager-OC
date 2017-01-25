//
//  WGEncodeManager.m
//  Demo
//
//  Created by VS on 23/01/2017.
//  Copyright © 2017 JianWei. All rights reserved.
//

#import "WGEncodeManager.h"

@implementation WGEncodeManager

/**
 * 加密数据
 * 参数 data 要加密的数据
 * 参数 encodeType 加密类型 1 -> 异或加密
 * 返回 加密后的数据
 */
+ (nonnull NSData *)writeWithData:(nonnull NSData *)data encodeType:(Byte)encodeType encodeKey:(nonnull NSString *)encodeKey {
    
    // 如果是异或加密
    if (encodeType == 1) {
        
        // 把消息体转成字节数组
        Byte dataByteArr[data.length];
        [data getBytes:dataByteArr length:sizeof(dataByteArr)];
        
        // 把密钥转成字节数组
        Byte encodeKeyByteArr[encodeKey.length];
        [encodeKey getBytes:encodeKeyByteArr maxLength:sizeof(encodeKeyByteArr) usedLength:nil encoding:NSUTF8StringEncoding options:NSStringEncodingConversionExternalRepresentation range:NSMakeRange(0, sizeof(encodeKeyByteArr)) remainingRange:nil];
        
        // 开始加/解密
        Byte newDataByteArr[sizeof(dataByteArr)];
        for (NSInteger i = 0; i < sizeof(dataByteArr); i++) {
            
            Byte beforeByte = dataByteArr[i];
            Byte keyByte = encodeKeyByteArr[i % sizeof(encodeKeyByteArr)];
            Byte afterByte = beforeByte ^ keyByte;
            newDataByteArr[i] = afterByte;
        }
        // 把加密后的字节数组转回成消息体
        data = [NSData dataWithBytes:newDataByteArr length:sizeof(newDataByteArr)];
    }
    return data;
}

/**
 * 解密数据
 * 参数 data 要解密的数据
 * 参数 encodeType 加密类型 1 -> 异或加密
 * 返回 解密后的数据
 */
+ (nonnull NSData *)readWithData:(nonnull NSData *)data encodeType:(Byte)encodeType encodeKey:(nonnull NSString *)encodeKey {
    
    // 如果是异或加密
    if (encodeType == 1) {
        
        data = [self writeWithData:data encodeType:encodeType encodeKey:encodeKey];
    }
    return data;
}

@end
