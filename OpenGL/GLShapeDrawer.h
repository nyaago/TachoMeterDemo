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
 * 円塗りつぶし描画のための頂点設定
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

/*!
 * @param divides  円の分割数（精度）
 * @return 円塗りつぶし描画に必要な頂点数
 */
- (NSInteger)vertexCountOfFillCircle:(NSInteger)divides;

/**
 * 円or円の部分描画の頂点設定
 * @param array 頂点を設定する配列
 * @param x 描画位置-x
 * @param y 描画位置-y - 上がプラス
 * @param radius 半径
 * @param divides 円の分割数（精度）
 * @param drawRatio 全円を1とした円の大きさ
 * @param color 色情報(a,r,g,b)
 * @param lineWidth 線の太さ
 * @param stride
 */

- (NSInteger)drawCircleVertex:(FloatArray *)array
                            x:(CGFloat)x y:(CGFloat)y radius:(CGFloat)radius
                      divides:(NSInteger)divides
                    drawRatio:(CGFloat)drawRatio
                        color:(GLColor *)color
                    lineWidth:(NSInteger)lineWidth
                       stride:(NSInteger)stride;

/*!
 * @param divides  円の分割数（精度）
 * @return 円描画に必要な頂点数
 */
- (NSInteger) vertexCountOfDrawCircle:(NSInteger)divides;


/**
 * 円の内側に目盛り線を引く
 * @param x 描画位置-x
 * @param y 描画位置-y - 上がプラス
 * @param lineLength ラインの長さ
 * @param radius 半径
 * @param divides 円の分割数（精度）
 * @param drawnRatio 線が描画される領域-全体の内の比率、 > 0, <= 1.0f
 * @param color 色情報(a,r,g,b)
 */
- (NSInteger)drawLineInCircleVertex:(FloatArray *)array
                                  x:(CGFloat)x y:(CGFloat)y
                             radius:(CGFloat)radius
                            divides:(NSInteger)divides
                         lineLength:(CGFloat)lineLength
                          drawRatio:(CGFloat)drawRatio
                              color:(GLColor *)color
                          lineWidth:(NSInteger)lineWidth
                             stride:(NSInteger)stride;


/**
 * @param divides  円の分割数（精度）
 * @return 円の内側に目盛り線を引くための頂点の数
*/
- (NSInteger) vertexCountOfDrawLineInCircle:(NSInteger)divides;

@end
