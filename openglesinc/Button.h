//
//  Button.h
//  openglesinc
//
//  Created by Harold Serrano on 3/23/15.
//  Copyright (c) 2015 cgdemy.com. All rights reserved.
//

#ifndef __openglesinc__Button__
#define __openglesinc__Button__

#include <iostream>

#include <math.h>
#include <vector>
#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#define MAX_SHADER_LENGTH   8192

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

#define OPENGL_ES

using namespace std;

class Button{
    
private:
    
    GLuint textureID[16];   //Array for textures
    GLuint programObject;   //program object used to link shaders
    GLuint vertexArrayObject; //Vertex Array Object
    GLuint vertexBufferObject; //Vertex Buffer Object
    
    float aspect; //widthDisplay/heightDisplay ratio
    GLint modelViewProjectionUniformLocation;  //OpenGL location for our MVP uniform
    GLint modelViewUniformLocation; //OpenGL location for the Model-View uniform
    GLint ButtonAPressedTextureUniformLocation; //OpenGL location for the Texture Map
    GLint ButtonATextureUniformLocation; //OpenGL location for the Texture Map
    
    GLint ButtonStateUniformLocation;  //Uniform location for the current Button state
    
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
    
    float buttonXPosition;  //Button x position
    float buttonYPosition;  //Button y position
    
    float buttonWidth;  //Button width dimension
    float buttonHeight; //Button height dimension
    
    //button boundaries
    float left;
    float right;
    float bottom;
    float top;
    
    //button vertex, uv coords and index arrays
    float buttonVertices[12]={0};
    float buttonUVCoords[8]={0};
    int buttonIndex[6]={0};
    
    //has the button been pressed
    bool isPressed;
    
    //button images
    const char* buttonImage;
    const char* pressedButtonImage;
    
public:
    
    //Constructor
    Button(float uButtonXPosition, float uButtonYPosition, float uButtonWidth,float uButtonHeight, const char* uButtonImage, const char* uPressedButtonImage,float uScreenWidth,float uScreenHeight);
    
    ~Button();
    
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
    
    //button dimensions
    void setButtonVertexAndUVCoords();
    
    //get if button was pressed
    bool getButtonIsPress();
    
    //degree to rad
    inline float degreesToRad(float angle){return (angle*M_PI/180);};
    
};

#endif /* defined(__openglesinc__Button__) */
