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

@interface GLShapeDrawer() {
  
}

/*!
 描画要素のDictionary key は 要素タイプ、value は頂点数
 */
@property (nonatomic, strong) NSMutableArray *elements;
@end

@interface  GLShapeDrawerInfo : NSObject

@property (nonatomic) int type;
@property (nonatomic) NSInteger count;
@property (nonatomic) NSInteger offset;

- (id) init:(int)type offset:(NSInteger)offset count:(NSInteger)count;

@end

@implementation GLShapeDrawerInfo

- (id) init:(int)type offset:(NSInteger)offset count:(NSInteger)count {
  self = [super init];
  if(self) {
    self.type = type;
    self.offset = offset;
    self.count = count;
  }
  return self;
}

@end

@implementation GLShapeDrawer

enum {
  FILL_CIRCLE,
  DRAW_CIRCLE,
  DRAW_LINE_IN_CIRCLE,
  DRAW_NEEDLE_IN_CIRCLE
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
      default:
        break;
    }
  }
  
  
}

/*!
 * 塗りつぶした円の描画のための頂点設定
 * @param array 頂点を設定する配列
 * @param x 描画位置-x
 * @param y 描画位置-y - 上がプラス
 * @param radius 半径
 * @param divides 円の分割数（精度）
 * @param color 色情報(r,g, b)
 * @param stride
 */
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
    [array putValue:(float)( x+cos(angle) * radius)];
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



@end
