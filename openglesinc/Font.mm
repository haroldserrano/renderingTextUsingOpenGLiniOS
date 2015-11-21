//
//  Font.cpp
//  openglesinc
//
//  Created by Harold Serrano on 5/25/15.
//  Copyright (c) 2015 www.roldie.com. All rights reserved.
//

#include "Font.h"
#include "lodepng.h"
#include "FontLoader.h"

static GLubyte shaderText[MAX_SHADER_LENGTH];

void Font::setFont(){
    
    //1. Get font image name
    fontImage=fontLoader->fontAtlasImage.c_str();
    
    //2. Get width and height of font atlas
    fontWidth=fontLoader->fontAtlasWidth;
    fontHeight=fontLoader->fontAtlasHeight;
    
    //3. Set the coordinates for the vertex and UV
    setFontVertexAndUVCoords();
    
    //4. Start the OpenGL process
    setupOpenGL();
    
}

void Font::setText(const char* uText){
    
    text=uText;
    textContainer.clear(); //clear the text container
    
    //1. Parse the text and store the information into a vector
    for (int i=0; i<strlen(text); i++) {
        
        for (int j=0; j<fontLoader->fontData.size(); j++) {
            
            if (text[i]==*fontLoader->fontData[j].letter) {
                
                //copy the chars into the textContainer
                TextData textData;
                
                textData.x=fontLoader->fontData[j].x/fontLoader->fontAtlasWidth;
                textData.y=fontLoader->fontData[j].y/fontLoader->fontAtlasHeight;
                textData.width=fontLoader->fontData[j].width;
                textData.height=fontLoader->fontData[j].height;
                
                textData.xOffset=2*fontLoader->fontData[j].xoffset;
                textData.yOffset=fontLoader->fontData[j].yoffset;
                textData.xAdvance=2*fontLoader->fontData[j].xadvance;
                
                textData.letter=fontLoader->fontData[j].letter;
                
                textContainer.push_back(textData);
                
            }
        }
        
    }
    
}

void Font::drawText(){
    
    
    float lastTextYOffset=0.0;
    float currentTextYOffset=0.0;
    float lastTextXAdvance=0.0;
    
    GLKMatrix4 initPosition=modelSpace;
    
    //1. For every letter in the word, look for its information such as width, height, and coordinates and render it.
    for (int i=0; i<textContainer.size(); i++) {
        
        TextData textData;
        textData=textContainer.at(i);
        
        currentTextYOffset=lastTextYOffset-textData.yOffset;
        
        modelSpace=GLKMatrix4Translate(modelSpace, lastTextXAdvance/screenWidth,currentTextYOffset/screenHeight, 0.0);
        
        fontWidth=textData.width;
        fontHeight=textData.height;
        
        textXOffset=textData.x;
        textYOffset=textData.y;
        
        setFontVertexAndUVCoords();
        
        updateVertexObjectBuffer();
        
        draw();
        
        lastTextYOffset=textData.yOffset;
        lastTextXAdvance=textData.xAdvance+textSpacing;
        
    }
    
    //reset to initial position
    
    modelSpace=initPosition;
    
}

void Font::setupOpenGL(){
    
    //load the shaders, compile them and link them
    
    loadShaders("FontShader.vsh", "FontShader.fsh");
    
    //glEnable(GL_DEPTH_TEST);
    
    //1. Generate a Vertex Array Object
    
    glGenVertexArraysOES(1,&vertexArrayObject);
    
    //2. Bind the Vertex Array Object
    
    glBindVertexArrayOES(vertexArrayObject);
    
    //3. Generate a Vertex Buffer Object
    
    glGenBuffers(1, &vertexBufferObject);
    
    //4. Bind the Vertex Buffer Object
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
    
    //5a. Dump the data into the Buffer
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(fontVertices)+sizeof(fontUVCoords), NULL, GL_DYNAMIC_DRAW);
    
    //5b. Load vertex data with glBufferSubData
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(fontVertices), fontVertices);
    
    //5c. Load uv data with glBufferSubData
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(fontVertices), sizeof(fontUVCoords), fontUVCoords);
    
    
    //6. Get the location of the shader attribute called "position"
    positionLocation=glGetAttribLocation(programObject, "position");
    
    //8. Get the location of the shader attribute called "texCoords"
    uvLocation=glGetAttribLocation(programObject, "texCoord");
    
    //8. Get Location of uniforms
    modelViewProjectionUniformLocation = glGetUniformLocation(programObject,"modelViewProjectionMatrix");
    
    
    //9. Enable both attribute locations
    
    //9a. Enable the position attribute
    glEnableVertexAttribArray(positionLocation);
    
    //9c. Enable the UV attribute
    glEnableVertexAttribArray(uvLocation);
    
    //10. Link the buffer data to the shader attribute locations
    
    //10a. Link the buffer data to the shader's position location
    glVertexAttribPointer(positionLocation, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid *) 0);
    
    //10b. Link the buffer data to the shader's UV location
    glVertexAttribPointer(uvLocation, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)sizeof(fontVertices));
    
    /*Since we are going to start the rendering process by using glDrawElements*/
    
    //11. Create a new buffer for the indices
    GLuint elementBuffer;
    glGenBuffers(1, &elementBuffer);
    
    //12. Bind the new buffer to binding point GL_ELEMENT_ARRAY_BUFFER
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    
    //13. Load the buffer with the indices found in
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(fontIndex), fontIndex, GL_DYNAMIC_DRAW);
    
    //14. Activate GL_TEXTURE0
    glActiveTexture(GL_TEXTURE0);
    
    //15 Generate a texture buffer
    glGenTextures(1, &textureID[0]);
    
    //16 Bind texture0
    glBindTexture(GL_TEXTURE_2D, textureID[0]);
    
    //17. Decode image into its raw image data.
    if(convertImageToRawImage(fontImage)){
        
        //if decompression was successful, set the texture parameters
        
        //17a. set the texture wrapping parameters
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        
        //17b. set the texture magnification/minification parameters
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        
        //17c. load the image data into the current bound texture buffer
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, imageWidth, imageHeight, 0,
                     GL_RGBA, GL_UNSIGNED_BYTE, &image[0]);
        
    }
    
   FontTextureUniformLocation=glGetUniformLocation(programObject, "FontTextureAtlasMap");
    
   OffsetFontUniformLocation=glGetUniformLocation(programObject, "Offset");
    
    //25. Unbind the VAO
    glBindVertexArrayOES(0);
    
    //26. Sets the transformation
    setTransformation();
    
}


void Font::draw(){
    
    //4. Transform the model-world-view space to the projection space
    modelWorldViewProjectionSpace = GLKMatrix4Multiply(projectionSpace, modelSpace);
    
    
    //5. Assign the model-world-view-projection matrix data to the uniform location:modelviewProjectionUniformLocation
    glUniformMatrix4fv(modelViewProjectionUniformLocation, 1, 0, modelWorldViewProjectionSpace.m);
    
    
    
    //1. Set the shader program
    glUseProgram(programObject);
    
    //2. Bind the VAO
    glBindVertexArrayOES(vertexArrayObject);
    
    //3. Enable blending and depth test
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_DEPTH_TEST);
    
    //10. Activate the texture unit for the non-pressed button image
    glActiveTexture(GL_TEXTURE0);
    
    //11 Bind the texture object
    glBindTexture(GL_TEXTURE_2D, textureID[0]);
    
    //12. Specify the value of the UV Map uniform
    glUniform1i(FontTextureUniformLocation, 0);
    
    glUniform2f(OffsetFontUniformLocation, textXOffset,textYOffset);

    //13. Start the rendering process
    glDrawElements(GL_TRIANGLES, sizeof(fontIndex)/4, GL_UNSIGNED_INT,(void*)0);
    
    //14. Disable the blending and enable depth testing
    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
    
    
    //16. Disable the VAO
    glBindVertexArrayOES(0);
    
}


void Font::setTransformation(){
    
    //1. Set up the model space
    modelSpace=GLKMatrix4Identity;
    
    //2. translate 
    modelSpace=GLKMatrix4Translate(modelSpace, fontXPosition, fontYPosition, 0.0);
    
    
    //3. Set the projection space to a ortho space
    projectionSpace = GLKMatrix4MakeOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
    
    
    //4. Transform the model-world-view space to the projection space
    modelWorldViewProjectionSpace = GLKMatrix4Multiply(projectionSpace, modelSpace);
    
    
    //5. Assign the model-world-view-projection matrix data to the uniform location:modelviewProjectionUniformLocation
    glUniformMatrix4fv(modelViewProjectionUniformLocation, 1, 0, modelWorldViewProjectionSpace.m);
    
}

void Font::setFontVertexAndUVCoords(){
    
    //1. set the width, height and depth for the image rectangle
    float width=fontWidth/screenWidth;
    float height=fontHeight/screenHeight;
    float depth=0.0;
    
    float widthFontTexture=fontWidth/fontLoader->fontAtlasWidth;
    float heightFontTexture=fontHeight/fontLoader->fontAtlasHeight;
    
    //2. Set the value for each vertex into an array
    
    //Upper-Right Corner vertex of rectangle
    fontVertices[0]=width;
    fontVertices[1]=height;
    fontVertices[2]=depth;
    
    //Lower-Right corner vertex of rectangle
    fontVertices[3]=width;
    fontVertices[4]=-height;
    fontVertices[5]=depth;
    
    //Lower-Left corner vertex of rectangle
    fontVertices[6]=-width;
    fontVertices[7]=-height;
    fontVertices[8]=depth;
    
    //Upper-Left corner vertex of rectangle
    fontVertices[9]=-width;
    fontVertices[10]=height;
    fontVertices[11]=depth;
    
    
    //3. Set the value for each uv coordinate into an array
    
    fontUVCoords[0]=1.0*widthFontTexture;
    fontUVCoords[1]=0.0;
    
    fontUVCoords[2]=1.0*widthFontTexture;
    fontUVCoords[3]=1.0*heightFontTexture;
    
    fontUVCoords[4]=0.0;
    fontUVCoords[5]=1.0*heightFontTexture;
    
    fontUVCoords[6]=0.0;
    fontUVCoords[7]=0.0;
    
    //4. set the value for each index into an array
    
    fontIndex[0]=0;
    fontIndex[1]=1;
    fontIndex[2]=2;
    
    fontIndex[3]=2;
    fontIndex[4]=3;
    fontIndex[5]=0;
    
}

void Font::updateVertexObjectBuffer(){
    
    glBindVertexArrayOES(vertexArrayObject);
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);
  
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(fontVertices), fontVertices);
    
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(fontVertices), sizeof(fontUVCoords), fontUVCoords);
    
}


bool Font::convertImageToRawImage(const char *uTexture){
    
    bool success=false;
    
    //The method decode() is the method rensponsible for decompressing the formated image.
    //The result is stored in "image".
    
    unsigned error = lodepng::decode(image, imageWidth, imageHeight,uTexture);
    
    //if there's an error, display it
    if(error){
        
        cout << "Couldn't decode the image. decoder error " << error << ": " << lodepng_error_text(error) << std::endl;
        
    }else{
        
        //Flip and invert the image
        unsigned char* imagePtr=&image[0];
        
        int halfTheHeightInPixels=imageHeight/2;
        int heightInPixels=imageHeight;
        
        
        //Assume RGBA for 4 components per pixel
        int numColorComponents=4;
        
        //Assuming each color component is an unsigned char
        int widthInChars=imageWidth*numColorComponents;
        
        unsigned char *top=NULL;
        unsigned char *bottom=NULL;
        unsigned char temp=0;
        
        for( int h = 0; h < halfTheHeightInPixels; ++h )
        {
            top = imagePtr + h * widthInChars;
            bottom = imagePtr + (heightInPixels - h - 1) * widthInChars;
            
            for( int w = 0; w < widthInChars; ++w )
            {
                // Swap the chars around.
                temp = *top;
                *top = *bottom;
                *bottom = temp;
                
                ++top;
                ++bottom;
            }
        }
        
        success=true;
    }
    
    return success;
}



void Font::loadShaders(const char* uVertexShaderProgram, const char* uFragmentShaderProgram){
    
    // Temporary Shader objects
    GLuint VertexShader;
    GLuint FragmentShader;
    
    //1. Create shader objects
    VertexShader = glCreateShader(GL_VERTEX_SHADER);
    FragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    
    
    //2. Load both vertex & fragment shader files
    
    //2a. Usually you want to check the return value of the loadShaderFile function, if
    //it returns true, then the shaders were found, else there was an error.
    
    
    if(loadShaderFile(uVertexShaderProgram, VertexShader)==false){
        
        glDeleteShader(VertexShader);
        glDeleteShader(FragmentShader);
        fprintf(stderr, "The shader at %s could not be found.\n", uVertexShaderProgram);
        
    }else{
        
        fprintf(stderr,"Vertex Shader was loaded successfully\n");
        
    }
    
    if(loadShaderFile(uFragmentShaderProgram, FragmentShader)==false){
        
        glDeleteShader(VertexShader);
        glDeleteShader(FragmentShader);
        fprintf(stderr, "The shader at %s could not be found.\n", uFragmentShaderProgram);
    }else{
        
        fprintf(stderr,"Fragment Shader was loaded successfully\n");
        
    }
    
    //3. Compile both shader objects
    glCompileShader(VertexShader);
    glCompileShader(FragmentShader);
    
    //3a. Check for errors in the compilation
    GLint testVal;
    
    //3b. Check if vertex shader object compiled successfully
    glGetShaderiv(VertexShader, GL_COMPILE_STATUS, &testVal);
    if(testVal == GL_FALSE)
    {
        char infoLog[1024];
        glGetShaderInfoLog(VertexShader, 1024, NULL, infoLog);
        fprintf(stderr, "The shader at %s failed to compile with the following error:\n%s\n", uVertexShaderProgram, infoLog);
        glDeleteShader(VertexShader);
        glDeleteShader(FragmentShader);
        
    }else{
        fprintf(stderr,"Vertex Shader compiled successfully\n");
    }
    
    //3c. Check if fragment shader object compiled successfully
    glGetShaderiv(FragmentShader, GL_COMPILE_STATUS, &testVal);
    if(testVal == GL_FALSE)
    {
        char infoLog[1024];
        glGetShaderInfoLog(FragmentShader, 1024, NULL, infoLog);
        fprintf(stderr, "The shader at %s failed to compile with the following error:\n%s\n", uFragmentShaderProgram, infoLog);
        glDeleteShader(VertexShader);
        glDeleteShader(FragmentShader);
        
    }else{
        fprintf(stderr,"Fragment Shader compiled successfully\n");
    }
    
    
    //4. Create a shader program object
    programObject = glCreateProgram();
    
    //5. Attach the shader objects to the shader program object
    glAttachShader(programObject, VertexShader);
    glAttachShader(programObject, FragmentShader);
    
    //6. Link both shader objects to the program object
    glLinkProgram(programObject);
    
    //6a. Make sure link had no errors
    glGetProgramiv(programObject, GL_LINK_STATUS, &testVal);
    if(testVal == GL_FALSE)
    {
        char infoLog[1024];
        glGetProgramInfoLog(programObject, 1024, NULL, infoLog);
        fprintf(stderr,"The programs %s and %s failed to link with the following errors:\n%s\n",
                uVertexShaderProgram, uFragmentShaderProgram, infoLog);
        glDeleteProgram(programObject);
        
    }else{
        fprintf(stderr,"Shaders linked successfully\n");
    }
    
    
    // These are no longer needed
    glDeleteShader(VertexShader);
    glDeleteShader(FragmentShader);
    
    //7. Use the program
    glUseProgram(programObject);
}


#pragma mark - Load, compile and link shaders to program

bool Font::loadShaderFile(const char *szFile, GLuint shader)
{
    GLint shaderLength = 0;
    FILE *fp;
    
    // Open the shader file
    fp = fopen(szFile, "r");
    if(fp != NULL)
    {
        // See how long the file is
        while (fgetc(fp) != EOF)
            shaderLength++;
        
        // Allocate a block of memory to send in the shader
        //assert(shaderLength < MAX_SHADER_LENGTH);   // make me bigger!
        if(shaderLength > MAX_SHADER_LENGTH)
        {
            fclose(fp);
            return false;
        }
        
        // Go back to beginning of file
        rewind(fp);
        
        // Read the whole file in
        if (shaderText != NULL)
            fread(shaderText, 1, shaderLength, fp);
        
        // Make sure it is null terminated and close the file
        shaderText[shaderLength] = '\0';
        fclose(fp);
    }
    else
        return false;
    
    // Load the string
    loadShaderSrc((const char *)shaderText, shader);
    
    return true;
}

// Load the shader from the source text
void Font::loadShaderSrc(const char *szShaderSrc, GLuint shader)
{
    GLchar *fsStringPtr[1];
    
    fsStringPtr[0] = (GLchar *)szShaderSrc;
    glShaderSource(shader, 1, (const GLchar **)fsStringPtr, NULL);
}

#pragma mark - Tear down of OpenGL
void Font::teadDownOpenGL(){
    
    glDeleteBuffers(1, &vertexBufferObject);
    glDeleteVertexArraysOES(1, &vertexArrayObject);
    
    
    if (programObject) {
        glDeleteProgram(programObject);
        programObject = 0;
        
    }
    
}