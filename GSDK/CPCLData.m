//
//  CPCLData.m
//  GSDK
//
//  Created by max on 2020/11/02.
//  Copyright © 2020 Handset. All rights reserved.
//

#import "CPCLData.h"
typedef struct aRGBPixel
{
    unsigned char alpha;
    unsigned char red;
    unsigned char green;
    unsigned char blue;
} aRGBPixel;


@implementation BitmapImage

@end

@interface CPCLData() {
    UIImage *m_image;
    NSData *imageData;
}
@end

@implementation CPCLData

- (id)initWithUIImage:(UIImage *)image maxWidth:(int)maxWidth{
    self = [super init];
    if (self) {
        int32_t width = image.size.width; //CGImageGetWidth([image CGImage]);
        int32_t height = image.size.height; //CGImageGetHeight([image CGImage]);
        int32_t h2 = 0;
        if (width > maxWidth){
            h2 = (int)(((double)height * (float)maxWidth)/(double)width); //SCALLING IMAGE DOWN TO FIT ON PAPER IF TOO BIG
            //裁剪
            m_image = [self ScaleImageWithImage:image width:maxWidth height:h2];
            
        }
        else {
            m_image = image;
        }
        imageData = nil;
    }
    return self;
}


//裁剪图片
-(UIImage*)ScaleImageWithImage:(UIImage*)image width:(NSInteger)width height:(NSInteger)height
{
    CGSize size;
    size.width = width;
    size.height = height;
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return scaledImage;
}


#pragma mark - 方法调用


//cpcl
-(NSData *)printCPCLData
{
    //1打印 0不打印
    
    BitmapImage *bi = [self BitmapImageDataForLabelPrinterWithPrint:0x00 withNotPrint:0x01];
    const char* bytes = bi.bitmap.bytes;
    NSMutableData* dd = [[NSMutableData alloc] init];
    
    //横向点数计算需要除以8
    NSInteger w8 = bi.width / 8;
    //NSLog(@"%ld",(long)w8);
    //如果有余数，点数+1
    NSInteger remain8 = bi.width % 8;
    if (remain8 > 0) {
        w8 = w8 + 1;
    }
    
    NSInteger xL = w8 % 256;
    NSInteger xH = bi.width / (8 * 256);
    NSInteger yL = bi.height % 256;
    NSInteger yH = bi.height / 256;
    
    self.w = xL+xH*256;
    self.h = yL+yH*256;
    
    for (int h = 0; h < bi.height; h++) {
        for (int w = 0; w < w8; w++) {
            u_int8_t n = 0;
            for (int i=0; i<8; i++) {
                int x = i + w * 8;
                u_int8_t ch;
                if (x < bi.width) {
                    int pindex = h * (int)bi.width + x;
                    ch = bytes[pindex];
                }
                else{
                    ch = 0x00;
                }
                n = n << 1;
                n = n | ch;
            }
            [dd appendBytes:&n length:1];
        }
    }
    return dd;
}

/**
 *  方法说明：将图片数据进行二值化处理
 *  @param printP 可打印点
 *  @param nPrintP 不可打印点
 */
-(BitmapImage*)BitmapImageDataForLabelPrinterWithPrint:(u_int8_t)printP withNotPrint:(u_int8_t)nPrintP{

    
    CGImageRef cgImage = [m_image CGImage];
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    u_int32_t *pixels = malloc(width * height *sizeof(u_int32_t));
    memset(pixels, 0, width * height * sizeof(u_int32_t));
    NSMutableData* data = [[NSMutableData alloc] init];
    //初始化图片通道为RGB通道
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    //获取图片RGB通道数据，并赋值给pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(u_int32_t), colorSpaceRef, kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedLast);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);

    //NO.1
//    int total = (int)width * (int)height;
//    //灰度化
//    [self grayForImageData:pixels width:width height:height];
//    //二值化阀值
//    int iterative = [self iterativeBinaryzation:pixels withTotalPixel:total];
//    if (iterative < 1 || iterative >255) {
//        iterative = 127;
//    }
//
//    //将图片数据进行二值化处理，并将数据存至data中
//    for (int h = 0; h < height; h++) {
//        for (int w = 0; w < width; w++) {
//            int pIndex = w + h * (int)width;
//            //获取像素点
//            u_int8_t *pixel = (u_int8_t *)&pixels[pIndex];
//            //获取像素点的b(Blue)通道值
//            u_int8_t a = pixel[0];
//            u_int8_t b = pixel[1];
//            u_int8_t ch;
//            if (b < iterative && a >60) {
//                ch = printP;
//            } else {
//                ch = nPrintP;
//            }
//            [data appendBytes:&ch length:1];
//        }
//    }
//    CGContextRelease(context);
//    CGColorSpaceRelease(colorSpaceRef);
//    free(pixels);
    
    
    
    //NO.2将图片数据进行二值化处理，并将数据存至data中
    for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
            int pIndex = w + h * (u_int32_t)width;
            //获取像素点
            u_int8_t *pixel = (u_int8_t *)&pixels[pIndex];
            //获取像素点的b(Blue)通道值
            u_int8_t b = pixel[3];
            u_int8_t ch;
            if (b > 128) {
                ch = printP;
            } else {
                ch = nPrintP;
            }
            [data appendBytes:&ch length:1];
        }
    }

    
    BitmapImage* bi = [[BitmapImage alloc] init];
    bi.bitmap = data;
    bi.width = width;
    bi.height = height;
    return bi; 
}

/**
 * 二值化自适应阀值
 * @parma pixels 图片数据
 * @parma total 图片总像素点数（width x height）
 */
-(int)iterativeBinaryzation:(void *)pixels withTotalPixel:(int)total {
    if (pixels == NULL) {
        @throw [[NSException alloc]initWithName:@"NULLPointerException" reason:@"pixels is null" userInfo:nil];
    }
    //计算图片平均灰度值
    int averageBinaryzation = [self averageValueBinaryzation:pixels withTotalPixel:total];
    int lastBinaryzaion = 256;
    int binaryzation = averageBinaryzation;
    while ((binaryzation - lastBinaryzaion)!=0) {
        int c1 = 0;
        int j1 = 0;
        int c2 = 0;
        int j2 = 0;
        for (int i = 0; i < total; i++) {
            u_int8_t * pixel = (u_int8_t *)&pixels[i];
            u_int8_t b = pixel[1];
            if (binaryzation > b) {
                c1 += b;
                j1++;
            } else {
                c2 += b;
                j2++;
            }
        }
        if(j1 == 0){
            j1 = 1;
        }
        if (j2 == 0) {
            j2 = 1;
        }
        binaryzation = (c1 / j1 + c2 /j2)/2;
        lastBinaryzaion = binaryzation;
    }
    return binaryzation;
}

/**
 *  灰度化
 */
-(void)grayForImageData:(u_int32_t *)pixels width:(size_t)width height:(size_t)height {
    
    for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w ++) {
            int pIndex = w + h * (int)width;
            uint8_t *pixel = (uint8_t *)&pixels[pIndex];
            uint8_t red = pixel[1];
            uint8_t green = pixel[2];
            uint8_t blue = pixel[3];
            uint8_t gray = (int)(0.11 * red + 0.59 * green + 0.3 * blue);
            pixel[1] = gray;
            pixel[2] = gray;
            pixel[3] = gray;
        }
    }
}


-(int)averageValueBinaryzation:(void *)pixels withTotalPixel:(int)total {
    int grayValue = 0;
    for (int i = 0; i<total; i++) {
        u_int8_t * pixel = (u_int8_t *)&pixels[i];
        grayValue += pixel[3];
    }
    return grayValue / total;
}

//自己的 针对票据机
-(BitmapImage*)getBitmapImageDataWithPrint:(u_int8_t)printP withNotPrint:(u_int8_t)nPrintP{
    
    CGImageRef cgImage = [m_image CGImage];
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    NSInteger psize = sizeof(aRGBPixel);
    
    aRGBPixel * pixels = malloc(width * height * psize);
    
    NSMutableData* data = [[NSMutableData alloc] init];
    [self ManipulateImagePixelDataWithCGImageRef:cgImage imageData:pixels];
    for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
            int pIndex = [self PixelIndexWithX:w y:h width:(u_int32_t)width];
            aRGBPixel pixel = pixels[pIndex];
            //            if ([self PixelBrightnessWithRed:pixel.red green:pixel.green blue:pixel.blue] <= 127)
            if ([self GetGreyLevelWithARGBPixel:pixel intensity:0.9] <= 200){
                
                //打印黑,
//                u_int8_t ch = 0x01;
                u_int8_t ch = printP ;
                [data appendBytes:&ch length:1];
            }
            else{
                //打印白
//                u_int8_t ch = 0x00;
                u_int8_t ch = nPrintP ;

                [data appendBytes:&ch length:1];
            }
        }
    }
    
    free(pixels);
    
    BitmapImage* bi = [[BitmapImage alloc] init];
    bi.bitmap = data;
    bi.width = width;
    bi.height = height;
    return bi;
}









#pragma mark 获取像素信息

// 参考 http://developer.apple.com/library/mac/#qa/qa1509/_index.html
-(void)ManipulateImagePixelDataWithCGImageRef:(CGImageRef)inImage imageData:(void*)oimageData
{
    // Create the bitmap context
    CGContextRef cgctx = [self CreateARGBBitmapContextWithCGImageRef:inImage];
    if (cgctx == NULL)
    {
        // error creating context
        return;
    }
    
    // Get image width, height. We'll use the entire image.
    size_t w = CGImageGetWidth(inImage);
    size_t h = CGImageGetHeight(inImage);
    CGRect rect = {{0,0},{w,h}};
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(cgctx, rect, inImage);
    
    // Now we can get a pointer to the image data associated with the bitmap
    // context.
    void *data = CGBitmapContextGetData(cgctx);
    if (data != NULL)
    {
        CGContextRelease(cgctx);
        memcpy(oimageData, data, w * h * sizeof(u_int8_t) * 4);
        free(data);
        return;
    }
    
    // When finished, release the context
    CGContextRelease(cgctx);
    // Free image data memory for the context
    if (data)
    {
        free(data);
    }
    
    return;
}

// 参考 http://developer.apple.com/library/mac/#qa/qa1509/_index.html
-(CGContextRef)CreateARGBBitmapContextWithCGImageRef:(CGImageRef)inImage
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    colorSpace =CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL)
    {
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedFirst);
    if (context == NULL)
    {
        free (bitmapData);
    }
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease( colorSpace );
    
    return context;
}

-(u_int8_t)PixelBrightnessWithRed:(u_int8_t)red green:(u_int8_t)green blue:(u_int8_t)blue
{
    int level = ((int)red + (int)green + (int)blue)/3;
    return level;
}

-(u_int32_t)PixelIndexWithX:(u_int32_t)x y:(u_int32_t)y width:(u_int32_t)width
{
    return (x + (y * width));
}


-(NSInteger)GetGreyLevelWithARGBPixel:(aRGBPixel)source intensity:(float)intensity
{
    if (source.alpha == 0)
    {
        return 255;
    }
    
    int32_t gray = (int)(((source.red + source.green +  source.blue) / 3) * intensity);
    
    if (gray > 255)
        gray = 255;
    
    return (u_int8_t)gray;
}
@end

