//
//  PeakMeterRenderer.h
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/21.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "MeterRenderer.h"
#import "NYGLKView.h"
#import "GLColor.h"

@protocol PeakMeterParameters <NSObject>


-(NSInteger) maxValue;
-(NSInteger) minValue;
-(NSInteger) scale;
-(NSInteger) scaleTextInterval;

- (NSString *) scaleText:(NSInteger) value;

@end

@interface PeakMeterRenderer : MeterRenderer  <GLKViewDelegate, NYGLKRenferer>

@property (nonatomic) NSInteger value;

@property (nonatomic, strong) GLColor *frameColor;
@property (nonatomic, strong) GLColor *valueColor;
@property (nonatomic, strong) GLColor *meterColor;
@property (nonatomic, strong) GLColor *scaleColor;

@property (nonatomic, strong) UIColor *scaleTextColor;


@property (nonatomic) CGFloat scaleTextSize;
@property (nonatomic) CGFloat scaleLength;
@property (nonatomic) NSInteger scaleWeight;

@property (nonatomic) UIFont *scaleTextFont;
/*!
 * メーターのTOP座標(0.0〜1.0fの座標系での）
 */
@property (nonatomic) CGFloat meterTop;
/*!
 * メーターのBOTTOM座標(0.0〜1.0fの座標系での）
 */
@property (nonatomic) CGFloat meterBottom;
/**
 * メーターの三角部分の比率（上下の三角個別の比率）
 */
@property (nonatomic) CGFloat ratioMeterTriangle;
/*!
 * メーターのLEFT座標(0.0〜1.0fの座標系での）
 */
@property (nonatomic) CGFloat meterLeft;

/*!
 * メーターのLEFT座標(0.0〜1.0fの座標系での）
 */
@property (nonatomic) CGFloat meterRight;






@property (nonatomic, strong) NSObject <PeakMeterParameters> *parameters;

- (id) initWithView:(GLKView *)view;

/*!
 @return Texture の頂点のPosition
 */
-(NSInteger) texturePositionInValueVertex;

@end
