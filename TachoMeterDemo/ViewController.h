//
//  ViewController.h
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/18.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "NYGLKView.h"

@interface ViewController : UIViewController

@property (nonatomic, strong) NYGLKView *tachoMeterView;
@property (nonatomic, strong) NYGLKView *secondView;

@end
