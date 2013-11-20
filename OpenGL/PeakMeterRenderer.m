//
//  PeakMeterRenderer.m
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/21.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import "PeakMeterRenderer.h"
#import "ShaderLoader.h"
#import "GLShapeDrawer.h"
#import "TextImage.h"

@interface PeakMeterRenderer() {
  
  
}

//@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;

@end

@implementation PeakMeterRenderer


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

#pragma mark -  OpenGL ES 2

- (void)setupGL
{
//  [self loadTextureShaders];
  [self loadShaders];
  self.vertexs = [[FloatArray alloc] initWithCount:[self vertexArraySize]];
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
               sizeof(CGFloat) * [self.vertexs count] , self.vertexs.array, GL_STATIC_DRAW);
  
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  glVertexAttribPointer(GLKVertexAttribPosition, VERTEX_POS_SIZE, GL_FLOAT, GL_FALSE,
                        VERTEX_ATTRIB_SIZE * sizeof(GLfloat),
                        BUFFER_OFFSET(0));
  
  glEnableVertexAttribArray(GLKVertexAttribColor);
  glVertexAttribPointer(GLKVertexAttribColor, VERTEX_COLOR_SIZE, GL_FLOAT, GL_FALSE,
                        VERTEX_ATTRIB_SIZE * sizeof(GLfloat),
                        BUFFER_OFFSET(VERTEX_POS_SIZE * sizeof(GLfloat)));
  
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  glVertexAttribPointer(GLKVertexAttribTexCoord0, TEXCOORDS_SIZE, GL_FLOAT, GL_FALSE,
                        VERTEX_ATTRIB_SIZE * sizeof(GLfloat),
                        BUFFER_OFFSET((VERTEX_POS_SIZE + VERTEX_COLOR_SIZE) * sizeof(GLfloat)));
  
  glBindVertexArrayOES(0);
}

- (void)update
{
  GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(0.0f, self.aspect, 0.0f, 1.0f, -100, 100);
  self.effect.transform.projectionMatrix = projectionMatrix;
  
  GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -4.0f);
  //  baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
  
  // Compute the model view matrix for the object rendered with GLKit
  GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, -1.5f);
  //  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
  modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
  
  self.effect.transform.modelviewMatrix = modelViewMatrix;
  
  // Compute the model view matrix for the object rendered with ES2
  modelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 1.5f);
  //  modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 1.0f, 1.0f, 1.0f);
  modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, modelViewMatrix);
  
  _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(modelViewMatrix), NULL);
  
  _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix);
  
}



#pragma mark - GLKView  delegate methods


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
  [self setValueVertex];
  [self setOtherVertex];
  glBufferSubData(GL_ARRAY_BUFFER,
                  [self valueVertexOffset] * VERTEX_ATTRIB_SIZE * sizeof(CGFloat) ,
                  [self valueVertextCount] * VERTEX_ATTRIB_SIZE * sizeof(CGFloat),
                  self.vertexs.array + [self valueVertexOffset] * VERTEX_ATTRIB_SIZE);
  glBufferSubData(GL_ARRAY_BUFFER,
                  [self otherVertexOffset] * VERTEX_ATTRIB_SIZE * sizeof(CGFloat) ,
                  [self otherVertextCount] * VERTEX_ATTRIB_SIZE * sizeof(CGFloat),
                  self.vertexs.array + [self otherVertexOffset] * VERTEX_ATTRIB_SIZE);

  glClearColor(0.3f, 0.3f, 0.3f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  
  glBindVertexArrayOES(_vertexArray);
  
  // Render the object with GLKit
  [self.effect prepareToDraw];
  
  //  [self.shapeDrawer drawArrays];
  // glDrawArrays(GL_TRIANGLE_STRIP, 0, 36);
  
  // Render the object again with ES2
  //  glDisable(GL_TEXTURE_2D);
  glEnable(GL_COLOR_ARRAY);
  glUseProgram(_program);
  glEnableVertexAttribArray(GLKVertexAttribPosition);
  glEnableVertexAttribArray(GLKVertexAttribColor);
  
  glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
  glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
  
//    glDrawArrays(GL_TRIANGLE_STRIP, 0, 10);
  [self.shapeDrawer drawArrays];
  
  // 文字
  
  glEnable(GL_TEXTURE_2D);
  glDisable(GL_COLOR_ARRAY);
//  glUseProgram(_textureProgram);
  glDisableVertexAttribArray(GLKVertexAttribColor);
  glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0,
                     _modelViewProjectionMatrix.m);
  glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
  glUniform1i(glGetUniformLocation(_program, "texture"), 0);
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  [self drawFrameText];
//  [self drawValueText];
}

- (void) setFrameVertex {
  glEnableClientState( GL_VERTEX_ARRAY );
  glEnableClientState( GL_COLOR_ARRAY );

  [self.shapeDrawer fillRectangle:self.vertexs
                             left:[self left]
                              top:[self topOfRectangle]
                            right:[self right]
                           bottom:[self bottomOfRectanhle]
                            color:self.frameColor
                           stride:VERTEX_ATTRIB_SIZE];
  
  // 上のtriangle
  [self.shapeDrawer fillTriangle:self.vertexs
                          point1:CGPointMake([self left], [self bottomOfUpperTriangle])
                          point2:CGPointMake([self right], [self topOfMeter])
                          point3:CGPointMake([self right], [self bottomOfUpperTriangle])
                           color:self. frameColor
                          stride:VERTEX_ATTRIB_SIZE];
  // 下のtriangle
  [self.shapeDrawer fillTriangle:self.vertexs
                          point1:CGPointMake([self left], [self topOfLowerTriangle])
                          point2:CGPointMake([self right], [self topOfLowerTriangle])
                          point3:CGPointMake([self right], [self bottomOfMeter])
                           color:self.frameColor
                          stride:VERTEX_ATTRIB_SIZE];

}

- (void) setOtherVertex {
  static CGFloat scales[] = {0.25f, 0.5f, 0.75f};
  [self.vertexs setPosition:[self otherVertexOffset] * VERTEX_ATTRIB_SIZE];
  for(int i = 0; i < sizeof(scales) / sizeof(CGFloat); ++i) {
    CGFloat p = scales[i];
    [self.shapeDrawer drawLineVertex:self.vertexs
                               start:CGPointMake([self x:p], [self topOfMeter:p])
                                 end:CGPointMake([self x:p], [self bottomOfMeter:p])
                               color:self.scaleColor
                           lineWidth:self.scaleWeight
                              stride:VERTEX_ATTRIB_SIZE];
  }
}


- (void) setValueVertex {
  
  [self.vertexs setPosition:[self valueVertexOffset] * VERTEX_ATTRIB_SIZE];
  CGFloat ratio = (CGFloat)self.value
  / (CGFloat)(self.parameters.maxValue - self.parameters.minValue);
  
  
  [self.shapeDrawer fillRectangle:self.vertexs
                             left:[self left]
                              top:[self topOfRectangle]
                            right:[self right:ratio]
                           bottom:[self bottomOfRectanhle]
                            color:self.valueColor
                           stride:VERTEX_ATTRIB_SIZE];
  
  // 上のtriangle
  [self.shapeDrawer fillTriangle:self.vertexs
                          point1:CGPointMake([self left], [self bottomOfUpperTriangle])
                          point2:CGPointMake([self right:ratio], [self topOfMeter:ratio])
                          point3:CGPointMake([self right:ratio], [self bottomOfUpperTriangle])
                           color:self. valueColor
                          stride:VERTEX_ATTRIB_SIZE];
  // 下のtriangle
  [self.shapeDrawer fillTriangle:self.vertexs
                          point1:CGPointMake([self left], [self topOfLowerTriangle])
                          point2:CGPointMake([self right:ratio], [self topOfLowerTriangle])
                          point3:CGPointMake([self right:ratio], [self bottomOfMeter:ratio])
                           color:self.valueColor
                          stride:VERTEX_ATTRIB_SIZE];
  // Scale
  

}

- (void) drawFrameText {
  static CGFloat scalesForText[] = {0.0f, 0.5f, 1.0f};
  UIFont *font;
  if([self.scaleTextFont respondsToSelector:@selector(fontDescriptor)]) {
    font = [UIFont fontWithDescriptor:[self.scaleTextFont fontDescriptor] size:self.scaleTextSize];
  }
  else {
    font = [UIFont systemFontOfSize:self.scaleTextSize];
  }
  
  for(int i = 0; i < sizeof(scalesForText) / sizeof(CGFloat); ++i) {
    CGFloat p = scalesForText[i];
    NSInteger value = (NSInteger)((self.parameters.maxValue - self.parameters.minValue) * p)
                      + self.parameters.minValue;
    
    CGFloat m = 0.0f;
    NSString *text = [NSString stringWithFormat:@"%d", value];
    TextImage *textImage;
    CGFloat h = + [self pxHeightToOpenGLHeight:self.scaleTextSize] / 2;
    if(p == 1.0f) {     // 一番右の目盛り、中央配置すると右半分がはみ出るので
      textImage = [[TextImage alloc] init];
      textImage.font = font;
      m = 0.0f - [self pxWidthToOpenGLWidth:[textImage textWidth:text]] / 2;
    }
    else if(p == 0.0f) {// 一番左の目盛り、中央配置すると左半分がはみ出るので
      textImage = [[TextImage alloc] init];
      textImage.font = font;
      m = [self pxWidthToOpenGLWidth:[textImage textWidth:text]] / 2;
    }
    [self drawText:text
                 x:[self x:p] + m y:[self topOfMeter:p] + h z:0
              font:font
         textColor:self.scaleTextColor
   backgroundColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.0f]];
    
  }

 
}

- (void) setDefault {
  self.frameColor = [[GLColor alloc] initWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f];
  self.scaleTextColor =  [UIColor colorWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
  self.valueColor =[[GLColor alloc] initWithRed:255.0f/255.0f green:153.0f/255.0f blue:0.0f/255.0f];
  self.meterColor = [[GLColor alloc] initWithRed:255.0f/255.0f green:255.0f/255.0f blue:255.0f/255.0f];
  self.scaleColor = [[GLColor alloc] initWithRed:106.0f/255.0f green:106.0f/255.0f blue:106.0f/255.0f];
  
  self.scaleTextSize = 20;
  self.scaleLength = 0.08f;
  self.scaleWeight = 5;

  self.meterTop = 0.7f;
  self.meterBottom = 0.0f;
  self.ratioMeterTriangle  = 0.15f;
  self.meterLeft = 0.0f;
  self.meterRight = 1.0f;
  
  self.scaleTextFont = [UIFont systemFontOfSize:14];
  
  self.value = 40;
}

- (NSInteger) vertexArraySize {
  return [self vertexCount] * VERTEX_ATTRIB_SIZE;
}

- (NSInteger) vertexCount {
  return [self frameVertextCount]
  + [self valueVertextCount]
  + [self otherVertextCount]
  + 4; // Textrure
}

- (NSInteger) valueVertexOffset {
  return [self valueVertextCount];
}

- (NSInteger) otherVertexOffset {
  return [self valueVertextCount] + [self valueVertextCount];
}

- (NSInteger) frameVertextCount {
  return [self.shapeDrawer vertexCOuntOfFillRectangle]
  + [self.shapeDrawer vertexCOuntOfFillTriangle] * 2;
}

- (NSInteger) otherVertextCount {
  return 2 * 3;  // scale
}

- (NSInteger) valueVertextCount {
  return [self.shapeDrawer vertexCOuntOfFillRectangle]
  + [self.shapeDrawer vertexCOuntOfFillTriangle] * 2;
}

/*!
 *
 * @return 値描画のための頂点数
 */
-(NSInteger) texturePositionInValueVertex {
  //
  return [self frameVertextCount]
  + [self valueVertextCount];
}


#pragma mark - Inherited From MeterRenderere

/*!
 * 幅のpx値からのopenGL座標の大きさへ変換
 * @param px 幅のpx値
 * @return openGL座標での大きさ
 */
- (CGFloat) pxWidthToOpenGLWidth:(CGFloat) px {
  return [self aspect] * 1.0f / (float)[self width] * px;
}

/*!
 * 高さのpx値からのopenGL座標の大きさへ変換
 * @param px 高さのpx値
 * @return  openGL座標での大きさ
 */
- (CGFloat) pxHeightToOpenGLHeight:(CGFloat) px {
  return (1.0f / (float)[self height]) * px;
}


#pragma mark - Private Funtion

- (CGFloat) topOfMeter {
  return self.meterTop;
}

- (CGFloat) bottomOfMeter {
  return self.meterBottom;
}

- (CGFloat) topOfRectangle {
  return [self bottomOfUpperTriangle];
}

- (CGFloat) bottomOfRectanhle {
  return [self topOfLowerTriangle];
}

- (CGFloat) bottomOfUpperTriangle {
  return [self topOfMeter] - self.ratioMeterTriangle;
}

- (CGFloat) topOfLowerTriangle {
  return [self bottomOfMeter] + self.ratioMeterTriangle;
}

- (CGFloat) right {
  return [self left] + self.aspect * (self.meterRight - self.meterLeft);
}

- (CGFloat) left {
  return self.meterLeft * self.aspect;
}

- (CGFloat) x:(CGFloat)ratio {
  return [self left] + (self.meterRight - self.meterLeft) * ratio * self.aspect;
}

- (CGFloat) right:(CGFloat)ratio {
  return [self x:ratio];
}


- (CGFloat) topOfMeter:(CGFloat) ratio {
  return  [self topOfMeter] - (self.ratioMeterTriangle * (1.0f - ratio));
}

- (CGFloat) bottomOfMeter:(CGFloat) ratio {
  return [self bottomOfMeter] + (self.ratioMeterTriangle * (1.0f - ratio));
}

- (CGFloat) scale:(CGFloat)ratio {
  return ([self right] -  [self left]) * ratio;
}


@end
