//
//  TachoMeterRenderere.h
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/18.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "MeterRenderer.h"
#import "NYGLKView.h"
#import "GLColor.h"

/*!
 * タコメーター表示用パラメーターのプロトコル
 */
@protocol TachoMeterParameters

-(NSInteger) maxValue;
-(NSInteger) minValue;
-(NSInteger) scale;
-(NSInteger) largeScale;
-(NSInteger) mediumScale;
-(NSInteger) redZoneValue;
-(NSInteger) scaleTextInterval;

- (NSString *) scaleText:(NSInteger) value;

@end



@interface TachoMeterRenderere : MeterRenderer <GLKViewDelegate, NYGLKRenferer>


@property (nonatomic, strong) GLKBaseEffect *effect;
@property (nonatomic, strong) GLKView *view;

@property (nonatomic) CGFloat frameRadius;
@property (nonatomic) CGFloat meterRadius;
@property (nonatomic) CGFloat meterScaleCircleRadius;
@property (nonatomic) CGFloat meterScaleLineRadius;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) CGFloat centerRadius;

@property (nonatomic, strong) GLColor *frameColor;
@property (nonatomic, strong) GLColor *activeMeterColor;
@property (nonatomic, strong) GLColor *inactiveMeterColor;
@property (nonatomic, strong) GLColor *centerColor;
@property (nonatomic, strong) GLColor *scaleColor;
@property (nonatomic, strong) GLColor *largeScaleColor;
@property (nonatomic, strong) GLColor *redColor;

@property (nonatomic, strong) UIColor *scaleTextColor;
@property (nonatomic, strong) UIColor *valueTextColor;
@property (nonatomic, strong) UIColor *noteTextColor;
@property (nonatomic, strong) UIColor *valueBackgroundColor;


@property (nonatomic) CGFloat scaleLength;
@property (nonatomic) CGFloat medimuScaleLength;
@property (nonatomic) CGFloat largeScaleLength;

@property (nonatomic) CGFloat scaleTextSize;
@property (nonatomic) CGFloat valueTextSize;
@property (nonatomic) CGFloat noteTextSize;

@property (nonatomic) UIFont *scaleTextFont;
@property (nonatomic) UIFont *valueTextFont;
@property (nonatomic) UIFont *noteTextFont;

@property (nonatomic, strong) NSObject <TachoMeterParameters>  *parameters;

@property (nonatomic) CGFloat needleWeight;
@property (nonatomic) CGFloat needLength;
@property (nonatomic) CGFloat needCoreLength;
/*!
 針の色の配列 - 要素はGLColor
 */
@property (nonatomic, strong) NSArray *needleColors;


@property (nonatomic, strong) NSString *noteText;
@property (nonatomic, strong) NSNumber *value;


- (id) initWithView:(GLKView *)view;

@end
