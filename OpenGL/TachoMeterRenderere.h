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

@interface TachoMeterRenderere : NSObject <GLKViewDelegate, NYGLKRenferer>

@property (nonatomic, strong) GLKBaseEffect *effect;
@property (nonatomic, strong) GLKView *view;

- (id) initWithView:(GLKView *)view;

@end
