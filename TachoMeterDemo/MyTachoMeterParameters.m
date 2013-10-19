//
//  MyTachoMeterParameters.m
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/19.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import "MyTachoMeterParameters.h"

@implementation MyTachoMeterParameters

-(NSInteger) maxValue {
  return 14000;
}
-(NSInteger) minValue {
  return 0;
}
-(NSInteger) scale {
  return [self largeScale] / 5;
}
-(NSInteger) largeScale {
  return 1000;
}
-(NSInteger) mediumScale {
  return [self largeScale] / 2;

}
-(NSInteger) redZoneValue {
  return 10000;
}
-(NSInteger) scaleTextInterval {
  return [self largeScale];
}

- (NSString *) scaleText:(NSInteger) value {
  return [NSString stringWithFormat:@"%d", value / 1000];
}


@end
