//
//  GLShapeDrawer.m
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/19.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "GLShapeDrawer.h"
#import "Vector2.h"

@interface  GLShapeDrawerInfo : NSObject

@property (nonatomic) int type;
@property (nonatomic) NSInteger count;
@property (nonatomic) NSInteger offset;
@property (nonatomic) NSInteger lineWidth;

- (id) init:(int)type offset:(NSInteger)offset count:(NSInteger)count;
- (id) init:(int)type offset:(NSInteger)offset count:(NSInteger)count
  lineWidth:(NSInteger)lineWidth;


@end


@interface GLShapeDrawer() {
  
}

/*!
 * 描画要素のDictionary key は 要素タイプ、value は頂点数
 */
@property (nonatomic, strong) NSMutableArray *elements;

/*!
 * 頂点設定済みの円の塗りつぶし描画実行
 */
- (void) fillCircle:(GLShapeDrawerInfo *)info;

/*!
 * 頂点設定済みの円描画実行
 */
- (void) drawCircle:(GLShapeDrawerInfo *)info;


/*!
 * 頂点設定済みの円の内側の目盛り線描画
 */
- (void) drawLineInCircle:(GLShapeDrawerInfo *)info;

/*!
 * 頂点設定済みの針の描画
 */
- (void) drawNeedle:(GLShapeDrawerInfo *)info;

/*!
 * 頂点設定済みの 塗りつぶした円環面（ドーナツ型）の描画
 */
- (void)fillTorus:(GLShapeDrawerInfo *)info;

/*!
 * 頂点設定済みの 塗りつぶした長方形の描画
 */
- (void) fillRectangle:(GLShapeDrawerInfo *)info;

/*!
 * 頂点設定済みの 塗りつぶした三角形の描画
 */
- (void) fillTriangle:(GLShapeDrawerInfo *)info;

/*!
 * 頂点設定済みの 線描画
 */
- (void) drawLine:(GLShapeDrawerInfo *)info;

@end


@implementation GLShapeDrawerInfo

- (id) init:(int)type offset:(NSInteger)offset count:(NSInteger)count {
  self = [self init:type offset:offset count:count lineWidth:1];
  return self;
}

- (id) init:(int)type offset:(NSInteger)offset count:(NSInteger)count
  lineWidth:(NSInteger)lineWidth {
  self = [super init];
  if(self) {
    self.type = type;
    self.offset = offset;
    self.count = count;
    self.lineWidth = lineWidth;
  }
  return self;
}

- (BOOL)isEqual:(id)anObject
{
  if (anObject == self) {
    return YES;
  }
  if (!anObject || ![anObject isKindOfClass:[self class]]) {
    return NO;
  }
  GLShapeDrawerInfo *other = (GLShapeDrawerInfo *)anObject;
  if (self.offset == other.offset) {
    return YES;
  }
  return NO;
}

@end

@implementation GLShapeDrawer

enum {
  FILL_CIRCLE,
  DRAW_CIRCLE,
  DRAW_LINE_IN_CIRCLE,
  DRAW_NEEDLE_IN_CIRCLE,
  FILL_TORUS,
  FILL_RECTANGLE,
  FILL_TRIANGLE,
  DRAW_LINE
};


- (id) init {
  self = [super init];
  if(self) {
    _elements = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void) drawArrays {
  for (NSObject *o  in self.elements) {
    GLShapeDrawerInfo *info = (GLShapeDrawerInfo *)o;
    switch (info.type) {
      case FILL_CIRCLE:
        [self fillCircle:info];
        break;
      case DRAW_CIRCLE:
        [self drawCircle:info];
        break;
      case DRAW_LINE_IN_CIRCLE :
        [self drawLineInCircle:info];
        break;
      case DRAW_NEEDLE_IN_CIRCLE :
        [self drawNeedle:info];
        break;
      case FILL_TORUS :
        [self fillTorus:info];
        break;
      case FILL_RECTANGLE :
        [self fillRectangle:info];
        break;
      case FILL_TRIANGLE :
        [self fillTriangle:info];
        break;
      case DRAW_LINE :
        [self drawLine:info];
        break;
      default:
        break;
    }
  }
  
  
}

- (NSInteger)fillCircleVertex:(FloatArray *)array
                      x:(CGFloat)x y:(CGFloat)y radius:(CGFloat)radius
                divides:(NSInteger)divides color:(GLColor *)color stride:(NSInteger)stride{
  int offset = array.position;
  int length = divides + 2;// 頂点数,2 => (中心と円のend=start)
  
  //頂点配列情報
  [array putValue:x];
  [array putValue:y];
  [array putValue:0];
  [array putValues:[color rgbArray] count:3];
  [array advancePosition:stride > (3+3) ? (stride - (3 + 3)) : 0 ];

  for (int i=1;i< length;i++) {
    float angle=(float)(2*M_PI*i/divides);
    [array putValue:(float)(x+cos(angle) * radius)];
    [array putValue:(float)(y+sin(angle) * radius)];
    [array putValue:0];
    [array putValues:[color rgbArray] count:3];
    [array advancePosition:stride > (3+3) ? (stride - (3 + 3)) : 0 ];
  }
  [self.elements addObject:[[GLShapeDrawerInfo alloc]
                            init:FILL_CIRCLE offset:offset / stride count:length]];
  return array.position;
  
}

- (NSInteger)vertexCountOfFillCircle:(NSInteger)divides {
  return divides + 2;
}

- (void) fillCircle:(GLShapeDrawerInfo *)info {
  
  glDrawArrays(GL_TRIANGLE_FAN,info.offset,info.count );

}


- (NSInteger)drawCircleVertex:(FloatArray *)array
                            x:(CGFloat)x y:(CGFloat)y radius:(CGFloat)radius
                      divides:(NSInteger)divides
                    drawRatio:(CGFloat)drawRatio
                        color:(GLColor *)color
                    lineWidth:(NSInteger)lineWidth
                       stride:(NSInteger)stride{
  int offset = array.position;
  int length = divides - 1;// 頂点数
  
  //頂点配列情報
  for (int i=0;i< length;i++) {
    float angle=[self getRadianForCircleWithIndex:i+1 divides:divides drawRatio:drawRatio];
    [array putValue:(float)( x+cos(angle) * radius)];
    [array putValue:(float)(y+sin(angle) * radius)];
    [array putValue:0];
    [array putValues:[color rgbArray] count:3];
    [array advancePosition:stride > (3+3) ? (stride - (3 + 3)) : 0 ];
  }
  [self.elements addObject:[[GLShapeDrawerInfo alloc]
                            init:DRAW_CIRCLE offset:offset / stride count:length
                            lineWidth:lineWidth]];
  return array.position;
  
}

- (NSInteger) vertexCountOfDrawCircle:(NSInteger)divides {
  return divides-1;
}

- (void) drawCircle:(GLShapeDrawerInfo *)info {
  
  glLineWidth(info.lineWidth);
  glDrawArrays(GL_LINE_STRIP ,info.offset,info.count );
//  glDrawArrays(GL_POINTS ,info.offset,info.count );
}

- (NSInteger)drawLineInCircleVertex:(FloatArray *)array
                            x:(CGFloat)x y:(CGFloat)y
                             radius:(CGFloat)radius
                      divides:(NSInteger)divides
                         lineLength:(CGFloat)lineLength
                    drawRatio:(CGFloat)drawRatio
                        color:(GLColor *)color
                    lineWidth:(NSInteger)lineWidth
                       stride:(NSInteger)stride{
  int offset = array.position;
  int length = divides + 1;// 頂点数
  Vector2 *baseStart = [[Vector2 alloc] initWithX:-lineLength y:0];
  Vector2 *baseEnd = [[Vector2 alloc] initWithX:0 y:0];
  
  //頂点配列情報
  for (int i=0;i< length;i++) {
    float angle=[self getRadianForCircleWithIndex:i divides:divides drawRatio:drawRatio];
    Vector2 *vecStart = [baseStart rotate:angle];
    vecStart = [vecStart translateX:x + cos(angle) * radius  y:(float) (y + sin(angle) * radius )];
    Vector2 *vecEnd = [baseEnd rotate:angle];
    vecEnd = [vecEnd translateX:x + cos(angle) * radius  y:(float) (y + sin(angle) * radius )];
    
    [array putValues:[vecStart xyz] count:3];
    [array putValues:[color rgbArray] count:3];
    [array advancePosition:stride > (3+3) ? (stride - (3 + 3)) : 0 ];
    [array putValues:[vecEnd xyz] count:3];
    [array putValues:[color rgbArray] count:3];
    [array advancePosition:stride > (3+3) ? (stride - (3 + 3)) : 0 ];
  }
  [self.elements addObject:[[GLShapeDrawerInfo alloc]
                            init:DRAW_LINE_IN_CIRCLE offset:offset / stride count:length * 2
                            lineWidth:lineWidth]];
  return array.position;
  
}

- (NSInteger) vertexCountOfDrawLineInCircle:(NSInteger)divides {
  return (divides + 1) * 2;
}

- (void) drawLineInCircle:(GLShapeDrawerInfo *)info {
  
  glLineWidth(info.lineWidth);
  for(int i = 0; i < info.count; i+=2) {
    glDrawArrays(GL_LINE_STRIP, info.offset + i, 2);

  }
}

- (NSInteger)drawNeedleVertex:(FloatArray *)array
                              value:(NSInteger)value
                                  x:(CGFloat)x y:(CGFloat)y
                             radius:(CGFloat)radius
                            divides:(NSInteger)divides
                         lineLength:(CGFloat)lineLength
                         coreLength:(CGFloat)coreLength
                          drawRatio:(CGFloat)drawRatio
                              colors:(NSArray *)colors
                          lineWidth:(CGFloat)lineWidth
                             stride:(NSInteger)stride{
  int offset = array.position;
  
  float vertexes[][3] = { {lineLength ,0.0f,0.0f},
    {-coreLength,-lineWidth / 2,0.0f},
    {-coreLength,lineWidth /2,0.0f}
  };
  float angle=[self getRadianForCircleWithIndex:value divides:divides drawRatio:drawRatio];

  for(int i = 0; i < 3; ++i) {
    float *p = vertexes[i];
    Vector2 *vec = [[Vector2 alloc] initWithX:*p y:*(p+1)];
    vec = [vec rotate:angle];
    if(x != 0 && y != 0) {
      vec = [vec translateX:x y:y];
    }
    [array putValues:[vec xyz] count:3];
    GLColor *color;
    if([colors count] > i) {
      color = [colors objectAtIndex:i];
    }
    else {
      color = [colors lastObject];
    }
    [array putValues:[color rgbArray] count:3];
    [array advancePosition:stride > (3+3) ? (stride - (3 + 3)) : 0 ];
  }
  GLShapeDrawerInfo *info = [[GLShapeDrawerInfo alloc]
                             init:DRAW_NEEDLE_IN_CIRCLE offset:offset / stride count:3
                             lineWidth:lineWidth];
  if([self.elements containsObject:info] == NO) {
    [self.elements addObject:info];
  }
  return array.position;
}

- (NSInteger) vertexCountOfDrawNeedle {
  return 3;
}

- (void) drawNeedle:(GLShapeDrawerInfo *)info {
  glDrawArrays(GL_TRIANGLE_STRIP, info.offset, 3);
}


- (CGFloat) getRadianForCircleWithIndex:(NSInteger) i  divides:(NSInteger)divides
                             drawRatio:(CGFloat)drawnRatio {
  float pos =  (float)(divides - i ) ;
  float angle = (float)(2*M_PI*pos / (divides / drawnRatio));
  angle = angle - (float)(2*M_PI * ((drawnRatio - 0.5f) / 2.0f ));
  return angle;
}


- (NSInteger)fillTorusVertex:(FloatArray *)array
                                  x:(CGFloat)x y:(CGFloat)y
                             radius:(CGFloat)radius
                        innerRadius:(CGFloat)innerRadius
                            divides:(NSInteger)divides
                         startAngle:(CGFloat)startAngle
                           endAngle:(CGFloat)endAngle
                              color:(GLColor *)color
                             stride:(NSInteger)stride{
  
  int offset = array.position;
  int newDevides = (int)(abs(endAngle - startAngle) / (2*M_PI) * divides);
  int length = newDevides + 1 ;// 頂点数

  CGFloat angle = startAngle;
  CGFloat step = (endAngle - startAngle) / newDevides ;
  
  for (int i=0;i< length;i++) {
    [array putValue:(float)( x+cos(angle) * radius)];
    [array putValue:(float)( y+sin(angle) * radius)];
    [array putValue:(float)0];
    [array putValues:[color rgbArray] count:3];
    [array advancePosition:stride > (3+3) ? (stride - (3 + 3)) : 0 ];
    
    [array putValue:(float)( x+cos(angle) * innerRadius)];
    [array putValue:(float)( y+sin(angle) * innerRadius)];
    [array putValue:(float)0];
    [array putValues:[color rgbArray] count:3];
    [array advancePosition:stride > (3+3) ? (stride - (3 + 3)) : 0 ];
    angle += step;
  }
  [self.elements addObject:[[GLShapeDrawerInfo alloc]
                            init:FILL_TORUS offset:offset / stride count:length * 2
                            lineWidth:0]];
  return array.position;
}

- (NSInteger)vertexCountOfFillTorusWithDivides:(NSInteger)divides
                                    startAngle:(CGFloat)startAngle
                                      endAngle:(CGFloat)endAngle {
  
  return (int)(abs(endAngle - startAngle) / (2*M_PI) * divides + 1) * 2;
}

- (void)fillTorus:(GLShapeDrawerInfo *)info {
  glDrawArrays(GL_TRIANGLE_STRIP,info.offset,info.count);

}


- (NSInteger) fillRectangle:(FloatArray *)array
                       left:(CGFloat)left top:(CGFloat)top
                      right:(CGFloat)right bottom:(CGFloat)bottom
                      color:(GLColor *)color
                     stride:(NSInteger)stride
{
  NSInteger offset = array.position;
  CGFloat vertexs[][3] = {
    {left, top, 0},
    {right, top, 0},
    {left, bottom, 0},
    {right, bottom, 0}
  };
  
  for(int i = 0; i < 4; ++i) {
    CGFloat *p = vertexs[i];
    [array putValues:p  count:3];
    [array putValues:[color rgbArray] count:3];
    [array advancePosition:stride > (3+3) ? (stride - (3 + 3)) : 0 ];
  }
  GLShapeDrawerInfo *info = [[GLShapeDrawerInfo alloc]
                             init:FILL_RECTANGLE offset:offset / stride count:4
                             lineWidth:0];
  if([self.elements containsObject:info] == NO) {
    [self.elements addObject:info];
  }
  return array.position;

}

- (NSInteger) vertexCOuntOfFillRectangle {
  return 4;
}

- (void) fillRectangle:(GLShapeDrawerInfo *)info {
  glDrawArrays(GL_TRIANGLE_STRIP, info.offset, info.count);
}


- (NSInteger) fillTriangle:(FloatArray *)array
                    point1:(CGPoint)point1
                    point2:(CGPoint)point2
                    point3:(CGPoint)point3
                      color:(GLColor *)color
                    stride:(NSInteger)stride {

  NSInteger offset = array.position;
  CGPoint points[] = {
    point1, point2, point3
  };
  
  for(int i = 0; i < 3; ++i) {
    CGPoint point = points[i];
    [array putValue:point.x];
    [array putValue:point.y];
    [array putValue:0.0f];
    [array putValues:[color rgbArray] count:3];
    [array advancePosition:stride > (3+3) ? (stride - (3 + 3)) : 0 ];
  }
  GLShapeDrawerInfo *info = [[GLShapeDrawerInfo alloc]
                             init:FILL_TRIANGLE offset:offset / stride count:3
                             lineWidth:0];
  if([self.elements containsObject:info] == NO) {
    [self.elements addObject:info];
  }
  return array.position;
 
}

- (NSInteger) vertexCOuntOfFillTriangle {
  return 3;
}

- (void) fillTriangle:(GLShapeDrawerInfo *)info {
  glDrawArrays(GL_TRIANGLE_STRIP, info.offset, info.count);
}


- (NSInteger) drawLineVertex:(FloatArray *)array
                    start:(CGPoint)start
                      end:(CGPoint)end
                     color:(GLColor *)color
             lineWidth:(NSInteger)lineWidth
                    stride:(NSInteger)stride {
  
  NSInteger offset = array.position;

  CGPoint points[] = {
    start, end
  };
  
  for(int i = 0; i < 2; ++i) {
    CGPoint point = points[i];
    [array putValue:point.x];
    [array putValue:point.y];
    [array putValue:0.0f];
    [array putValues:[color rgbArray] count:3];
    [array advancePosition:stride > (3+3) ? (stride - (3 + 3)) : 0 ];
  }
  GLShapeDrawerInfo *info = [[GLShapeDrawerInfo alloc]
                             init:DRAW_LINE offset:offset / stride count:2
                             lineWidth:0];
  if([self.elements containsObject:info] == NO) {
    [self.elements addObject:info];
  }
  return array.position;
}

- (NSInteger) vertexCountOfDrawLine {
  return 2;
}

- (void) drawLine:(GLShapeDrawerInfo *)info {
  glLineWidth(info.lineWidth);
  glDrawArrays(GL_LINES, info.offset, info.count);
}

/*!
 * 角度(radian)と半径から円周上のY座標を得る
 * @param rarian
 * @param radius
 * @return 円周上のY座標
 */
- (CGFloat) getYOfCircleWithRadian:(CGFloat)rarian radius:(CGFloat)radius {
  return (CGFloat)(sin(rarian) * radius);
}

/*!
 * 角度(radian)と半径から円周上のX座標を得る
 * @param rarian
 * @param radius
 * @return 円周上のX座標
 */
- (CGFloat) getXOfCircleWithRadian:(CGFloat)rarian radius:(CGFloat)radius {
  return (CGFloat)(cos(rarian) * radius);
}


- (CGFloat) radianToDegree:(CGFloat)radian {
  return radian * (180.0f / (float)M_PI);

}


@end
