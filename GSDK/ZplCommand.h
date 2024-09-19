//
//  ZplCommand.h
//  GSDK
//
//  Created by max on 2021/3/1.
//  Copyright © 2021 max. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZplConfig.h"
#import <UIKit/UIKit.h>

// 打印图片方式枚举
typedef NS_ENUM (NSUInteger,ZPLPAPERTYPE){
    PAPER_N = 0,//连续纸张
    PAPER_Y = 2,//非连续间隙纸张
    PAPER_W = 3,//非连续间隙纸张
    PAPER_M = 4,//非连续黑标纸张
    PAPER_A = 5//自动选择
};

@interface ZplCommand : NSObject

- (void) testCmd:(NSString *)cmds;

/**
 * 方法说明：标签起始，起始命令必须以这个开始
 */
- (void) startZpl;

/**
 * 方法说明：标签结束，最后命令必须以这个结束
 */
- (void) endZpl;

/**
 * 方法说明：获得打印命令
*/
-(NSData*) getCommand;

/**
 * 方法说明：将字符串转成十六进制码
 * @param  str  命令字符串
 */
-(void) addStrToCommand:(NSString *)str;

/**
 * 方法说明：执行打印
 * @param m 指定打印的份数（set）1≤m≤99999999
 * @param n 每张拷贝数 默认值：0(不复制) 每张标签需重复打印的张数 1≤n≤99999999
 * @param pauseCut 多少张后暂停，默认0(不暂停)
 * @param isPause 默认值YES，如果参数设定为 YES，打印机打印不会有暂停操作，如果设定为 NO，打印机每打印一组标签就会暂停，直到用户按下 FEED
 */
-(void) addPrintNum:(int) m copy:(int) n pauseCut:(int) pauseCut isPause:(BOOL) isPause;


/**
 * 方法说明：设置标签尺寸的宽和高
 * @param width  标签宽度
 * @param height 标签高度
 */
-(void) addSize:(int) width :(int) height;

/**
 * 方法说明：设置标签原点坐标
 * @param x  横坐标
 * @param y  纵坐标
 */
-(void) addReference:(int) x :(int)y;

/**
 * 方法说明：设置打印速度：默认3，其他值：2 ～ 5
 * 2 = 50.8 mm/sec. (2 inches/sec.)
 * 3 = 76.2 mm/sec. (3 inches/sec.)
 * 4 = 101.6 mm/sec. (4 inches/sec.)
 * 5 = 127 mm/sec.(5 inches/sec.)
 * @param speed  打印速度
*/
-(void) addSpeed:(int) speed;

/**
 * 方法说明：设置打印浓度
 * @param density  浓度：0 ～ 30
 */
-(void) addDensity:(int) density;

/**
 * 方法说明：打印镜像标签
 * @param isMirror  M 指令将整体的标签内容镜像打印出来。指令将图像左右颠倒过来
 */
-(void) addMirror:(BOOL) isMirror;

/**
 * 方法说明：设置打印方向
 * @param isInvert  方向指令将整体的标签内容转过 180 度
 */
-(void) addInvertOrientation:(BOOL) isInvert;

/**
 * 方法说明：清除上张标签内容
 */
-(void) addCls:(BOOL)isCls;

/**
 * 方法说明：设置纸张类型，该指令决定打印机使用何种纸张打印并且设置黑标的打印起始偏移
 * @param type  使用的纸张类型，必须设置值否则指令无效
 *  @param offset  黑标起始偏移：缺省值：0(在 type=PAPER_M时才有效)，其他值：-120 到 283
 */
-(void) setPaperType:(ZPLPAPERTYPE) type withBLineStartOffset:(int)offset;

/**
 * 方法说明：选择使用的介质类型。
 * @param m 选择使用的介质类型：缺省值：必须设置值否则指令无效，其他值：D = 热敏模式，T = 热转模式
*/
- (void) setMediaType:(NSString *)m;


/**
 * 方法说明：打印模式：该指令决定打印机在打印一批标签后的操作
 * @param m 选择模式：缺省值：T(撕纸模式) 其他值：P,R,A,C,D,F,L,U,K,V,S(无动作模式)
 * 注释： 调整的打印模式仅有两种，除撕纸外其余全部都为无操作。
*/
- (void) addPrintMode:(NSString *)m;


/**
 * 方法说明：标签上下偏移：该指令可以使标签内容根据自己需要上下偏移。负值把内容向标签上沿移动，正值把内容远离上沿方向移动。
 * @param m 下移值：缺省值：必须指定值，其他值：-120 到 120
*/
- (void) addTopOffset:(int) m;
/**
 * 方法说明：撕离位置调整：该指令让用户自行调整打印耗材打印完成后的停止位置，方便用户撕开或者切断。
 * @param m 停止位置： 默认值：上次设置的值，其他值：-120 到 120
 *  如果没有参数或者参数有误，指令被忽略
*/
- (void) adjustTearOffPosition:(int) m;

/**
 * 方法说明：指令在标签格式中印有打印段的内容黑白反色。它允许一个段由白变黑或由黑变白。当打印一个段，如果打印点是黑的，它变白；如果点是白的，它变黑
 * @param isReverse 反相打印： 缺省值：N=不反相打印标签，其他值：Y=是，开机初始值＝N （如无参数指令跳过）
 *  注意
 *   1. 指令将保留到下一个该指令值转换或打印机关机
 *   2. 该指令必须跟画框方法 addGraphicBoxX： 一起使用，由画框的宽高来决定反色区域
 *   3. 仅仅在这指令后的段被影响。
*/
- (void) addReversePrint:(BOOL) isReverse;

/**
 * 方法说明:在标签上绘制文字
 * @param x 横坐标
 * @param y 纵坐标
 * @param font  字体名称 默认值：0 其他值：A-Z，0-9（打印机的任何字体，包括下载字体，EPROM 中储存的，当然这些字体必须用^CW 来定义为 A-Z，0-9）
 * @param rotation  旋转角度 N = 正常 （Normal) R = 顺时针旋转 90 度（Roated) I = 顺时针旋转 180 度（Inverted) B = 顺时针旋转 270 度 (Bottom)
 * @param fontWid  字符宽度
 * @param fontHei 字符高度
 * @param text   文字字符串
 */
-(void) addTextwithX:(int)x withY:(int)y withFont:(NSString*)font withRotation:(NSString *)rotation withFontWid:(int)fontWid withFontHei:(int)fontHei withText:(NSString*) text;

/**
 * 方法说明：打印图片
 * @param x 横坐标
 * @param y 纵坐标
 * @param width  图片宽度
 * @param image  图片源
*/
-(void)addBitmapwithX:(int)x withY:(int)y withWidth:(int)width withImage:(UIImage *)image;

/**
 * 方法说明：打印QR码
 * @param content 条码内容
 * @param x 横坐标
 * @param y 纵坐标
 * @param config  条码配置
*/
-(void) addQRCode:(NSString*) content x:(int)x y:(int)y config:(QrCodeConfig *)config;

/**
 * 方法说明：打印CODE128码
 * @param content 条码内容
 * @param x 横坐标
 * @param y 纵坐标
 * @param config  条码配置
*/
-(void) addCODE128:(NSString*) content x:(int)x y:(int)y config:(BarCodeConfig *)config;

/**
 * 方法说明：打印EAN8码:
 * @param content 条码内容
 * @param x 横坐标
 * @param y 纵坐标
 * @param config  条码配置
*/
-(void) addEAN8:(NSString*)content x:(int)x y:(int)y config:(BarCodeConfig *)config;

/**
 * 方法说明：打印EAN13码
 * @param content 条码内容
 * @param x 横坐标
 * @param y 纵坐标
 * @param config  条码配置
*/
-(void) addEAN13:(NSString*)content x:(int)x y:(int)y config:(BarCodeConfig *)config;

/**
 * 方法说明：打印UPCA条码
 * @param content 条码内容
 * @param x 横坐标
 * @param y 纵坐标
 * @param config  条码配置
*/
-(void) addUPCA:(NSString*) content x:(int)x y:(int)y config:(BarCodeConfig *)config;
    
/**
 * 方法说明：打印UPCE条码
 * @param content 条码内容
 * @param x 横坐标
 * @param y 纵坐标
 * @param config  条码配置
*/
-(void) addUPCE:(NSString*) content x:(int)x y:(int)y config:(BarCodeConfig *)config;

/**
 * 方法说明：打印CODE39条码
 * @param content 条码内容
 * @param x 横坐标
 * @param y 纵坐标
 * @param config  条码配置
*/
-(void) addCODE39:(NSString*) content x:(int)x y:(int)y config:(BarCodeConfig *)config;

/**
 * 方法说明：画边框
 * @param x 横坐标
 * @param y 纵坐标
 * @param w  框宽度，若设置宽为0，可实现竖线
 * @param h  框高度，若设置高为0，可实现横线
 * @param b  线宽
 * @param r  边框圆角值，默认值：0 许可值：0～8
*/
- (void)addGraphicBoxX:(int)x y:(int)y w:(int)w h:(int)h border:(int)b rounding:(int)r;

/**
 * 方法说明：画圆
 * @param x 横坐标
 * @param y 纵坐标
 * @param d  圆直径
 * @param b  线宽
*/
- (void)addGraphicCircleX:(int)x y:(int)y diameter:(int)d border:(int)b;

/**
 * 方法说明：画斜线
 * @param x 横坐标
 * @param y 纵坐标
 * @param w  长
 * @param h  高
 * @param b  线宽
 * @param o  斜线方向：默认右倾线：输入“R”，其他值：左倾线，输入“L”
*/
- (void)addGraphicDiagonalLineX:(int)x y:(int)y w:(int)w h:(int)h border:(int)b Orientation:(NSString *)o;

/**
 * 方法说明：画椭圆
 * @param x 横坐标
 * @param y 纵坐标
 * @param w  椭圆宽度
 * @param h  椭圆高度
 * @param b  线宽
*/
- (void)addGraphicEllipseX:(int)x y:(int)y w:(int)w h:(int)h border:(int)b;


@end

