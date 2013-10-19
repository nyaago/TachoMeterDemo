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

@interface TachoMeterRenderere() {

GLuint _program;

GLKMatrix4 _modelViewProjectionMatrix;
GLKMatrix3 _normalMatrix;
float _rotation;

GLuint _vertexArray;
GLuint _vertexBuffer;

}

//@property (strong, nonatomic) EAGLContext *context;
@property (nonatomic, readonly) NSTimeInterval timeSinceLastUpdate;
@property (nonatomic, strong) NSDate *lastUpdated;
@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) ShaderLoader *shaderLoader;
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
    self.shapeDrawer = [[GLShapeDrawer alloc] init];
  }
  return self;
}

#pragma mark -  OpenGL ES 2

- (void)setupGL
{
  [self loadShaders];
  self.vertexs = [[FloatArray alloc] initWithCount:[self vertexArraySize]];
  [self setFrameVertex];
  
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
  glUseProgram(_program);
  
  glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
  glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
  
//  glDrawArrays(GL_TRIANGLE_STRIP, 0, 36);
  [self.shapeDrawer drawArrays];
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
  // Create shader program.
  _program = [self.shaderLoader loadShaders:@"Shader"];
  // Bind attribute locations.
  // This needs to be done prior to linking.
  glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
  glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
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
}

- (void) setDefault {
  
  self.frameRadius = 1.0f;
  self.meterRadius = 0.96f;
  self.meterScaleCircleRadius = 0.94;
  self.meterScaleLineRadius = 0.87f;
  
  self.frameColor = [[GLColor alloc] initWithRed:191.0/255.0 green:191.0/255 blue:191.0/255];
  self.activeMeterColor = [[GLColor alloc] initWithRed:255 green:255 blue:255];
  self.inactiveMeterColor = [[GLColor alloc] initWithRed:127 green:127 blue:127];
  self.centerColor = [[GLColor alloc] initWithRed:31 green:31 blue:31];
  self.scaleColor = [[GLColor alloc] initWithRed:0 green:0 blue:0];
  self.largeScaleColor = [[GLColor alloc] initWithRed:255 green:0 blue:0];
  self.redColor = [[GLColor alloc] initWithRed:255 green:0 blue:0];
  
  self.lineWidth = 1.0f;
  
  self.scaleLength = 0.04f;
  self.medimuScaleLength = 0.04f;
  self.largeScaleLength = 0.1f;
}

- (NSInteger) vertexCount {
  return [self.shapeDrawer vertexCountOfFillCircle:CIRCLE_DIVIDES] * 3
  + [self.shapeDrawer vertexCountOfDrawCircle:CIRCLE_DIVIDES]
  + [self.shapeDrawer vertexCountOfDrawLineInCircle:
     (self.parameters.maxValue - self.parameters.minValue) / self.parameters.scale ]
  + [self.shapeDrawer vertexCountOfDrawLineInCircle:
     (self.parameters.maxValue - self.parameters.minValue) / self.parameters.mediumScale ]
  + [self.shapeDrawer vertexCountOfDrawLineInCircle:
     (self.parameters.maxValue - self.parameters.minValue) / self.parameters.largeScale];
}

- (NSInteger) vertexArraySize {
  return [self vertexCount] * VERTEX_ATTRIB_SIZE;
}




@end
