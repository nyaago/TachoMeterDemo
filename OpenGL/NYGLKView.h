//
//  TachoMeterView.h
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/18.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@protocol NYGLKRenferer <NSObject>

- (void)setupGL;
- (void)tearDownGL;
- (void)update;

@end


@interface NYGLKView : GLKView

@property (nonatomic) BOOL paused;
/**
 * 描画Interval - 1秒での最大描画数(描画後、次ぎの描画がこのInterval/60秒後にされるようにする）
 */
@property (nonatomic) NSInteger frameInterval;
@property (nonatomic, strong) NSObject <NYGLKRenferer, GLKViewDelegate> *renderer;

- (void) start;
- (void) stop;

@end
