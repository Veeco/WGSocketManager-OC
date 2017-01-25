//
//  WGCompressManager.m
//  Demo
//
//  Created by VS on 23/01/2017.
//  Copyright © 2017 JianWei. All rights reserved.
//

#import "WGCompressManager.h"
#import <zlib.h>

@implementation WGCompressManager

/**
 * 压缩数据
 * 参数 data 要压缩的数据
 * 参数 compressType 压缩类型 1 -> gzip压缩
 * 返回 压缩后的数据
 */
+ (nonnull NSData *)writeWithData:(nonnull NSData *)data andCompressType:(Byte)compressType {
    
    // 如果是ZIP压缩
    if (compressType == 1) {
        
        if ([data length] == 0) return data;
        
        z_stream strm;
        
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        strm.opaque = Z_NULL;
        strm.total_out = 0;
        strm.next_in=(Bytef *)[data bytes];
        strm.avail_in = (uInt)[data length];
        
        // Compresssion Levels:
        //   Z_NO_COMPRESSION
        //   Z_BEST_SPEED
        //   Z_BEST_COMPRESSION
        //   Z_DEFAULT_COMPRESSION
        
        if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
        
        NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
        
        do {
            
            if (strm.total_out >= [compressed length])
                [compressed increaseLengthBy: 16384];
            
            strm.next_out = [compressed mutableBytes] + strm.total_out;
            strm.avail_out = (uInt)([compressed length] - strm.total_out);
            
            deflate(&strm, Z_FINISH);
            
        } while (strm.avail_out == 0);
        
        deflateEnd(&strm);
        
        [compressed setLength: strm.total_out];
        data = [NSData dataWithData:compressed];
    }
    return data;
}

/**
 * 解压数据
 * 参数 data 要解压的数据
 * 参数 compressType 压缩类型 1 -> gzip压缩
 * 返回 解压后的数据
 */
+ (nonnull NSData *)readWithData:(nonnull NSData *)data andCompressType:(Byte)compressType {

    // 如果是ZIP压缩
    if (compressType == 1) {
        
        if ([data length] == 0) return data;
        
        unsigned long full_length = [data length];
        unsigned long  half_length = [data length] / 2;
        
        NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
        BOOL done = NO;
        int status;
        
        z_stream strm;
        strm.next_in = (Bytef *)[data bytes];
        strm.avail_in = (uInt)[data length];
        strm.total_out = 0;
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        
        if (inflateInit2(&strm, (15+32)) != Z_OK)
            return nil;
        
        while (!done)
        {
            // Make sure we have enough room and reset the lengths.
            if (strm.total_out >= [decompressed length])
                [decompressed increaseLengthBy: half_length];
            strm.next_out = [decompressed mutableBytes] + strm.total_out;
            strm.avail_out = (uInt)([decompressed length] - strm.total_out);
            
            // Inflate another chunk.
            status = inflate (&strm, Z_SYNC_FLUSH);
            if (status == Z_STREAM_END)
                done = YES;
            else if (status != Z_OK)
                break;
        }
        if (inflateEnd (&strm) != Z_OK)
            return nil;
        
        // Set real length.
        if (done)
        {
            [decompressed setLength: strm.total_out];
            data = [NSData dataWithData: decompressed];
        }
        else return nil;
    }
    return data;
}

@end
