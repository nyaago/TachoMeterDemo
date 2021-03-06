//
//  ViewController.m
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/18.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import "ViewController.h"
#import "TachoMeterRenderere.h"
#import "PeakMeterRenderer.h"
#import "MyTachoMeterParameters.h"
#import "MyPeakMeterParameters.h"
@interface ViewController () {
}
@end

@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  CGRect frame = self.view.bounds;
  CGRect rect = CGRectMake(0, 0, frame.size.height / 2, frame.size.height / 2);
  _tachoMeterView = [[NYGLKView alloc] initWithFrame:rect];
  TachoMeterRenderere *renderer = [[TachoMeterRenderere alloc] initWithView:_tachoMeterView];
  _tachoMeterView.renderer = renderer;
  renderer.parameters = [[MyTachoMeterParameters alloc] init];
  [self.view addSubview:_tachoMeterView];

  rect = CGRectMake(0, frame.size.height / 2, frame.size.height / 2, frame.size.height / 2);
  _secondView = [[NYGLKView alloc] initWithFrame:rect];
  PeakMeterRenderer *renderer2 = [[PeakMeterRenderer alloc] initWithView:_secondView];
  _secondView.renderer = renderer2;
  renderer2.parameters = [[MyPeakMeterParameters alloc] init];
  
  [self.view addSubview:_secondView];

}

- (void) viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self.tachoMeterView start];
  [self.secondView start];
}

- (void) viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  [self.tachoMeterView stop];
  [self.secondView stop];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
}


@end
