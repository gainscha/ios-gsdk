//
//  TscCommand.m
//  GSDK
//
//  Created by max on 2020/11/02.
//  Copyright © 2020 Handset. All rights reserved.
//

#import "TscCommand.h"
#import "GPUtils.h"
#import <zlib.h>
@interface TscCommand()
@property(nonatomic, assign) NSStringEncoding encoding;
@property(nonatomic, strong) NSMutableData *mCommandData;
@end

@implementation TscCommand

-(NSStringEncoding)encoding{
    if (!_encoding) {
        _encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    }
    return _encoding;
}

-(id) init{
    
    self = [super init];
    if (self) {
        self.mCommandData = [NSMutableData data];
    }
    
    return self;
}

/**
 * 方法说明：设置标签尺寸的宽和高
 * @param width  标签宽度
 * @param height 标签高度
 */
-(void) addSize:(int) width :(int) height {
    [self addStrToCommand: [NSString stringWithFormat:@"SIZE %d mm,%d mm\r\n", width, height]];
}

/**
 * 方法说明：设置标签间隙尺寸 单位mm
 * @param m    间隙长度
 * @param n    间隙偏移
 */
-(void) addGapWithM:(int) m withN:(int) n {
    [self addStrToCommand:[NSString stringWithFormat:@"GAP %d mm,%d mm\r\n", m, n]];
}

/**
 * 方法说明：设置标签原点坐标
 * @param x  横坐标
 * @param y  纵坐标
 */
-(void) addReference:(int) x :(int)y {
    [self addStrToCommand:[NSString stringWithFormat:@"REFERENCE %d,%d\r\n", x, y]];
}

/**
 * 方法说明：设置打印速度
 * @param speed  打印速度
 */
-(void) addSpeed:(int) speed {
    [self addStrToCommand: [NSString stringWithFormat:@"SPEED %d\r\n", speed]];
}

/**
 * 方法说明：设置打印速度，保留小数点后1位
 * @param speed  打印速度
*/
-(void) addSpeedF:(float) speed {
    [self addStrToCommand: [NSString stringWithFormat:@"SPEED %.1f\r\n", speed]];
}

/**
 * 方法说明：设置打印浓度
 * @param density  浓度
 */
-(void) addDensity:(int) density {
    [self addStrToCommand: [NSString stringWithFormat:@"DENSITY %d\r\n", density]];
}

/**
 * 方法说明：设置打印方向
 * @param direction  方向
 */
-(void) addDirection:(int) direction {
    [self addStrToCommand: [NSString stringWithFormat:@"DIRECTION %d\r\n", direction]];
}

/**
 * 方法说明：清除打印缓冲区
 */
-(void) addCls {
    
    [self addStrToCommand: [NSString stringWithFormat:@"CLS\r\n"]];
}

/**
 * 方法说明:在标签上绘制文字
 * @param x 横坐标
 * @param y 纵坐标
 * @param font  字体类型
 * @param rotation  旋转角度
 * @param xScal  横向放大
 * @param yScal  纵向放大
 * @param text   文字字符串
 */
-(void)addTextwithX:(int)x withY:(int)y withFont:(NSString*)font withRotation:(int)rotation withXscal:(int)xScal withYscal:(int)yScal withText:(NSString*) text{
    NSString *mark = @"\"";
    NSMutableString * str = [[NSMutableString alloc] init];
    [str appendString:[NSString stringWithFormat:@"TEXT %d,%d,",x,y]];
    [str appendString: mark];
    [str appendString:font];
    [str appendString: mark];
    [str appendString:[NSString stringWithFormat:@",%d,%d,%d,", rotation, xScal, yScal]];
    [str appendString: mark];
    [str appendString: text];
    [str appendString: mark];
    [str appendString: @"\r\n"];
    [self addStrToCommand: str];
}

-(void)addNewBitmapwithX:(int)x withY:(int)y withMode:(int)mode withWidth:(int)width withImage:(UIImage *)image {
    
    if (image != nil) {
        // 如果不使用压缩模式
        if(mode == 0) {
            
            UIImage *newImage = [GPUtils imageWithScaleImage:image andScaleWidth:width];
            newImage = [GPUtils grayImage:newImage];
            NSLog(@"newImage.size===%@",NSStringFromCGSize(newImage.size));
            NSData *data = [GPUtils printTscData:newImage andMode:mode];
            int wid = (int)newImage.size.width / 8;
            NSString *str = [NSString stringWithFormat:@"BITMAP %d,%d,%d,%d,%d,", x, y, wid, (int)newImage.size.height, mode];
            [self.mCommandData appendData:[str dataUsingEncoding:self.encoding]];
            [self.mCommandData appendData:data];
            return;
        }
        
        
        if (mode == 3) {
            int ZLIB_BITMAP_DOT_MAX = 18 * 1024 * 8;
            int widthK = width;
            if (width%8 != 0) {
                widthK = (width/8)*8+8;
            }
            
            int height =image.size.height*widthK/image.size.width;
            image = [GPUtils binaryzation:image];
            UIImage *rszBitmap = [GPUtils resizeImage:image withWidth:widthK withHeight:height];
            int maxHeight = ZLIB_BITMAP_DOT_MAX / widthK;
            NSMutableArray *temp = [self cropImageFromImageArrry:rszBitmap inPhotoSize:rszBitmap.size withHeight:maxHeight];
            __block int yy = y;
            [temp enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                UIImage *b = obj;
                // b = [GPUtils grayImage:b];
                NSData *data = [GPUtils printTscData:b andMode:mode];
                NSString *str = [NSString stringWithFormat:@"BITMAP %d,%d,%d,%d,%d,", x, yy, widthK/8, (int)b.size.height, mode];
                yy+=b.size.height;
                NSData *temp = [self zlibCompression:data];
                str = [NSString stringWithFormat:@"%@%ld,",str,(unsigned long)[temp length]];
                NSLog(@"%@",str);
                [self.mCommandData appendData:[str dataUsingEncoding:self.encoding]];
                [self.mCommandData appendData:temp];
                
            }];
        }
        
    }
    
}

-(void)addBitmapwithX:(int)x withY:(int)y withWidth:(int)width withHeight:(int)height withMode:(int) mode withData:(NSData*) data {
    
    NSString *str = [NSString stringWithFormat:@"BITMAP %d,%d,%d,%d,%d,", x, y, width, height, mode];
    
    NSMutableData *tmpMData = [[NSMutableData alloc] init];
    [tmpMData appendData:[str dataUsingEncoding: self.encoding]];
    [tmpMData appendData:data];
    
    
    int startPos = 0;
    NSMutableData *oriData=[[NSMutableData alloc] initWithData:tmpMData];
    NSInteger length = [oriData length];
    
    const int maxByte = 150;
    while (startPos <= length) {
        if (length - startPos >=  maxByte) {
            NSData *tmpData = [oriData subdataWithRange:NSMakeRange(startPos, maxByte)];
            [self addNSDataToCommand:tmpData];
            startPos += maxByte;
        } else {
            NSData *tmpData = [oriData subdataWithRange:NSMakeRange(startPos, length - startPos)];
            [self addNSDataToCommand:tmpData];
            break;
        }
    }
}

/**
 * 方法说明：打印图片
 * 参 数 说 明：
 * x 点阵影像的水平启始位置
 * y 点阵影像的垂直启始位置
 * mode 影像绘制模式
 *       0 OVERWRITE
 *       1 OR
 *       2 XOR
 * width 图片宽度
 * image 需要打印的图片
 */
-(void)addBitmapwithX:(int)x withY:(int)y withMode:(int)mode withWidth:(int)width withImage:(UIImage *)image {
    if (image != nil) {
        UIImage *newImage = [GPUtils imageWithScaleImage:image andScaleWidth:width];
        newImage = [GPUtils grayImage:newImage];
        NSData *data = [GPUtils printTscData:newImage andMode:mode];
        int wid = (int)newImage.size.width / 8;
        NSString *str = [NSString stringWithFormat:@"BITMAP %d,%d,%d,%d,%d,", x, y, wid, (int)newImage.size.height, mode];
        if (mode == 3) {
            //压缩图片数据
            data = [self zlibCompression:data];
            str = [NSString stringWithFormat:@"%@%ld,",str,(unsigned long)[data length]];
        }
        [self.mCommandData appendData:[str dataUsingEncoding:self.encoding]];
        [self.mCommandData appendData:data];
    }
    
}

/**
 *方法说明：压缩算法
 *参数说明：data数据源
 */
-(NSData *)zlibCompression:(NSData *)data {
    if ([data length] == 0) {
        return data;
    }
    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    strm.total_out = 0;
    strm.next_in = (Bytef *)[data bytes];
    strm.avail_in = (uint)[data length];
    if (deflateInit(&strm, Z_DEFAULT_COMPRESSION) != Z_OK) {
        return nil;
    }
    NSMutableData *compressed = [NSMutableData dataWithLength:16384];
    do {
        if (strm.total_out >= [compressed length]) {
            [compressed increaseLengthBy:16384];
        }
        strm.next_out = [compressed mutableBytes] + strm.total_out;
        strm.avail_out = (uint)([compressed length] - strm.total_out);
        deflate(&strm, Z_FINISH);
    } while (strm.avail_out == 0);
    deflateEnd(&strm);
    [compressed setLength:strm.total_out];
    return [NSData dataWithData:compressed];
}

/**
 * 方法说明：切割待打印的图像并保存到数组
 * @param image 图片源文件
 * @param imgSize 图片size大小
 * @param photoHeight 需要切割的图片高度
 * @return NSMutableArray
 */
- (NSMutableArray *)cropImageFromImageArrry:(UIImage *)image inPhotoSize:(CGSize)imgSize withHeight:(int)photoHeight{
    NSMutableArray *arr = [NSMutableArray array];
    int fixelH = imgSize.height;
    int flag = floor(fixelH /photoHeight);
    int yu = fixelH%photoHeight;
    // 保存固定高度切割的图片
    for (int i = 0; i < flag; i ++) {
        CGRect dianRect = CGRectMake(0, photoHeight*i, imgSize.width, photoHeight);
        CGImageRef sourceImageRef = [image CGImage];
        CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, dianRect);
        UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:1 orientation:UIImageOrientationUp];
        [arr addObject:newImage];
    }
    
    // 剩余部分图像保存
    if (yu != 0) {
        CGRect yuRect = CGRectMake(0, fixelH - yu, imgSize.width, yu);
        CGImageRef sourceImageRef = [image CGImage];
        CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, yuRect);
        UIImage *newImage = [UIImage imageWithCGImage:newImageRef scale:1 orientation:UIImageOrientationUp];
        [arr addObject:newImage];
    }
    return arr;
}

-(void)addBitmapwithX:(int)x withY:(int)y withMode:(int)mode withImage:(UIImage *)image {
    if (image != nil) {
        image = [GPUtils imageWithScaleImage:image andScaleWidth:(int)image.size.width];
        int wid = image.size.width / 8;
        NSString *str = [NSString stringWithFormat:@"BITMAP %d,%d,%d,%d,%d,", x, y, wid, (int)image.size.height, mode];
        [self.mCommandData appendData:[str dataUsingEncoding:self.encoding]];
        [self.mCommandData appendData:[GPUtils printTscData:image]];
    }
}

/**
 * 方法说明:在标签上绘制一维条码
 * @param x 横坐标
 * @param y 纵坐标
 * @param barcodeType 条码类型
 * @param height  条码高度，默认为40
 * @param readable  是否可识别，0:  人眼不可识，1:   人眼可识
 * @param rotation  旋转角度，条形码旋转角度，顺时钟方向，0不旋转，90顺时钟方向旋转90度，180顺时钟方向旋转180度，270顺时钟方向旋转270度
 * @param narrow 默认值2，窄 bar  宽度，以点(dot)表示
 * @param wide 默认值4，宽 bar  宽度，以点(dot)表示
 * @param content   条码内容
 */
-(void) add1DBarcode:(int)x :(int)y :(NSString*)barcodeType :(int)height :(int)readable :(int)rotation :(int)narrow :(int)wide :(NSString*)content {
    
    NSString *adjustType = barcodeType;
    if ([adjustType isEqualToString:@"ITF"]) {
        adjustType = @"ITF14";
    } else if([adjustType isEqualToString:@"CODE39"]) {
        adjustType = @"39";
    } else if([adjustType isEqualToString:@"CODE128"]) {
        adjustType = @"128";
    }
    
    NSString *mark = @"\"";
    NSMutableString * str = [[NSMutableString alloc] init];
    [str appendString:[NSString stringWithFormat:@"BARCODE %d,%d,",x,y]];
    [str appendString: mark];
    [str appendString:adjustType];
    [str appendString: mark];
    [str appendString:[NSString stringWithFormat:@",%d,%d,%d,%d,%d,", height, readable, rotation, narrow, wide]];
    [str appendString: mark];
    [str appendString: content];
    [str appendString: mark];
    [str appendString: @"\r\n"];
    [self addStrToCommand: str];
}

/**
 * 方法说明:在标签上绘制QRCode二维码
 * @param x 横坐标
 * @param y 纵坐标
 * @param ecclever 选择QRCODE纠错等级,默认为L，L为7%,M为15%,Q为25%,H为30%
 * @param cellWidth  二维码宽度1~10，默认为4
 * @param mode  默认为A，A为Auto,M为Manual
 * @param rotation  旋转角度，默认为0，QRCode二维旋转角度，顺时钟方向，0不旋转，90顺时钟方向旋转90度，180顺时钟方向旋转180度，270顺时钟方向旋转270度
 * @param content   条码内容
 * QRCODE X,Y ,ECC LEVER ,cell width,mode,rotation, "data string"
 * QRCODE 20,24,L,4,A,0,"佳博集团网站www.Gprinter.com.cn"
 */
-(void) addQRCode:(int)x :(int)y :(NSString*)ecclever :(int)cellWidth :(NSString*)mode :(int)rotation :(NSString*)content {
    NSString *mark = @"\"";
    NSMutableString * str = [[NSMutableString alloc] init];
    [str appendString:[NSString stringWithFormat:@"QRCODE %d,%d,",x,y]];
    [str appendString: ecclever];
    [str appendString:[NSString stringWithFormat:@",%d,", cellWidth]];
    [str appendString: mode];
    [str appendString:[NSString stringWithFormat:@",%d,", rotation]];
    [str appendString: mark];
    [str appendString: content];
    [str appendString: mark];
    [str appendString: @"\r\n"];
    [self addStrToCommand: str];
}

/**
 * 方法说明：执行打印
 * @param m 指定打印的份数（set）1≤m≤65535
 * @param n 每张标签需重复打印的张数 1≤n≤65535
 */
-(void) addPrint:(int) m :(int) n {
    [self addStrToCommand: [NSString stringWithFormat:@"PRINT %d,%d\r\n", m,n]];
}

/**
 * 方法说明:获得打印命令
 */
-(NSData*) getCommand {
    return self.mCommandData;
}

/**
 * 方法说明：将字符串转成十六进制码
 * @param  str  命令字符串
 */
-(void) addStrToCommand:(NSString *)str {
    if (self.mCommandData) {
        [self.mCommandData appendData:[str dataUsingEncoding:self.encoding]];
    }
}

-(void) addNSDataToCommand:(NSData*) data {
    [self.mCommandData appendData:data];
}

/**
 * 方法说明：发送一些TSC的固定命令，在cls命令之前发送
 */
-(void) addComonCommand {
    [self addStrToCommand: [NSString stringWithFormat:@"SET HEAD ON\r\n"]];
    [self addStrToCommand: [NSString stringWithFormat:@"SET PRINTKEY OFF\r\n"]];
    [self addStrToCommand: [NSString stringWithFormat:@"SET KEY1 ON\r\n"]];
    [self addStrToCommand: [NSString stringWithFormat:@"SET KEY2 ON\r\n"]];
    [self addStrToCommand: [NSString stringWithFormat:@"SHIFT %d\r\n",0]];
}

/**
 * 方法说明:打印自检页，打印测试页
 */
-(void) addSelfTest {
    [self addStrToCommand: [NSString stringWithFormat:@"SELFTEST\r\n"]];
}

/**
 * 方法说明 :查询打印机型号
 */
-(void) queryPrinterType {
    [self addStrToCommand: [NSString stringWithFormat:@"~!T\r\n"]];
}

/**
 * 方法说明:设定黑标高度及定义标签印完后标签额外送出的长度
 * @param m 黑标高度（0≤m≤1(inch)，0≤m≤25.4(mm)）
 * @param n 额外送出纸张长度 n≤标签纸纸张长度(inch或mm)
 */
-(void)addBLine:(int)m :(int)n{
    [self addStrToCommand:[NSString stringWithFormat:@"BLINE %d,%d\r\n",m,n]];
}

/**
 * New：方法说明:设定黑标高度及定义标签印完后标签额外送出的长度
 * @param m 黑标高度（0≤m≤1(inch)，0≤m≤25.4(mm)）
 * @param n 额外送出纸张长度 n≤标签纸纸张长度(inch或mm)
*/
-(void)addNewBLine:(int)m :(int)n{
    [self addStrToCommand:[NSString stringWithFormat:@"BLINE %d mm,%d mm\r\n", m, n]];
}


/**
 * 方法说明:设置打印机剥离模式
 * @param peel ON/OFF  是否开启
 */
-(void) addPeel:(NSString *) peel {
    NSMutableString * str = [[NSMutableString alloc] init];
    [str appendString: @"SET PEEL "];
    [str appendString: peel];
    [str appendString: @"\r\n"];
    [self addStrToCommand: str];
}

/**
 * 方法说明:设置打印机撕离模式
 * @param tear ON/OFF 是否开启
 */
-(void) addTear:(NSString *) tear {
    NSMutableString * str = [[NSMutableString alloc] init];
    [str appendString: @"SET TEAR "];
    [str appendString: tear];
    [str appendString: @"\r\n"];
    [self addStrToCommand: str];
}

/**
 * 方法说明:设置切刀是否有效
 * @param cutter 是否开启 OFF/pieces (0<=pieces<=127)设定几张标签切一次
 */
-(void)addCutter:(NSString *)cutter {
    NSMutableString * str = [[NSMutableString alloc] init];
    [str appendString: @"SET CUTTER "];
    [str appendString: cutter];
    [str appendString: @"\r\n"];
    [self addStrToCommand: str];
}

/**
 * 方法说明:设置切刀半切是否有效
 * @param cutter  是否开启
 */
-(void) addPartialCutter:(NSString *) cutter {
    NSMutableString * str = [[NSMutableString alloc] init];
    [str appendString: @"SET CUTTER "];
    [str appendString: cutter];
    [str appendString: @"\r\n"];
    [self addStrToCommand: str];
}

/**
 * 方法说明：设置蜂鸣器
 * @param level 频率
 * @param interval  时间ms
 */
-(void) addSound:(int)level :(int)interval{
    [self addStrToCommand: [NSString stringWithFormat:@"SOUND %d,%d\r\n", level,interval]];
}

/**
 * 方法说明：打开钱箱命令,CASHDRAWER m,t1,t2
 * @param m  钱箱号 m      0，48  钱箱插座的引脚2        1，49  钱箱插座的引脚5
 * @param t1   高电平时间0 ≤ t1 ≤ 255输出由t1和t2设定的钱箱开启脉冲到由m指定的引脚
 * @param t2   低电平时间0 ≤ t2 ≤ 255输出由t1和t2设定的钱箱开启脉冲到由m指定的引脚
 */
-(void) addCashdrawer:(int) m :(int) t1 :(int) t2 {
    [self addStrToCommand: [NSString stringWithFormat:@"CASHDRAWER %d,%d,%d\r\n", m,t1,t2]];
}

/**
 * 方法说明:在标签上绘制黑块，画线
 * @param x 起始横坐标
 * @param y 起始纵坐标
 * @param width 线宽，以点(dot)表示
 * @param height 线高，以点(dot)表示
 */
-(void) addBar:(int) x :(int) y :(int) width :(int) height {
    [self addStrToCommand:[NSString stringWithFormat:@"BAR %d,%d,%d,%d\r\n", x,y,width,height]];
}

/**
 * 方法说明:在标签上绘制矩形
 * @param xStart 起始横坐标
 * @param yStart 起始纵坐标
 * @param xEnd 终点横坐标
 * @param yEnd 终点纵坐标
 * @param lineThickness 矩形框线厚度或宽度，以点(dot)表示
 */
-(void) addBox:(int)xStart :(int)yStart :(int)xEnd :(int)yEnd :(int)lineThickness {
    [self addStrToCommand: [NSString stringWithFormat:@"BOX %d,%d,%d,%d,%d\r\n", xStart,yStart,xEnd,yEnd,lineThickness]];
}

/**
 * 方法说明:查询打印机状态
 * 询问打印机状态指令为立即响应型指令，该指令控制字符是以<ESC> (ASCII 27=0x1B, escape字符)为控制字符.!(ASCII 33=0x21),?(ASCII 63=0x3F)
 * 即使打印机在错误状态中仍能透过 RS-232  回传一个 byte  资料来表示打印机状态，若回传值为 0  则表示打印
 * 机处于正常的状态
 */
-(void) queryPrinterStatus {
    unsigned char postfix[] = {0x1B, 0x21, 0x3F};
    [self.mCommandData  appendData: [NSData dataWithBytes:postfix length:sizeof(postfix)]];
}

/**
 * 方法说明:将指定的区域反向打印（黑色变成白色，白色变成黑色）
 * @param xStart 起始横坐标
 * @param yStart 起始横坐标
 * @param width X坐标方向宽度，dot为单位
 * @param height Y坐标方向高度，dot为单位
 */
-(void) addReverse:(int) xStart :(int) yStart :(int) width :(int) height {
    [self addStrToCommand: [NSString stringWithFormat:@"REVERSE %d,%d,%d,%d\r\n", xStart,yStart,width,height]];
}

/**
 *  方法说明: 打印机打印完成时，自动返回状态。可用于实现连续打印功能
 *  @param response 自动返回状态  <a>@see Response</a>
 *                  OFF     关闭自动返回状态功能
 *                  ON      开启自动返回状态功能
 *                  BATCH   全部打印完成后返回状态
 */
-(void)addQueryPrinterStatus:(Response)response {
    NSString *str;
    switch (response) {
        case 1:
            str = @"ON";
            break;
        case 2:
            str = @"BATCH";
            break;
        default:
            str = @"OFF";
            break;
    }
    NSString *command = [NSString stringWithFormat:@"%@ %@\r\n",@"SET RESPONSE",str];
    [self addStrToCommand:command];
}

/**
 *  方法说明: 查询打印机电量。
 *  <p>返回值:  31（低电量）；32 (中电量)；33 (高电量)；35 (正在充电)</p>
 *
 */
-(void)queryElectricity {
    unsigned char command[] = {0x1F,0x1B,0x1F,0xA8,0x10,0x11,0x12,0x13,0x14,0x15,0x77};
    [self.mCommandData appendData:[NSData dataWithBytes:command length:sizeof(command)]];
}

@end
