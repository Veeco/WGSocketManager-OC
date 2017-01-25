#WGSocketManager-OC
iOS基于NSStream实现的Socket长连接小封装

#搭建环境
1. 将下载后的WGSocketManager文件夹拖进工程中
2. 导入libz库(用于压缩处理)
3. 导入头文件WGSocketManager.h即可

#基本使用
1.设置WGSocketManager单例对象的代理并遵守WGSocketManagerProtocol协议
```objc
[WGSocketManager manager].delegate = self;

@interface ViewController ()<WGSocketManagerProtocol>
```
2.直接调用WGSocketManager单例对象的连接方法即可与服务器实现长连接
```objc
NSString *host = @"192.168.2.161";
NSInteger port = 6666;
    
// 连接服务器
[[WGSocketManager manager] connectToServerWithIP:host andPort:port];
```
3.实现WGSocketManager的代理方法1. 与服务器连接成功时会调用
```objc
/**
 * 代理方法1. 与服务器连接成功时会调用
 * 参数 socketManager 本管理者
 */
- (void)connectSucceededToServerWithSocketManager:(nonnull WGSocketManager *)socketManager {

    self.contentTextView.text = [NSString stringWithFormat:@"%@\n连接成功", self.contentTextView.text];
}
```
4.此时可以调用WGSocketManager单例对象的发送方法向服务器发送数据(数据类型只能是`NSArray`或`NSDictionary`)
```objc
NSDictionary *dic = @{@"name":@"Veeco"};
    
// 发送数据
[[WGSocketManager manager] sendToServerWithData:dic];
```
5.实现WGSocketManager的代理方法2. 收到服务器发出的数据时会调用
```objc
/**
 * 代理方法2. 接收到服务器发送的数据时会调用
 * 参数 socketManager 本管理者
 * 参数 data 所收到的数据(NSArray / NSDictionary)
 * 参数 dataLength 所收到的数据长度(字节)
 */
- (void)socketManager:(nonnull WGSocketManager *)socketManager receiveData:(nonnull id)data dataLength:(NSInteger)dataLength {

    self.contentTextView.text = [NSString stringWithFormat:@"%@\n收到的数据字节长度为%zd\n%@\n", self.contentTextView.text, dataLength, data];
}
```
6.实现WGSocketManager的代理方法3. 与服务器连接失败时会调用(试图与不存在的服务器连接时也会调用)
```objc
/**
 * 代理方法3. 与服务器连接失败时会调用(试图与不存在的服务器连接时也会调用)
 * 参数 socketManager 本管理者
 */
- (void)connectFailedToServerWithSocketManager:(nonnull WGSocketManager *)socketManager {

    self.contentTextView.text = [NSString stringWithFormat:@"%@\n连接失败", self.contentTextView.text];
}
```
7.调用WGSocketManager单例对象的中断方法即可与服务器断开长连接
```objc
// 断开连接
[[WGSocketManager manager] disconnectToServer];
```
8.调用WGSocketManager单例对象的以下属性可以获取所消耗流量信息
```objc
/** 总共发送数据量(单位:M) */
@property (nonatomic, assign, readonly) double sentTotalData;
/** 总共接收数据量(单位:M) */
@property (nonatomic, assign, readonly) double gotTotalData;
```
#注意点
由于流的特性, 我们很难准确无误地获取服务器返回的数据(反之亦然), 特别是数据连发或网络不好的时候, 会出现多条数据连着一起收到的情况(当然也会有1条数据分成多段收到的情况), 所以我们必须在每一条数据前加上数据长度的信息, 这样接收方在接收到数据后就可以准确无误地截取并且解析了. 这里我是把每条数据的前7个字节用来放辅助信息的, 下面会作详细说明:
* 前4个字节合起来(即32位下的int)表示每条数据的字节长度 `注意这里的长度是把前7个字节也一并算上的`
* 第5个字节表示数据类型, 暂时只支持一种类型`1 -> JSON`
* 第6个字节表示加密类型(当然密钥也是需要的), `0 -> 无加密 1 -> 异或加密`
* 第7个字节表示压缩类型, `0 -> 无压缩 1 -> ZIP压缩`

>关于第5, 6, 7个字节的设置, 可以在WGSocketManager.m顶部的宏中修改
```objc
// 数据类型 1 -> JSON
#define kDataType 1
// 加密类型 0 -> 无加密 1 -> 异或加密
#define kEncodeType 0
// 压缩类型 0 -> 无压缩 1 -> ZIP压缩
#define kCompressType 0
// 密钥
#define kEncodeKey @"Veeco"
```

* 这里需要强调的是, 服务器也必须遵循这个'7个字节'原则才能进行正常交流(当时同事使用Java写的服务器, 用AIO)

##第一次做关于Socket的项目, 难免有幼嫩的地方, 请大家多多指点, 谢谢!
