//
//  MeterRenderer.h
//  TachoMeterDemo
//
//  Created by nyaago on 2013/10/21.
//  Copyright (c) 2013年 nyaago. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "ShaderLoader.h"
#import "GLShapeDrawer.h"
#import "TextImage.h"

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

// Attribute index.
enum
{
  ATTRIB_VERTEX,
  ATTRIB_NORMAL,
  NUM_ATTRIBUTES
};

@interface MeterRenderer : NSObject {
GLuint _program;
GLuint _textureProgram;

GLKMatrix4 _modelViewProjectionMatrix;
GLKMatrix3 _normalMatrix;
float _rotation;

GLuint _vertexArray;
GLuint _vertexBuffer;

NSInteger _needlePosition;
GLint uniforms[NUM_UNIFORMS];

}



@property (nonatomic, strong) GLKBaseEffect *effect;
@property (nonatomic, strong) GLKView *view;

//@property (strong, nonatomic) EAGLContext *context;

@property (nonatomic, strong) ShaderLoader *shaderLoader;
@property (nonatomic, strong) ShaderLoader *textureShaderLoader;
@property (nonatomic, strong) GLShapeDrawer *shapeDrawer;
@property (nonatomic, strong) FloatArray *vertexs;

@property (nonatomic, readonly) CGFloat aspect;
@property (nonatomic, readonly) NSInteger width;
@property (nonatomic, readonly) NSInteger height;


- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)loadTextureShaders;
- (void)update;

- (NSInteger) width ;

- (NSInteger) height;

- (CGFloat) aspect ;

/*!
 * 幅のpx値からのopenGL座標の大きさへ変換
 * @param px 幅のpx値
 * @return openGL座標での大きさ
 */
- (CGFloat) pxWidthToOpenGLWidth:(CGFloat) px;


/*!
 * 高さのpx値からのopenGL座標の大きさへ変換
 * @param px 高さのpx値
 * @return  openGL座標での大きさ
 */
- (CGFloat) pxHeightToOpenGLHeight:(CGFloat) px;

- (NSInteger) openGLWidthToPx:(CGFloat)textSize;

/*!
 * 指定したテキストを描画する
 * @param text 描画テキスト
 * @param x 描画位置-openglの座標 -x
 * @param y 描画位置-openglの座標 -y
 * @param z 描画位置-openglの座標 -z
 * @param font フォント
 * @param textColor
 * @param backgroundColor
 */
- (void) drawText:(NSString *)text x:(CGFloat)x y:(CGFloat)y z:(CGFloat)z
             font:(UIFont *)font
        textColor:(UIColor *)textColor
  backgroundColor:(UIColor *)backgroundColor;

@end
