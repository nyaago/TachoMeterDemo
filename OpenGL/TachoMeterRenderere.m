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

GLuint _program;
GLuint _textureProgram;

GLKMatrix4 _modelViewProjectionMatrix;
GLKMatrix3 _normalMatrix;
float _rotation;

GLuint _vertexArray;
GLuint _vertexBuffer;
  
NSInteger _needlePosition;

}

//@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, readonly) NSTimeInterval timeSinceLastUpdate;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) ShaderLoader *shaderLoader;
@property (nonatomic, strong) ShaderLoader *textureShaderLoader;
@property (nonatomic, strong) GLShapeDrawer *shapeDrawer;
@property (nonatomic, strong) FloatArray *vertexs;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;

@end

@implementation TachoMeterRenderere

#define VERTEX_POS_SIZE  3
#define VERTEX_COLOR_SIZE  3
#define TEXCOORDS_SIZE  2

#define VERTEX_ATTRIB_SIZE 8

#define BUFFER_OFFSET(i) ((char *)NULL + (i))
#define CIRCLE_DIVIDES 250

// Uniform index.
enum
{
  UNIFORM_MODELVIEWPROJECTION_MATRIX,
  UNIFORM_NORMAL_MATRIX,
  UNIFORM_TEXTURE,
  NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Attribute index.
enum
{
  ATTRIB_VERTEX,
  ATTRIB_NORMAL,
  NUM_ATTRIBUTES
};

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
  [self loadShaders];
  [self loadTextureShaders];
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
              sizeof(CGFloat) * [_vertexs count] , _vertexs.array, GL_STATIC_DRAW);

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

- (void)tearDownGL
{
  glDeleteBuffers(1, &_vertexBuffer);
  glDeleteVertexArraysOES(1, &_vertexArray);
  
  self.effect = nil;
  
  if (_program) {
    glDeleteProgram(_program);
    _program = 0;
  }
}


- (void)update
{
  float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
  GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
  
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
  
//  _rotation += self.timeSinceLastUpdate * 0.5f;
  
  _lastUpdated = [NSDate date];
}

#pragma mark - GLKView  delegate methods


- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
  glClearColor(0.65f, 0.65f, 0.65f, 1.0f);
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
  glEnableVertexAttribArray(GLKVertexAttribColor);
  
  glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
  glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
  
//  glDrawArrays(GL_TRIANGLE_STRIP, 0, 36);
  [self updateValueVertex];
  [self.shapeDrawer drawArrays];
  
  // 文字
  glEnable(GL_TEXTURE_2D);
  glDisable(GL_COLOR_ARRAY);
  glUseProgram(_textureProgram);
  glDisableVertexAttribArray(GLKVertexAttribColor);
  glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0,
                     _modelViewProjectionMatrix.m);
  glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
  glUniform1i(glGetUniformLocation(_textureProgram, "texture"), 0);
  glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
  [self drawFrameText];
  [self drawValueText];
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
  // Create shader program.
  _program = [self.shaderLoader loadShaders:@"Shader"];
  // Bind attribute locations.
  // This needs to be done prior to linking.
  glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
//  glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
  glBindAttribLocation(_program, GLKVertexAttribColor, "color");

  // Link program.
  if (![self.shaderLoader linkProgram]) {
    NSLog(@"Failed to link program: %d", self.shaderLoader.program);
    return NO;
  }
  
  // Get uniform locations.
  uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
  uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
  
  // Release vertex and fragment shaders.
  [self.shaderLoader releaseShaders];
  return YES;
}

- (BOOL)loadTextureShaders
{
  // Create shader program.
  _textureProgram = [self.textureShaderLoader loadShaders:@"TextureShader"];
  // Bind attribute locations.
  // This needs to be done prior to linking.
  glBindAttribLocation(_textureProgram, GLKVertexAttribPosition, "position");
//  glBindAttribLocation(_textureProgram, GLKVertexAttribNormal, "normal");
  glBindAttribLocation(_textureProgram, GLKVertexAttribTexCoord0, "texcoord");

  // Link program.
  if (![self.textureShaderLoader linkProgram]) {
    NSLog(@"Failed to link program: %d", self.shaderLoader.program);
    return NO;
  }
  
  // Get uniform locations.
  uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_textureProgram, "modelViewProjectionMatrix");
  uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_textureProgram, "normalMatrix");
  
  // Release vertex and fragment shaders.
  [self.textureShaderLoader releaseShaders];
  return YES;
}


#pragma mark Private Properties

- (NSTimeInterval) timeSinceLastUpdate {
  return (- 0 - [self.lastUpdated timeIntervalSinceNow]);
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
                               color:self.inactiveMeterColor stride:VERTEX_ATTRIB_SIZE];
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
                            divides:200
                         startAngle:startRadian
                           endAngle:endRadian
                              color:self.redColor
                             stride:VERTEX_ATTRIB_SIZE];
  
}

- (void) setOtherVertex {
  [self.shapeDrawer fillCircleVertex:self.vertexs x:0 y:0
                              radius:self.centerRadius divides:CIRCLE_DIVIDES
                               color:self.centerColor stride:VERTEX_ATTRIB_SIZE];
}


- (void) setValueVertex {
 
  _needlePosition = self.vertexs.position;
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
}

- (void) updateValueVertex {
  [self.vertexs setPosition:_needlePosition];
  [self.shapeDrawer drawNeedleVertexUpdate:self.vertexs
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
  glBufferSubData(GL_ARRAY_BUFFER,
                  sizeof(CGFloat) * _needlePosition,
                  4 * VERTEX_ATTRIB_SIZE * sizeof(CGFloat),
                  _vertexs.array + _needlePosition);

  
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
    UIFont *font = [UIFont fontWithDescriptor:[baseFont fontDescriptor] size:textPxSize];
    CGFloat x = [self.shapeDrawer
                 getXOfCircleWithRadian:radian
                                 radius:self.meterScaleCircleRadius - self.largeScaleLength - textSize];
    CGFloat y = [self.shapeDrawer
                 getYOfCircleWithRadian:radian
                                 radius:self.meterScaleCircleRadius - self.largeScaleLength - textSize];
    [self drawText:[self.parameters scaleText:v] x:x y:y z:0
              font:font textColor:self.scaleTextColor
   backgroundColor:[UIColor clearColor]];

    
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
  UIFont *font = [UIFont fontWithDescriptor:[baseFont fontDescriptor] size:textPxSize];
  [self drawText:self.noteText  x:x y:y z:0
            font:font textColor:self.noteTextColor
   backgroundColor:[UIColor clearColor]];
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
  UIFont *font = [UIFont fontWithDescriptor:[baseFont fontDescriptor] size:textPxSize];
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
- (void) drawText:(NSString *)text x:(CGFloat)x y:(CGFloat)y z:(CGFloat)z
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
  CGFloat tw = [textImage textWidth:text];
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
  float w = [self pxWidthToOpenGLWidth:bmpWidth];
  float textWidth = [self pxWidthToOpenGLWidth:tw];
  float h = [self pxHeightToOpenGLHeight:font.lineHeight * (1.0f + margin) ];
   float left = x - (textWidth / 2);
  float right = left + w;
  float bottom = bottom = y - (h / 2);
  float top = bottom + h;
  CGFloat  vertex [] =  {
    left, top, z,
    left, bottom, z,
    right, top, z,
    right, bottom, z
  };
  CGFloat  uv[] = {
    0.0f, 1.0f,
    0.0f, ((float)(bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
    1.0f, 1.0f,
    1.0f, ((float)(bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
  };
  //頂点配列の指定
  NSInteger pos =[self texturePositionInValueVertex] * VERTEX_ATTRIB_SIZE ;
  _vertexs.position = [self texturePositionInValueVertex] * VERTEX_ATTRIB_SIZE ;
  for(int i = 0; i < 4; ++i) {
    [_vertexs putValue:vertex[i * 3]];
    [_vertexs putValue:vertex[i * 3 + 1]];
    [_vertexs putValue:vertex[i * 3 + 2]];
    [_vertexs advancePosition:VERTEX_COLOR_SIZE];
    [_vertexs putValue:uv[i*2]];
    [_vertexs putValue:uv[i*2+1]];
  }
  
  glBufferSubData(GL_ARRAY_BUFFER,
                  sizeof(CGFloat) * pos,
                  4 * VERTEX_ATTRIB_SIZE * sizeof(CGFloat),
                  _vertexs.array + ( [self texturePositionInValueVertex] * VERTEX_ATTRIB_SIZE));
  //
  glDrawArrays(GL_TRIANGLE_STRIP, [self texturePositionInValueVertex], 4);
  [textImage releaseImage];
  
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
  CGFloat  vertex [] =  {
    left, top, z,
    left, bottom, z,
    right, top, z,
    right, bottom, z
  };
  /*
  CGFloat  uv[] = {
    0.0f, 1.0f,
    0.0f, ((float)(bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
    1.0f, 1.0f,
    1.0f, ((float)(bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
  };
   */
  CGFloat  uv[] = {
    0.0f, 1.0f,
    0.0f, ((float)(bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
    ((float)strWidth / (float)bmpWidth), 1.0f,
    ((float)strWidth / (float)bmpWidth), ((float)((float)bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
  
  };
  /*
  CGFloat  uv[] = {
    1.0f - ((float)strWidth / (float)bmpWidth), 1.0f,
    1.0f - ((float)strWidth / (float)bmpWidth), ((float)(bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
    1.0f, 1.0f,
    1.0f, ((float)((float)bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
  };
   */
  /*
  CGFloat  uv[] = {
    1.0f - ((float)strWidth / (float)bmpWidth), 1.0f,
    1.0f - ((float)strWidth / (float)bmpWidth), ((float)(bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
    1.0f, 1.0f,
    1.0f, ((float)((float)bmpWidth - font.lineHeight * (1.0f + margin)) / bmpWidth),
  };
   */
  //頂点配列の指定
  NSInteger pos =[self texturePositionInValueVertex] * VERTEX_ATTRIB_SIZE ;
  _vertexs.position = [self texturePositionInValueVertex] * VERTEX_ATTRIB_SIZE ;
  for(int i = 0; i < 4; ++i) {
    [_vertexs putValue:vertex[i * 3]];
    [_vertexs putValue:vertex[i * 3 + 1]];
    [_vertexs putValue:vertex[i * 3 + 2]];
    [_vertexs advancePosition:VERTEX_COLOR_SIZE];
    [_vertexs putValue:uv[i*2]];
    [_vertexs putValue:uv[i*2+1]];
  }
  
  glBufferSubData(GL_ARRAY_BUFFER,
                  sizeof(CGFloat) * pos,
                  4 * VERTEX_ATTRIB_SIZE * sizeof(CGFloat),
                  _vertexs.array + ( [self texturePositionInValueVertex] * VERTEX_ATTRIB_SIZE));
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
  self.scaleColor = [[GLColor alloc] initWithRed:0 green:0 blue:0];
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
  self.value = [NSNumber numberWithInt:4000];
  self.valueBackgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f];
}


#pragma mark Private Functions


- (NSInteger) width {
  return self.view.bounds.size.width;
}

- (NSInteger) height {
  return self.view.bounds.size.height;
}

- (CGFloat) aspect {
  return fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
}


- (NSInteger) vertexArraySize {
  return [self vertexCount] * VERTEX_ATTRIB_SIZE;
}

- (NSInteger) vertexCount {
  return [self frameVertextCount]
  + 3  // 針
  + 4;  // texture
}

- (NSInteger) frameVertextCount {
  
  CGFloat startRadian = [self.shapeDrawer
                    getRadianForCircleWithIndex:self.parameters.redZoneValue
                    divides:self.parameters.maxValue - self.parameters.minValue
                    drawRatio:3.0f / 4.0f];
  CGFloat endRadian = [self.shapeDrawer
                         getRadianForCircleWithIndex:self.parameters.maxValue
                         divides:self.parameters.maxValue - self.parameters.minValue
                         drawRatio:3.0f / 4.0f];

  return [self.shapeDrawer vertexCountOfFillCircle:CIRCLE_DIVIDES] * 3
  + [self.shapeDrawer vertexCountOfDrawCircle:CIRCLE_DIVIDES]
  + [self.shapeDrawer vertexCountOfDrawLineInCircle:
     (self.parameters.maxValue - self.parameters.minValue) / self.parameters.scale ]
  + [self.shapeDrawer vertexCountOfDrawLineInCircle:
     (self.parameters.maxValue - self.parameters.minValue) / self.parameters.mediumScale ]
  + [self.shapeDrawer vertexCountOfDrawLineInCircle:
     (self.parameters.maxValue - self.parameters.minValue) / self.parameters.largeScale]
  + [self.shapeDrawer vertexCountOfFillTorusWithDivides:CIRCLE_DIVIDES
                                             startAngle:startRadian endAngle:endRadian];
  
}

/*!
 *
 * @return 値描画のための頂点数
 */
-(NSInteger) texturePositionInValueVertex {
  //
  return [self frameVertextCount] + 3;
}


/*!
 * 幅のpx値からのopenGL座標の大きさへ変換
 * @param px 幅のpx値
 * @return openGL座標での大きさ
 */
- (CGFloat) pxWidthToOpenGLWidth:(CGFloat) px {
  return [self aspect] * 2.0f / (float)[self width] * px;
}

/*!
 * 高さのpx値からのopenGL座標の大きさへ変換
 * @param px 高さのpx値
 * @return  openGL座標での大きさ
 */
- (CGFloat) pxHeightToOpenGLHeight:(CGFloat) px {
  return (2.0f / (float)[self height]) * px;
}

- (NSInteger) openGLWidthToPx:(CGFloat)textSize {
  // PX_Width / openGL座標系のwidth * openGL座標系のtextSize
  return (int)((CGFloat)self.width /  ((CGFloat)self.width / (CGFloat)self.height * 2.0f)
               * (CGFloat)textSize);
}



@end
