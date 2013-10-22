//
//  MyPeakMeterParameters.m
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/22.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import "MyPeakMeterParameters.h"

@implementation MyPeakMeterParameters

-(NSInteger) maxValue {
  return 100;
}
-(NSInteger) minValue {
  return 0;
}
-(NSInteger) scale {
  return 1;
}

-(NSInteger) scaleTextInterval {
  return 20;
}

- (NSString *) scaleText:(NSInteger) value {
  return [NSString stringWithFormat:@"%d", value];
}


@end
