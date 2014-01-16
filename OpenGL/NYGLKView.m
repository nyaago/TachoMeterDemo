//
//  TachoMeterView.m
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/18.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import "NYGLKView.h"


@interface NYGLKView() {
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;
@property (nonatomic, readonly) NSTimeInterval timeSinceLastUpdate;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic, strong) NSTimer *timer;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation NYGLKView


- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Initialization code
    [self setDefault];
  }
  return self;
}

- (void)dealloc
{
  [self tearDownGL];
  
  if ([EAGLContext currentContext] == self.context) {
    [EAGLContext setCurrentContext:nil];
  }
}



#pragma mark - Public

- (void) start {

  self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
  if (!self.context) {
    NSLog(@"Failed to create ES context");
  }
  self.drawableDepthFormat = GLKViewDrawableDepthFormat24;
  [self setupGL];
  
  _timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * self.frameInterval)
                                            target:self
                                          selector:@selector(display)
                                          userInfo:nil
                                           repeats:NO];
}

- (void) stop {
  
  [_timer invalidate];
  _timer = nil;
}

- (void) setRenderer:(NSObject<NYGLKRenferer,GLKViewDelegate> *)renderer {
  _renderer = renderer;
  self.delegate = renderer;
}

#pragma mark - Properties

- (void) setPaused:(BOOL)paused {
  _paused = paused;
  if (paused == NO) {
    [self display];
  }
}


#pragma mark - Inherited From GLKView

- (void) display {
  if(self.paused == NO) {
    [self update];
    [super display];
      _timer = [NSTimer scheduledTimerWithTimeInterval:(NSTimeInterval)((1.0 / 60.0) * self.frameInterval)
                                                target:self
                                              selector:@selector(display)
                                              userInfo:nil
                                               repeats:NO];
  }
}

#pragma mark -  OpenGL ES 2

- (void)setupGL
{
  [EAGLContext setCurrentContext:self.context];
  
  [self.renderer setupGL];
}

- (void)tearDownGL
{
  [EAGLContext setCurrentContext:self.context];

  [self.renderer tearDownGL];
}


- (void)update
{
  [self.renderer update];
}



/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark Private Properties

- (NSTimeInterval) timeSinceLastUpdate {
  return (- 0 - [self.lastUpdated timeIntervalSinceNow]);
}

#pragma mark Private Methods

- (void) setDefault {
  _paused = NO;
  _frameInterval = 12;
}

@end
