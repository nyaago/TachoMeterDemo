//
//  Vector4.m
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/19.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import "Vector2.h"

@interface Vector2() {
  float _xyz[3];
}

@end

@implementation Vector2

- (id) initWithX:(float)x y:(float)y  {
  self = [super init];
  if(self) {
    _x = x;
    _y = y;
    _z = 0;
  }
  return self;
}

- (Vector2 *) translate:(Vector2 *)vec  {
  return [[Vector2 alloc] initWithX:self.x + vec.x y:self.y + vec.y];
}

- (Vector2 *) translateX:(float)x y:(float)y {
  return [[Vector2 alloc] initWithX:self.x + x y:self.y + y];
}

- (Vector2 *) rotate:(float)degree {
  return [[Vector2 alloc] initWithX:self.x * cos(degree) - self.y * sin(degree)
                                  y:self.x * sin(degree) + self.y * cos(degree)];
}

- (float  *) xyz {
  _xyz[0] = self.x;
  _xyz[1] = self.y;
  _xyz[2] = self.z;
  return _xyz;
}

@end
