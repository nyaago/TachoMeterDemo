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
#import "NYGLKView.h"
#import "GLColor.h"

@interface TachoMeterRenderere : NSObject <GLKViewDelegate, NYGLKRenferer>

@property (nonatomic, strong) GLKBaseEffect *effect;
@property (nonatomic, strong) GLKView *view;

@property (nonatomic) CGFloat frameRadius;
@property (nonatomic) CGFloat meterRadius;
@property (nonatomic) CGFloat meterScaleCircleRadius;
@property (nonatomic) CGFloat meterScaleLineRadius;

@property (nonatomic, strong) GLColor *frameColor;
@property (nonatomic, strong) GLColor *activeMeterColor;
@property (nonatomic, strong) GLColor *inactiveMeterColor;
@property (nonatomic, strong) GLColor *centerColor;
@property (nonatomic, strong) GLColor *scaleColor;
@property (nonatomic, strong) GLColor *largeScaleColor;
@property (nonatomic, strong) GLColor *redColor;


- (id) initWithView:(GLKView *)view;

@end
