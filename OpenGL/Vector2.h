//
//  Vector4.h
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/19.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Vector2 : NSObject

@property (nonatomic) float x;
@property (nonatomic) float y;
@property (nonatomic) float z;

- (id) initWithX:(float)x y:(float)y ;

/*!
 * 移動行列演算
 */
- (Vector2 *) translate:(Vector2 *)vec;

/*!
 * 移動行列演算
 */
- (Vector2 *) translateX:(float)x y:(float)y;

/*!
 * 回転行列演算
 */
- (Vector2 *) rotate:(float)degree;

/*!
 * @return XYZの３要素配列で返す
 */
- (float *) xyz;


@end
