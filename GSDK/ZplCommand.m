//
//  ZplCommand.m
//  GSDK
//
//  Created by max on 2021/3/1.
//  Copyright © 2021 max. All rights reserved.
//

#import "ZplCommand.h"
#import "ZplConfig.h"
#import "GPUtils.h"
@interface ZplCommand()
@property(nonatomic, assign) NSStringEncoding encoding;
@property(nonatomic, strong) NSMutableData *mCommandData;
@end

@implementation ZplCommand

/**
 * 方法说明：清除上张标签内容
 */
-(void)addCls:(BOOL)isCls {
    NSString *r = (isCls)?@"Y":@"N";
    [self addStrToCommand: [NSString stringWithFormat:@"^MC%@",r]];
}

- (void) testCmd:(NSString *)cmds {
    [self addStrToCommand:cmds];
}

/**
 * 方法说明：设置纸张类型，该指令决定打印机使用何种纸张打印并且设置黑标的打印起始偏移
 * @param type  使用的纸张类型，必须设置值否则指令无效
 *  @param offset  黑标起始偏移：缺省值：0(在 type=PAPER_M时才有效)，其他值：-120 到 283
 */
-(void) setPaperType:(ZPLPAPERTYPE) type withBLineStartOffset:(int)offset {
    NSString *r = @"N";
    if (type == PAPER_N) r = @"N";
    if (type == PAPER_Y) r = @"Y";
    if (type == PAPER_W) r = @"W";
    if (type == PAPER_M) r = @"M";
    if (type == PAPER_A) r = @"A";
    
    if (offset < -120) offset = - 120;
    if (offset > 283) offset = 283;
    [self addStrToCommand: [NSString stringWithFormat:@"^MN%@,%d",r,offset]];
}

/**
 * 方法说明：选择使用的介质类型。
 * @param m 选择使用的介质类型：缺省值：必须设置值否则指令无效，其他值：D = 热敏模式，T = 热转模式
*/
- (void) setMediaType:(NSString *)m {
    NSString *r = ([m isEqualToString:@"T"])?@"T":@"D";
    [self addStrToCommand: [NSString stringWithFormat:@"^MT%@",r]];
}


/**
 * 方法说明：打印模式：该指令决定打印机在打印一批标签后的操作
 * @param m 选择模式：缺省值：T(撕纸模式) 其他值：P,R,A,C,D,F,L,U,K,V,S(无动作模式)
 * 注释： 调整的打印模式仅有两种，除撕纸外其余全部都为无操作。
*/
- (void) addPrintMode:(NSString *)m {
    NSString *r = @"T";
    if (![m isEqualToString:@"T"]) r = @"P";
    [self addStrToCommand: [NSString stringWithFormat:@"^MM%@",r]];
}


/**
 * 方法说明：标签上下偏移：该指令可以使标签内容根据自己需要上下偏移。负值把内容向标签上沿移动，正值把内容远离上沿方向移动。
 * @param m 下移值：缺省值：必须指定值，其他值：-120 到 120
*/
- (void) addTopOffset:(int) m {
    if (m < - 120) m = - 120;
    if (m > 120) m = 120;
    [self addStrToCommand: [NSString stringWithFormat:@"^LT%d",m]];
}

/**
 * 方法说明：撕离位置调整：该指令让用户自行调整打印耗材打印完成后的停止位置，方便用户撕开或者切断。
 * @param m 停止位置： 默认值：上次设置的值，其他值：-120 到 120
 *  如果没有参数或者参数有误，指令被忽略
*/
- (void) adjustTearOffPosition:(int) m {
    if (m < 0) m = -m;
    if (m > 120) m = 120;
    NSString *r = [NSString stringWithFormat:@"%d",m];
    if (r.length == 1) r = [NSString stringWithFormat:@"00%@",r];
    if (r.length == 2) r = [NSString stringWithFormat:@"0%@",r];
    if (r.length == 3) {
        [self addStrToCommand: [NSString stringWithFormat:@"~TA%@",r]];
    }
}

/**
 * 方法说明：指令在标签格式中印有打印段的内容黑白反色。它允许一个段由白变黑或由黑变白。当打印一个段，如果打印点是黑的，它变白；如果点是白的，它变黑
 * @param isReverse 反相打印： 缺省值：N=不反相打印标签，其他值：Y=是，开机初始值＝N （如无参数指令跳过）
 *  注意
 *   1. 指令将保留到下一个该指令值转换或打印机关机
 *   2. 该指令必须跟画框方法 addGraphicBoxX： 一起使用，由画框的宽高来决定反色区域
 *   3. 仅仅在这指令后的段被影响。
*/
- (void) addReversePrint:(BOOL) isReverse {
    NSString *r = (isReverse)?@"Y":@"N";
    [self addStrToCommand: [NSString stringWithFormat:@"^LR%@",r]];
}

-(void) addBitmapwithX:(int)x withY:(int)y withWidth:(int)width withImage:(UIImage *)image {
    UIImage *newImage = [GPUtils imageWithScaleImage:image andScaleWidth:width];
    newImage = [GPUtils grayImage:newImage];
    int wid = newImage.size.width;
    int rowBytes = ceil(wid/8);
    if (wid%8) {
        rowBytes = ceil(wid/8) + 1;
    }
    NSString *pp = [GPUtils printZplCmd:newImage];
    [self addStrToCommand: [NSString stringWithFormat:@"~DGR:SAMPLE.GRF,%u,%d,",pp.length/2,rowBytes]];
    [self addStrToCommand:pp];
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d^XGR:SAMPLE.GRF,1,1^FS",x,y]];
}

/**
 * 方法说明：执行打印
 * @param m 指定打印的份数（set）1≤m≤99999999
 * @param n 每张拷贝数 默认值：0(不复制) 每张标签需重复打印的张数 1≤n≤99999999
 * @param pauseCut 多少张后暂停，默认0(不暂停)
 * @param isPause 默认值YES，如果参数设定为 YES，打印机打印不会有暂停操作，如果设定为 NO，打印机每打印一组标签就会暂停，直到用户按下 FEED
*/
-(void) addPrintNum:(int) m copy:(int) n pauseCut:(int) pauseCut isPause:(BOOL) isPause {
    NSString *r = (isPause)?@"Y":@"N";
    [self addStrToCommand: [NSString stringWithFormat:@"^PQ%d,%d,%d,%@",m,pauseCut,n,r]];
}

-(NSStringEncoding)encoding{
    if (!_encoding) {
        _encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    }
    return _encoding;
}

-(id) init {
    
    self = [super init];
    if (self) {
        self.mCommandData = [NSMutableData data];
    }
    
    return self;
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
 * 方法说明：标签起始
 */
- (void) startZpl {
    [self addStrToCommand: [NSString stringWithFormat:@"^XA"]];
}

/**
 * 方法说明：标签结束
 */
- (void) endZpl {
    [self addStrToCommand: [NSString stringWithFormat:@"^XZ"]];
}

/**
 * 方法说明：设置标签尺寸的宽和高
 * @param width  标签宽度
 * @param height 标签高度
 */
-(void) addSize:(int) width :(int) height {
    if (width < 2) width = 2;
    if (height < 1 || height > 9999) height = 1;
    [self addStrToCommand: [NSString stringWithFormat:@"^PW%d",width]]; // 宽度
    [self addStrToCommand: [NSString stringWithFormat:@"^LL%d^FS",height]]; //长度
}

/**
 * 方法说明：设置标签原点坐标
 * @param x  横坐标
 * @param y  纵坐标
 */
-(void) addReference:(int) x :(int)y {
    [self addStrToCommand: [NSString stringWithFormat:@"^LH%d,%d",x,y]];
}


/**
 * 方法说明：设置打印速度：默认3，其他值：2 ～ 5
 * 2 = 50.8 mm/sec. (2 inches/sec.)
 * 3 = 76.2 mm/sec. (3 inches/sec.)
 * 4 = 101.6 mm/sec. (4 inches/sec.)
 * 5 = 127 mm/sec.(5 inches/sec.)
 * @param speed  打印速度
 */
-(void) addSpeed:(int) speed {
    if (speed < 2) speed = 2;
    if (speed > 14) speed = 14;
    [self addStrToCommand: [NSString stringWithFormat:@"^PR%d",speed]]; //速度
}


/**
 * 方法说明：设置打印浓度
 * @param density  浓度：0 ～ 30
 */
-(void) addDensity:(int) density {
    if (density > 30) density = 30;
    if (density < 0) density = 0;
    NSString *r = [NSString stringWithFormat:@"%d",density];
    if (r.length == 1) r = [NSString stringWithFormat:@"0%@",r];
    [self addStrToCommand: [NSString stringWithFormat:@"~SD%@",r]];
}

/**
 * 方法说明：打印镜像标签
 * @param isMirror  M 指令将整体的标签内容镜像打印出来。指令将图像左右颠倒过来
 */
-(void) addMirror:(BOOL) isMirror {
    NSString *r = (isMirror)?@"Y":@"N";
    [self addStrToCommand: [NSString stringWithFormat:@"^PM%@",r]];
}

/**
 * 方法说明：设置打印方向
 * @param isInvert  方向指令将整体的标签内容转过 180 度
*/
-(void) addInvertOrientation:(BOOL) isInvert {
    NSString *r = (isInvert)?@"I":@"N";
    [self addStrToCommand: [NSString stringWithFormat:@"^PO%@",r]];
}

/**
 * 方法说明:在标签上绘制文字
 * @param x 横坐标
 * @param y 纵坐标
 * @param font  字体名称 默认值：0 其他值：A-Z，0-9（打印机的任何字体，包括下载字体，EPROM 中储存的，当然这些字体必须用^CW 来定义为 A-Z，0-9）
 * @param rotation  旋转角度 N = 正常 （Normal) R = 顺时针旋转 90 度（Roated) I = 顺时针旋转 180 度（Inverted) B = 顺时针旋转 270 度 (Bottom)
 * @param fontWid  字符宽度: 默认值:15 点或上一次^CF 的值。可接受 10-1500 点
 * @param fontHei 字符高度 默认值:12 点或上一次^CF 的值，也可以显示为 0 可接受 10-1500 点
 * @param text   文字字符串
 */
-(void) addTextwithX:(int)x withY:(int)y withFont:(NSString*)font withRotation:(NSString *)rotation withFontWid:(int)fontWid withFontHei:(int)fontHei withText:(NSString*) text {
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d",x,y]];
    if (![self canEditWithStr:font]) font = @"0";
    if (![rotation isEqualToString:@"N"] && ![rotation isEqualToString:@"R"] && ![rotation isEqualToString:@"I"] && ![rotation isEqualToString:@"B"]) rotation = @"N";
    [self addStrToCommand: [NSString stringWithFormat:@"^A%@%@,%d,%d",font,rotation,fontWid,fontHei]];
    [self addStrToCommand: [NSString stringWithFormat:@"^FD%@^FS",text]];
}

- (BOOL) canEditWithStr:(NSString *)str
{
    BOOL res = YES;
    NSCharacterSet* tmpSet = [NSCharacterSet characterSetWithCharactersInString:@"1234567890QWERTYUIOPLKJHGFDSAZXCVBNM"];
    int i = 0;
    while (i < str.length) {
        NSString * string = [str substringWithRange:NSMakeRange(i, 1)];
        NSRange range = [string rangeOfCharacterFromSet:tmpSet];
        if (range.length == 0) {
            res = NO;
            break;
        }
        i++;
    }
    if ([str isEqualToString:@""]) {
        res = YES;
    }
    
    return res;
}

- (NSString *)getOriCmd:(ZPLORIENTATION)o {
    if (o == ZPL_NORMAL) return @"N";
    if (o == ZPL_ROATED) return @"R";
    if (o == ZPL_INVERTED) return @"I";
    if (o == ZPL_BOTTOM) return @"B";
    return @"N";
}

- (NSString *)getBoolCmd:(BOOL)s {
    return (s)?@"Y":@"N";
}

/**
 * 方法说明：打印QR码
 */
-(void) addQRCode:(NSString*) content x:(int)x y:(int)y config:(QrCodeConfig *)config {
    
    QrCodeConfig *pram = config;
    if (!pram) {
        pram = [QrCodeConfig new];
        pram.mode = 2;
        pram.mFactor = 10;
        pram.ecclever = @"Q";
        pram.maskValue = 7;
    }
    
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d",x,y]];
    [self addStrToCommand: [NSString stringWithFormat:@"^BQN,%d,%d,%@,%d",pram.mode,pram.mFactor,pram.ecclever,pram.maskValue]];
    [self addStrToCommand: [NSString stringWithFormat:@"^FD%@^FS",content]];
}

/**
 * 方法说明：打印CODE128码
 */
-(void) addCODE128:(NSString*) content x:(int)x y:(int)y config:(BarCodeConfig *)config {
    
    BarCodeConfig *pram = config;
    if (!pram) {
        pram = [BarCodeConfig new];
        pram.orienftation = ZPL_NORMAL;
        pram.barHeight = 100;
        pram.wh = 3;
        pram.isNote = YES;
        pram.isAbove = NO;
    }
    
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d^BY%d",x,y,pram.wh]];
    [self addStrToCommand: [NSString stringWithFormat:@"^BC%@,%d,%@,%@,N",[self getOriCmd:pram.orienftation],pram.barHeight,[self getBoolCmd:pram.isNote],[self getBoolCmd:pram.isAbove]]];
    [self addStrToCommand: [NSString stringWithFormat:@"^FD%@^FS",content]];
}

/**
 * 方法说明：打印EAN8码:
 * @param content 数据范围0-9，长度为7位
 */
-(void) addEAN8:(NSString*)content x:(int)x y:(int)y config:(BarCodeConfig *)config {
    BarCodeConfig *pram = config;
    if (!pram) {
        pram = [BarCodeConfig new];
        pram.orienftation = ZPL_NORMAL;
        pram.barHeight = 100;
        pram.wh = 3;
        pram.isNote = YES;
        pram.isAbove = NO;
    }
    
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d^BY%d",x,y,pram.wh]];
    [self addStrToCommand: [NSString stringWithFormat:@"^B8%@,%d,%@,%@",[self getOriCmd:pram.orienftation],pram.barHeight,[self getBoolCmd:pram.isNote],[self getBoolCmd:pram.isAbove]]];
    [self addStrToCommand: [NSString stringWithFormat:@"^FD%@^FS",content]];
}

/**
 * 方法说明：打印EAN13码
 * @param content 数据范围0-9，长度为12位
 */
-(void) addEAN13:(NSString*)content x:(int)x y:(int)y config:(BarCodeConfig *)config {
    BarCodeConfig *pram = config;
    if (!pram) {
        pram = [BarCodeConfig new];
        pram.orienftation = ZPL_NORMAL;
        pram.barHeight = 100;
        pram.wh = 3;
        pram.isNote = YES;
        pram.isAbove = NO;
    }
    
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d^BY%d",x,y,pram.wh]];
    [self addStrToCommand: [NSString stringWithFormat:@"^BE%@,%d,%@,%@",[self getOriCmd:pram.orienftation],pram.barHeight,[self getBoolCmd:pram.isNote],[self getBoolCmd:pram.isAbove]]];
    [self addStrToCommand: [NSString stringWithFormat:@"^FD%@^FS",content]];
}


/**
 * 方法说明：打印UPCA条码
 * @param content 数据范围0-9，长度为11位
 */
-(void) addUPCA:(NSString*) content x:(int)x y:(int)y config:(BarCodeConfig *)config {
    BarCodeConfig *pram = config;
    if (!pram) {
        pram = [BarCodeConfig new];
        pram.orienftation = ZPL_NORMAL;
        pram.barHeight = 100;
        pram.wh = 3;
        pram.isNote = YES;
        pram.isAbove = NO;
    }
    
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d^BY%d",x,y,pram.wh]];
    [self addStrToCommand: [NSString stringWithFormat:@"^BU%@,%d,%@,%@,Y",[self getOriCmd:pram.orienftation],pram.barHeight,[self getBoolCmd:pram.isNote],[self getBoolCmd:pram.isAbove]]];
    [self addStrToCommand: [NSString stringWithFormat:@"^FD%@^FS",content]];
}

/**
 * 方法说明：打印UPCE条码
 * @param content 数据范围0-9，长度为11位
 */
-(void) addUPCE:(NSString*) content x:(int)x y:(int)y config:(BarCodeConfig *)config {
    BarCodeConfig *pram = config;
    if (!pram) {
        pram = [BarCodeConfig new];
        pram.orienftation = ZPL_NORMAL;
        pram.barHeight = 100;
        pram.wh = 3;
        pram.isNote = YES;
        pram.isAbove = NO;
    }
    
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d^BY%d",x,y,pram.wh]];
    [self addStrToCommand: [NSString stringWithFormat:@"^B9%@,%d,%@,%@,Y",[self getOriCmd:pram.orienftation],pram.barHeight,[self getBoolCmd:pram.isNote],[self getBoolCmd:pram.isAbove]]];
    [self addStrToCommand: [NSString stringWithFormat:@"^FD%@^FS",content]];
}

/**
 * 方法说明:打印CODE39条码
 * @param content  数据范围0-9 A-Z SP $ % + - . / ，*为 (开始/结束字符)
 */
-(void) addCODE39:(NSString*) content x:(int)x y:(int)y config:(BarCodeConfig *)config {
    BarCodeConfig *pram = config;
    if (!pram) {
        pram = [BarCodeConfig new];
        pram.orienftation = ZPL_NORMAL;
        pram.barHeight = 100;
        pram.wh = 3;
        pram.isNote = YES;
        pram.isAbove = NO;
    }
    
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d^BY%d",x,y,pram.wh]];
    [self addStrToCommand: [NSString stringWithFormat:@"^B3%@,N,%d,%@,%@",[self getOriCmd:pram.orienftation],pram.barHeight,[self getBoolCmd:pram.isNote],[self getBoolCmd:pram.isAbove]]];
    [self addStrToCommand: [NSString stringWithFormat:@"^FD%@^FS",content]];
}


/*
 画框：
 可通过框实现横线：设置高为0
 可通过框实现竖线：设置宽为0
 */
- (void)addGraphicBoxX:(int)x y:(int)y w:(int)w h:(int)h border:(int)b rounding:(int)r {
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d",x,y]];
    if (r == 0) {
        [self addStrToCommand: [NSString stringWithFormat:@"^GB%d,%d,%d^FS",w,h,b]];
    } else {
        [self addStrToCommand: [NSString stringWithFormat:@"^GB%d,%d,%d,,%d^FS",w,h,b,r]];
    }
    
}

/// 画圆
- (void)addGraphicCircleX:(int)x y:(int)y diameter:(int)d border:(int)b {
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d",x,y]];
    [self addStrToCommand: [NSString stringWithFormat:@"^GC%d,%d,B^FS",d,b]];
}

/// 画斜线
- (void)addGraphicDiagonalLineX:(int)x y:(int)y w:(int)w h:(int)h border:(int)b Orientation:(NSString *)o {
    if (![o isEqualToString:@"L"]) o = @"R";
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d",x,y]];
    [self addStrToCommand: [NSString stringWithFormat:@"^GD%d,%d,%d,,%@^FS",w,h,b,o]];
}

///  画椭圆
- (void)addGraphicEllipseX:(int)x y:(int)y w:(int)w h:(int)h border:(int)b {
    [self addStrToCommand: [NSString stringWithFormat:@"^FO%d,%d",x,y]];
    [self addStrToCommand: [NSString stringWithFormat:@"^GE%d,%d,%d,B^FS",w,h,b]];
}


@end
