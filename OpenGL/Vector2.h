//
//  Vector4.h
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/19.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Vector2 : NSObject

@property (nonatomic) CGFloat x;
@property (nonatomic) CGFloat y;
@property (nonatomic) CGFloat z;

- (id) initWithX:(CGFloat)x y:(CGFloat)y ;

/*!
 * 移動行列演算
 */
- (Vector2 *) translate:(Vector2 *)vec;

/*!
 * 移動行列演算
 */
- (Vector2 *) translateX:(CGFloat)x y:(CGFloat)y;

/*!
 * 回転行列演算
 */
- (Vector2 *) rotate:(CGFloat)degree;

/*!
 * @return XYZの３要素配列で返す
 */
- (CGFloat *) xyz;


@end
