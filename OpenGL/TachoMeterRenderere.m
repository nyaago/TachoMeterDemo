//
//  TachoMeterRenderere.m
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/18.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import "TachoMeterRenderere.h"
#import "ShaderLoader.h"
#import "GLShapeDrawer.h"
#import "TextImage.h"

@interface TachoMeterRenderere() {

  
  NSInteger _needlePosition;
  NSInteger _bodyPosition;
  BOOL _statusChanged;

}

//@property (strong, nonatomic) EAGLContext *context;
- (void)setupGL;

@property (nonatomic, strong) GLShapeDrawerInfo *needleInfo;
@property (nonatomic, strong) GLShapeDrawerInfo *redZoneInfo;

@end


@implementation TachoMeterRenderere

#define VERTEX_POS_SIZE  3
#define VERTEX_COLOR_SIZE  3
#define TEXCOORDS_SIZE  2

#define VERTEX_ATTRIB_SIZE 8

#define BUFFER_OFFSET(i) ((char *)NULL + (i))


- (id) initWithView:(GLKView *)view {
  self = [super init];
  if(self) {
    [self setDefault];
    self.view = view;
    self.shaderLoader = [[ShaderLoader alloc] init];
    self.textureShaderLoader = [[ShaderLoader alloc] init];
    self.shapeDrawer = [[GLShapeDrawer alloc] init];
  }
  return self;
}

#pragma mark - Properties

- (void) setActive:(BOOL)active {
  if(active != _active) {
    _statusChanged = YES;
  }
  _active = active;
}

#pragma mark -  OpenGL ES 2

- (void)setupGL
{
  [self loadShaders];
//  [self loadTextureShaders];
  self.vertexs = [[FloatArray alloc] initWithCount:[self vertexArraySize]  ];
  [self setFrameVertex];
  [self setValueVertex];
  [self setOtherVertex];
  
  self.effect = [[GLKBaseEffect alloc] init];
  self.effect.light0.enabled = GL_TRUE;
//  self.effect.light0.diffuseColor = GLKVector4Make(1.0f, 0.4f, 0.4f, 1.0f);
  
  
  glGenVertexArraysOES(1, &_vertexArray);
  glBindVertexArrayOES(_vertexArray);
  
  glGenBuffers(1, &_vertexBuffer);
  glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
//  glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
  
  glBufferData(GL_ARRAY_BUFFER,
              sizeof(float) * [self.vertexs count] , self.vertexs.array, GL_STATIC_DRAW);

  glEnableVertexAttribArray(GLKVertexAttribPosition);
  glVertexAttribPointer(GLKVertexAttribPosition, VERTEX_POS_SIZE, GL_FLOAT, GL_FALSE,
                        VERTEX_ATTRIB_SIZE * sizeof(float),
                        BUFFER_OFFSET(0));
  
  glEnableVertexAttribArray(GLKVertexAttribColor);
  glVertexAttribPointer(GLKVertexAttribColor, VERTEX_COLOR_SIZE, GL_FLOAT, GL_FALSE,
                        VERTEX_ATTRIB_SIZE * sizeof(float),
                        BUFFER_OFFSET(VERTEX_POS_SIZE * sizeof(float)));
  
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  glVertexAttribPointer(GLKVertexAttribTexCoord0, TEXCOORDS_SIZE, GL_FLOAT, GL_FALSE,
                        VERTEX_ATTRIB_SIZE * sizeof(float),
                        BUFFER_OFFSET((VERTEX_POS_SIZE + VERTEX_COLOR_SIZE) * sizeof(float)));
  
  glBindVertexArrayOES(0);
  

}

#pragma mark - GLKView  delegate methods


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
  glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  
  glBindVertexArrayOES(_vertexArray);
  
  // Render the object with GLKit
  [self.effect prepareToDraw];

  glEnable(GL_COLOR_ARRAY);
  glUseProgram(_program);
  

  // 文字
  glEnable(GL_TEXTURE_2D);
  glDisable(GL_COLOR_ARRAY);
  //  glUseProgram(_textureProgram);
  glDisableVertexAttribArray(GLKVertexAttribColor);
  glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0,
                     _modelViewProjectionMatrix.m);
  glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);

  
//  [self.shapeDrawer drawArrays];
 // glDrawArrays(GL_TRIANGLE_STRIP, 0, 36);
  
  // Render the object again with ES2
//  glDisable(GL_TEXTURE_2D);
  
  glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
  glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
  glUniform1i(glGetUniformLocation(_program, "texture"), 0);
  
//  glDrawArrays(GL_TRIANGLE_STRIP, 0, 36);

  glEnableVertexAttribArray(GLKVertexAttribColor);
  glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
  
  
  if(!_statusChanged) {
    [self.shapeDrawer drawArrays];
    [self updateValueVertex];
//    glBufferData(GL_ARRAY_BUFFER,
//                 sizeof(float) * [self.vertexs count] , self.vertexs.array, GL_STATIC_DRAW);
//    [self.shapeDrawer drawArrays];
  }
  else {
    [self setFrameVertex];
    [self setValueVertex];
    [self setOtherVertex];
    glBufferData(GL_ARRAY_BUFFER,
                 sizeof(float) * [self.vertexs count] , self.vertexs.array, GL_STATIC_DRAW);
    [self.shapeDrawer drawArrays];
  }
//  glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
  glDisableVertexAttribArray(GLKVertexAttribColor);
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  [self drawValueText];
  [self drawFrameText];
  _statusChanged = NO;
  
}



#pragma mark - Private Methods

- (void) setFrameVertex {
  glEnableClientState( GL_VERTEX_ARRAY );
  glEnableClientState( GL_COLOR_ARRAY );
  self.vertexs.position = 0;
  [self.shapeDrawer fillCircleVertex:self.vertexs x:0 y:0
                              radius:self.frameRadius divides:CIRCLE_DIVIDES
                               color:self.frameColor stride:VERTEX_ATTRIB_SIZE];
  [self.shapeDrawer fillCircleVertex:self.vertexs x:0 y:0
                              radius:self.meterRadius divides:CIRCLE_DIVIDES
                               color:self.active ? self.activeMeterColor :  self.inactiveMeterColor
                              stride:VERTEX_ATTRIB_SIZE];
  [self.shapeDrawer drawCircleVertex:self.vertexs x:0 y:0
                              radius:self.meterScaleLineRadius
                             divides:CIRCLE_DIVIDES
                           drawRatio:3.0f / 4.0f
                               color:self.largeScaleColor
                           lineWidth:self.lineWidth
                              stride:VERTEX_ATTRIB_SIZE];
  [self.shapeDrawer drawLineInCircleVertex:self.vertexs x:0 y:0
                                    radius:self.meterScaleCircleRadius
                                   divides:(self.parameters.maxValue - self.parameters.minValue)
                                            / self.parameters.scale
                                lineLength:self.scaleLength 
                                 drawRatio:3.0f / 4.0f color:self.scaleColor
                                 lineWidth:self.lineWidth
                                    stride:VERTEX_ATTRIB_SIZE];
  [self.shapeDrawer drawLineInCircleVertex:self.vertexs x:0 y:0
                                    radius:self.meterScaleLineRadius
                                   divides:(self.parameters.maxValue - self.parameters.minValue)
                                            / self.parameters.mediumScale
                                lineLength:self.medimuScaleLength
                                 drawRatio:3.0f / 4.0f color:self.scaleColor
                                 lineWidth:self.lineWidth
                                    stride:VERTEX_ATTRIB_SIZE];
  [self.shapeDrawer drawLineInCircleVertex:self.vertexs x:0 y:0
                                    radius:self.meterScaleLineRadius
                                   divides:(self.parameters.maxValue - self.parameters.minValue)
                                            / self.parameters.largeScale
                                lineLength:self.largeScaleLength
                                 drawRatio:3.0f / 4.0f color:self.scaleColor
                                 lineWidth:self.lineWidth
                                    stride:VERTEX_ATTRIB_SIZE];
  
  
}

- (void) setOtherVertex {
  [self.shapeDrawer fillCircleVertex:self.vertexs x:0 y:0
                              radius:self.centerRadius divides:CIRCLE_DIVIDES
                               color:self.centerColor stride:VERTEX_ATTRIB_SIZE];
}


- (void) setValueVertex {
 
  _needlePosition = self.vertexs.position;
  self.needleInfo = [self.shapeDrawer drawNeedleVertex:self.vertexs
                               value:[self.value integerValue]
                                   x:0 y:0
                              radius:1
                             divides:self.parameters.maxValue - self.parameters.minValue
                          lineLength:self.needLength
                          coreLength:self.needCoreLength
                           drawRatio:3.0f/4.0f
                               colors:self.needleColors
                           lineWidth:self.needleWeight
                              stride:VERTEX_ATTRIB_SIZE];
  CGFloat startRadian = [self.shapeDrawer
                         getRadianForCircleWithIndex:self.parameters.redZoneValue
                         divides:self.parameters.maxValue - self.parameters.minValue
                         drawRatio:3.0f / 4.0f];
  CGFloat endRadian = [self.shapeDrawer
                       getRadianForCircleWithIndex:self.parameters.maxValue
                       divides:self.parameters.maxValue - self.parameters.minValue
                       drawRatio:3.0f / 4.0f];
  self.redZoneInfo = [self.shapeDrawer fillTorusVertex:self.vertexs
                                  x:0 y:0
                             radius:self.meterScaleCircleRadius
                        innerRadius:self.meterScaleCircleRadius - self.scaleLength
                            divides:CIRCLE_DIVIDES
                         startAngle:startRadian
                           endAngle:endRadian
                              color:self.redColor
                             stride:VERTEX_ATTRIB_SIZE];

}

- (void) updateValueVertex {
  [self.vertexs setPosition:_needlePosition];
  [self.shapeDrawer drawNeedleVertex:self.vertexs
                               value:[self.value integerValue]
                                   x:0 y:0
                              radius:1
                             divides:self.parameters.maxValue - self.parameters.minValue
                          lineLength:self.needLength
                          coreLength:self.needCoreLength
                           drawRatio:3.0f/4.0f
                              colors:self.needleColors
                           lineWidth:self.needleWeight
                              stride:VERTEX_ATTRIB_SIZE];
  CGFloat startRadian = [self.shapeDrawer
                         getRadianForCircleWithIndex:self.parameters.redZoneValue
                         divides:self.parameters.maxValue - self.parameters.minValue
                         drawRatio:3.0f / 4.0f];
  CGFloat endRadian = [self.shapeDrawer
                       getRadianForCircleWithIndex:self.parameters.maxValue
                       divides:self.parameters.maxValue - self.parameters.minValue
                       drawRatio:3.0f / 4.0f];
  [self.shapeDrawer fillTorusVertex:self.vertexs
                                 x:0 y:0
                            radius:self.meterScaleCircleRadius
                       innerRadius:self.meterScaleCircleRadius - self.scaleLength
                           divides:CIRCLE_DIVIDES
                        startAngle:startRadian
                          endAngle:endRadian
                             color:self.redColor
                            stride:VERTEX_ATTRIB_SIZE];

  glBufferSubData(GL_ARRAY_BUFFER,
                  sizeof(float) * _needlePosition,
                  [self valueVertextCount] * VERTEX_ATTRIB_SIZE * sizeof(float),
                  self.vertexs.array + _needlePosition);
  [self.shapeDrawer drawArray:self.needleInfo];
  [self.shapeDrawer drawArray:self.redZoneInfo];
}

- (void) drawFrameText {
  
  NSInteger textPxSize = [self openGLWidthToPx:self.scaleTextSize];
  
  CGFloat textSize = [self pxWidthToOpenGLWidth:textPxSize];
  for(NSInteger v = self.parameters.minValue;
      v <= self.parameters.maxValue;
      v += self.parameters.scaleTextInterval) {
    
    CGFloat radian = [self.shapeDrawer
                      getRadianForCircleWithIndex:v
                                          divides:self.parameters.maxValue - self.parameters.minValue + 1
                                        drawRatio:3.0f / 4.0f];
    UIFont *baseFont = self.scaleTextFont;
    UIFont *font;
    if([baseFont respondsToSelector:@selector(fontDescriptor)]) {
      font = [UIFont fontWithDescriptor:[baseFont fontDescriptor] size:textPxSize];
    }
    else {
      font = [UIFont systemFontOfSize:textPxSize];
    }
    CGFloat x = [self.shapeDrawer
                 getXOfCircleWithRadian:radian
                                 radius:self.meterScaleCircleRadius - self.largeScaleLength - textSize];
    CGFloat y = [self.shapeDrawer
                 getYOfCircleWithRadian:radian
                                 radius:self.meterScaleCircleRadius - self.largeScaleLength - textSize];
    [self drawText:[self.parameters scaleText:v] x:x y:y z:0
              font:font textColor:self.scaleTextColor
   backgroundColor:[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
    
  }
  textPxSize = [self openGLWidthToPx:self.noteTextSize];
  textSize = [self pxWidthToOpenGLWidth:textPxSize];
  float radian = (float)(2.0f*M_PI * 3.0f/4.0f);
  CGFloat x = 0.0f - [self.shapeDrawer
               getXOfCircleWithRadian:radian
               radius:0.35f];
  CGFloat y = 0.0f - [self.shapeDrawer
               getYOfCircleWithRadian:radian
               radius:0.35f];
  UIFont *baseFont = self.noteTextFont;
  UIFont *font;
  if([baseFont respondsToSelector:@selector(fontDescriptor)]) {
    font = [UIFont fontWithDescriptor:[baseFont fontDescriptor] size:textPxSize];
  }
  else {
    font = [UIFont systemFontOfSize:textPxSize];
  }
  
  [self drawText:self.noteText  x:x y:y z:0
            font:font textColor:self.noteTextColor
   backgroundColor:[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.0f]];
}

- (void) drawValueText {
  NSInteger textPxSize = [self openGLWidthToPx:self.valueTextSize];
  float radian = (float)(2.0f*M_PI * 3.0f/4.0f);
  CGFloat x = [self.shapeDrawer
               getXOfCircleWithRadian:radian
               radius:0.6f];
  CGFloat y = [self.shapeDrawer
               getYOfCircleWithRadian:radian
               radius:0.6f];
  UIFont *baseFont = self.valueTextFont;
  UIFont *font;
  if([baseFont respondsToSelector:@selector(fontDescriptor)]) {
    font = [UIFont fontWithDescriptor:[baseFont fontDescriptor] size:textPxSize];
  }
  else {
    font = [UIFont systemFontOfSize:textPxSize];
  }

  NSString *s = nil;
  NSInteger max = self.parameters.maxValue;
  NSString *format = [NSString stringWithFormat:@"%%%dd", (int)log10((double)max) + 1];
  if(self.value != nil) {
    s = [NSString stringWithFormat:format, [self.value integerValue]];
  }
  else {
    s = [NSString stringWithFormat:format, 0];
  }
  [self drawValueText:s x:x y:y z:0
            font:font textColor:self.valueTextColor backgroundColor:self.valueBackgroundColor];
}


/*!
 * 指定したテキストを描画する
 * @param gl
 * @param text 描画テキスト
 * @param x 描画位置-openglの座標 -x
 * @param y 描画位置-openglの座標 -y
 * @param z 描画位置-openglの座標 -z
 * @param font フォント
 * @param pointLeft 指定座標を文字出力の左側で行うならtrue
 * @param pointBottom 指定座標を文字出力のBottom側で行うならtrue
 */
- (void) drawValueText:(NSString *)text x:(CGFloat)x y:(CGFloat)y z:(CGFloat)z
             font:(UIFont *)font textColor:(UIColor *)textColor
  backgroundColor:(UIColor *)backgroundColor
{
  
  float margin = 0.0f;
  // テキストのビットマップを生成してOpenGLへ
  TextImage *textImage = [[TextImage alloc] init];
  textImage.font = font;
  textImage.color = textColor;
  textImage.backgroundColor = backgroundColor;
  CGSize size = [textImage textSize:text];
//  CGFloat tw = [textImage textWidth:text];
  Byte *pixels =  [textImage drawStringToTexture:text];
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, size.width, size.height, 0,
               GL_RGBA, GL_UNSIGNED_BYTE, pixels);
  //
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glEnable(GL_BLEND);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  
  NSInteger bmpWidth = [textImage textSize:text].width;
  NSInteger strWidth = [textImage textWidth:text];
  float w = [self pxWidthToOpenGLWidth:strWidth];
  float textWidth = [self pxWidthToOpenGLWidth:strWidth];
  float h = [self pxHeightToOpenGLHeight:font.lineHeight * (1.0f + margin) ];
  float left = x - (textWidth / 2);
  float right = left + w;
  float bottom = y - (h / 2);
  float top = bottom + h;
  float  vertex [] =  {
    left, top, z,
    left, bottom, z,
    right, top, z,
    right, bottom, z
  };
  float  uv[] = {
    0.0f, 1.0f,
    0.0f, ((float)(bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
    ((float)strWidth / (float)bmpWidth), 1.0f,
    ((float)strWidth / (float)bmpWidth), ((float)((float)bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
  
  };
  //頂点配列の指定
  NSInteger pos =[self texturePositionInValueVertex] * VERTEX_ATTRIB_SIZE ;
  self.vertexs.position = [self texturePositionInValueVertex] * VERTEX_ATTRIB_SIZE ;
  for(int i = 0; i < 4; ++i) {
    [self.vertexs putValue:vertex[i * 3]];
    [self.vertexs putValue:vertex[i * 3 + 1]];
    [self.vertexs putValue:vertex[i * 3 + 2]];
    [self.vertexs advancePosition:VERTEX_COLOR_SIZE];
    [self.vertexs putValue:uv[i*2]];
    [self.vertexs putValue:uv[i*2+1]];
  }
  
  glBufferSubData(GL_ARRAY_BUFFER,
                  sizeof(float) * pos,
                  4 * VERTEX_ATTRIB_SIZE * sizeof(float),
                  self.vertexs.array + ( [self texturePositionInValueVertex] * VERTEX_ATTRIB_SIZE));
  //
  glDrawArrays(GL_TRIANGLE_STRIP, [self texturePositionInValueVertex], 4);
  [textImage releaseImage];
  
}


- (void) setDefault {
  
  self.frameRadius = 1.0f;
  self.meterRadius = 0.96f;
  self.meterScaleCircleRadius = 0.94;
  self.meterScaleLineRadius = 0.87f;
  self.centerRadius = 0.15f;
  
  self.frameColor = [[GLColor alloc] initWithRed:191.0/255.0 green:191.0/255 blue:191.0/255];
  self.activeMeterColor = [[GLColor alloc] initWithRed:255 green:255 blue:255];
  self.inactiveMeterColor = [[GLColor alloc] initWithRed:127.0/255.0 green:127.0/255.0 blue:127/255.0];
  self.centerColor = [[GLColor alloc] initWithRed:31.0f/255.0 green:31.0/255.0 blue:31.0/255.0];
  self.scaleColor = [[GLColor alloc] initWithRed:31.0f/255.0 green:31.0f/255.0 blue:31.0f/255.0];
  self.largeScaleColor = [[GLColor alloc] initWithRed:255.0/255.0 green:0/255.0 blue:0/255.0];
  self.redColor = [[GLColor alloc] initWithRed:255.0/255.0 green:0 blue:0];
  
  self.lineWidth = 1.0f;
  
  self.scaleLength = 0.04f;
  self.medimuScaleLength = 0.04f;
  self.largeScaleLength = 0.1f;
  
  self.scaleTextSize = 0.15f;
  self.valueTextSize = 0.20f;
  self.noteTextSize = 0.15f;
  
  self.scaleTextColor = [UIColor blackColor];
  self.valueTextColor = [UIColor whiteColor];
  self.noteTextColor = [UIColor blackColor];
  
  self.scaleTextFont = [UIFont systemFontOfSize:14];
  self.noteTextFont = [UIFont systemFontOfSize:14];
  self.valueTextFont = [UIFont fontWithName:@"Verdana-Italic" size:15];
  
  self.needleWeight = 0.1f;
  self.needLength = 0.85f;
  self.needCoreLength = 0.25f;
  self.needleColors = [NSArray arrayWithObjects:
                       [[GLColor alloc] initWithRed:255.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f],
                       [[GLColor alloc] initWithRed:255.0f/255.0f green:165.0f/255.0f blue:0.0f/255.0f],
                       [[GLColor alloc] initWithRed:255.0f/255.0f green:0.0f/255.0f blue:0.0f/255.0f],
                       nil];
  
  self.noteText = @"note";
  self.value = [NSNumber numberWithInt:0];
  self.valueBackgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
}




- (NSInteger) vertexArraySize {
  return [self vertexCount] * VERTEX_ATTRIB_SIZE;
}

- (NSInteger) vertexCount {
  return [self frameVertextCount]
  + [self valueVertextCount]
  + 4 // texture
  + 0  // @TODO -
  ;
}

- (NSInteger) frameVertextCount {
  
  return [self.shapeDrawer vertexCountOfFillCircle:CIRCLE_DIVIDES] * 3
  + [self.shapeDrawer vertexCountOfDrawCircle:CIRCLE_DIVIDES]
  + [self.shapeDrawer vertexCountOfDrawLineInCircle:
     (self.parameters.maxValue - self.parameters.minValue) / self.parameters.scale ]
  + [self.shapeDrawer vertexCountOfDrawLineInCircle:
     (self.parameters.maxValue - self.parameters.minValue) / self.parameters.mediumScale ]
  + [self.shapeDrawer vertexCountOfDrawLineInCircle:
     (self.parameters.maxValue - self.parameters.minValue) / self.parameters.largeScale];
  
}

- (NSInteger) valueVertextCount {
  CGFloat startRadian = [self.shapeDrawer
                         getRadianForCircleWithIndex:self.parameters.redZoneValue
                         divides:self.parameters.maxValue - self.parameters.minValue
                         drawRatio:3.0f / 4.0f];
  CGFloat endRadian = [self.shapeDrawer
                       getRadianForCircleWithIndex:self.parameters.maxValue
                       divides:self.parameters.maxValue - self.parameters.minValue
                       drawRatio:3.0f / 4.0f];
  return  [self.shapeDrawer vertexCountOfFillTorusWithDivides:CIRCLE_DIVIDES
                                             startAngle:startRadian endAngle:endRadian]
  + [self.shapeDrawer vertexCOuntOfFillTriangle];
}



/*!
 *
 * @return 値描画のための頂点数
 */
-(NSInteger) texturePositionInValueVertex {
  //
  return [self frameVertextCount] + [self valueVertextCount];
}



@end
