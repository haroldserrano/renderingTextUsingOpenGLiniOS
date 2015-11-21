//
//  Font.h
//  openglesinc
//
//  Created by Harold Serrano on 5/25/15.
//  Copyright (c) 2015 www.haroldserrano.com. All rights reserved.
//

#ifndef __openglesinc__Font__
#define __openglesinc__Font__

#include <stdio.h>
#include <iostream>
#include <vector>
#include "CommonProtocols.h"
#include "FontLoader.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define MAX_SHADER_LENGTH   8192



class Font{
    
private:
    
    FontLoader *fontLoader;
    
    const char* text;
    
    vector<TextData> textContainer;
    
    float textSpacing;
    
    
    GLuint textureID[16];   //Array for textures
    GLuint programObject;   //program object used to link shaders
    GLuint vertexArrayObject; //Vertex Array Object
    GLuint vertexBufferObject; //Vertex Buffer Object
    
    float aspect; //widthDisplay/heightDisplay ratio
    GLint modelViewProjectionUniformLocation;  //OpenGL location for our MVP uniform
    GLint modelViewUniformLocation; //OpenGL location for the Model-View uniform
    
    GLint FontTextureUniformLocation; //OpenGL location for the Texture Map
    GLint OffsetFontUniformLocation; //OpenGL location of the offset
    
    //Matrices for several transformation
    GLKMatrix4 projectionSpace;
    GLKMatrix4 cameraViewSpace;
    GLKMatrix4 modelSpace;
    GLKMatrix4 worldSpace;
    GLKMatrix4 modelWorldSpace;
    GLKMatrix4 modelWorldViewSpace;
    GLKMatrix4 modelWorldViewProjectionSpace;
    
    
    float screenWidth;  //Width of current device display
    float screenHeight; //Height of current device display
    
    GLuint positionLocation; //attribute "position" location
    GLuint uvLocation; //attribute "uv"location
    
    vector<unsigned char> image;
    unsigned int imageWidth, imageHeight;
    
    unsigned int fontWidth, fontHeight;
    
    
    //button vertex, uv coords and index arrays
    float fontVertices[12]={0};
    float fontUVCoords[8]={0};
    int fontIndex[6]={0};
    
    //font image
    const char* fontImage;
    
    float fontXPosition;  //font x position
    float fontYPosition;  //font y position
    
    float textXOffset;
    float textYOffset;
    
public:
    
    Font(FontLoader* uFontLoader,float uFontXPosition, float uFontYPosition,float uScreenWidth,float uScreenHeight){
        fontLoader=uFontLoader;
        screenWidth=uScreenWidth;
        screenHeight=uScreenHeight;
        
        fontXPosition=uFontXPosition*2/screenWidth-1;
        fontYPosition=uFontYPosition*(-2/screenHeight)+1;
    }
    
    ~Font(){
        delete fontLoader;
        
    };
    
    Font(const Font& value){};
    
    Font& operator=(const Font& value){return *this;};
   
    void setFont();
    
    void setText(const char* uText);
    
    void drawText();
    
    void setupOpenGL(); //Initialize the OpenGL
    
    void teadDownOpenGL(); //Destroys the OpenGL
    
    //loads the shaders
    void loadShaders(const char* uVertexShaderProgram, const char* uFragmentShaderProgram);
    
    //Set the transformation for the object
    void setTransformation();
    
    //updates the mesh
    void update(float touchXPosition,float touchYPosition);
    
    //draws the mesh
    void draw();
    
    //files used to loading the shader
    bool loadShaderFile(const char *szFile, GLuint shader);
    void loadShaderSrc(const char *szShaderSrc, GLuint shader);
    
    //method to decompress image
    bool convertImageToRawImage(const char *uTexture);
    
    //font atlas dimensions
    void setFontVertexAndUVCoords();
    
    void updateVertexObjectBuffer();
    
    //degree to rad
    inline float degreesToRad(float angle){return (angle*M_PI/180);};
    
};

#endif /* defined(__openglesinc__Font__) */
