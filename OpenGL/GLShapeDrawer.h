//
//  GLShapeDrawer.h
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/19.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLColor.h"
#import "FloatArray.h"

@interface GLShapeDrawer : NSObject

/*!
 設定した頂点の描画を実行
 */
- (void) drawArrays;

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
                divides:(NSInteger)divides color:(GLColor *)color stride:(NSInteger)stride;

- (NSInteger)vertexCountOfFillCircle:(NSInteger)divides;

@end
