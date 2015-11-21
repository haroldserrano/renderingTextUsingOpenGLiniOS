//
//  Button.cpp
//  openglesinc
//
//  Created by Harold Serrano on 3/23/15.
//  Copyright (c) 2015 cgdemy.com. All rights reserved.
//

#include "Button.h"
#include "lodepng.h"
#include <vector>
//#include "ButtonVertices.h"

static GLubyte shaderText[MAX_SHADER_LENGTH];

Button::Button(float uButtonXPosition, float uButtonYPosition, float uButtonWidth,float uButtonHeight, const char* uButtonImage, const char* uPressedButtonImage, float uScreenWidth,float uScreenHeight){
    
    //1. screen width and height
    screenWidth=uScreenWidth;
    screenHeight=uScreenHeight;
    
    //2. button width and height
    buttonWidth=uButtonWidth;
    buttonHeight=uButtonHeight;
    
    //3. set the names of both button images
    buttonImage=uButtonImage;
    pressedButtonImage=uPressedButtonImage;
 
    //4. button x and y position. Because our ortho matrix is in the range of [-1,1]. We need to convert from screen coordinates to ortho coordinates.
    buttonXPosition=uButtonXPosition*2/screenWidth-1;
    buttonYPosition=uButtonYPosition*(-2/screenHeight)+1;
    
    //5. calculate the boundaries of the button
    left=buttonXPosition-buttonWidth/screenWidth;
    right=buttonXPosition+buttonWidth/screenWidth;
    
    top=buttonYPosition+buttonHeight/screenHeight;
    bottom=buttonYPosition-buttonHeight/screenHeight;
    
    //6. set the bool value to false
    isPressed=false;

}

void Button::setupOpenGL(){
    
    //load the shaders, compile them and link them
    
    loadShaders("ButtonShader.vsh", "ButtonShader.fsh");
    
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
    
    glBufferData(GL_ARRAY_BUFFER, sizeof(buttonVertices)+sizeof(buttonUVCoords), NULL, GL_STATIC_DRAW);
    
    //5b. Load vertex data with glBufferSubData
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(buttonVertices), buttonVertices);
    
    //5c. Load uv data with glBufferSubData
    glBufferSubData(GL_ARRAY_BUFFER, sizeof(buttonVertices), sizeof(buttonUVCoords), buttonUVCoords);
    
    
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
    glVertexAttribPointer(uvLocation, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)sizeof(buttonVertices));
    
    /*Since we are going to start the rendering process by using glDrawElements*/
    
    //11. Create a new buffer for the indices
    GLuint elementBuffer;
    glGenBuffers(1, &elementBuffer);
    
    //12. Bind the new buffer to binding point GL_ELEMENT_ARRAY_BUFFER
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, elementBuffer);
    
    //13. Load the buffer with the indices found in littleMansion_index array
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(buttonIndex), buttonIndex, GL_STATIC_DRAW);
    
    //SET UNPRESSED BUTTON TEXTURE
    //14. Activate GL_TEXTURE0
    glActiveTexture(GL_TEXTURE0);
    
    //15 Generate a texture buffer
    glGenTextures(1, &textureID[0]);
    
    //16 Bind texture0
    glBindTexture(GL_TEXTURE_2D, textureID[0]);
    
    //17. Decode image into its raw image data. "ButtonA.png" is our formatted image.
    if(convertImageToRawImage(buttonImage)){
        
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
    
    image.clear();
    
    //18. Get the location of the Uniform Sampler2D
    ButtonATextureUniformLocation=glGetUniformLocation(programObject, "ButtonATextureMap");
    
    //SET PRESSED BUTTON TEXTURE
    
    //19. Activate GL_TEXTURE1
    glActiveTexture(GL_TEXTURE1);
    
    //20 Generate a texture buffer
    glGenTextures(1, &textureID[1]);
    
    //21 Bind texture0
    glBindTexture(GL_TEXTURE_2D, textureID[1]);
    
    //22. Decode image into its raw image data. "ButtonAPressed.png" is our formatted image.
    if(convertImageToRawImage(pressedButtonImage)){
        
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
    
    image.clear();
    
    //23. Get the location of the Uniform Sampler2D
    ButtonAPressedTextureUniformLocation=glGetUniformLocation(programObject, "ButtonAPressedTextureMap");
    
    //24. Get the location for the uniform containing the current button state
    ButtonStateUniformLocation=glGetUniformLocation(programObject, "CurrentButtonState");
    
    //25. Unbind the VAO
    glBindVertexArrayOES(0);
    
    //26. Sets the transformation
    setTransformation();
    
}

void Button::update(float touchXPosition,float touchYPosition){
    
    //1. check if the touch is within the boundaries of the button
    
    if (touchXPosition>=left && touchXPosition<=right) {
        
        if (touchYPosition>=bottom && touchYPosition<=top) {
            
            //2. if so, set the bool value to true
            isPressed=true;
        }
    }
    
    else{
            //3. else, set it to false
            isPressed=false;
    }
    
}

void Button::draw(){
 
    //1. Set the shader program
    glUseProgram(programObject);
    
    //2. Bind the VAO
    glBindVertexArrayOES(vertexArrayObject);
    
    //3. Enable blending and depth test
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_DEPTH_TEST);
    
    //4. If the isPressed value is true, then update the state of the button
    if (isPressed==true) {
        
        //5. uniform is updated with a value of 1
        glUniform1i(ButtonStateUniformLocation, 1);
        
        //6. Activate the texture unit for the pressed button image
        glActiveTexture(GL_TEXTURE1);
        
        //7 Bind the texture object
        glBindTexture(GL_TEXTURE_2D, textureID[1]);
        
        //8. Specify the value of the UV Map uniform
        glUniform1i(ButtonAPressedTextureUniformLocation, 1);
        
    }else{
        
        //9. if it is not pressed, the uniform is updated with a value of 0
        glUniform1i(ButtonStateUniformLocation, 0);
        
        //10. Activate the texture unit for the non-pressed button image
        glActiveTexture(GL_TEXTURE0);
        
        //11 Bind the texture object
        glBindTexture(GL_TEXTURE_2D, textureID[0]);
        
        //12. Specify the value of the UV Map uniform
        glUniform1i(ButtonATextureUniformLocation, 0);
        
    }
    
    //13. Start the rendering process
    glDrawElements(GL_TRIANGLES, sizeof(buttonIndex)/4, GL_UNSIGNED_INT,(void*)0);
    
    //14. Disable the blending and enable depth testing
    glDisable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
    
    //15. Set the bool value "isPressed" to false to avoid the image to be locked up
    isPressed=false;
    
    //16. Disable the VAO
    glBindVertexArrayOES(0);
    
}


void Button::setTransformation(){
    
    //1. Set up the model space
    modelSpace=GLKMatrix4Identity;
    
    //2. translate the button
    modelSpace=GLKMatrix4Translate(modelSpace, buttonXPosition, buttonYPosition, 0.0);
    
   
    //3. Set the projection space to a ortho space
    projectionSpace = GLKMatrix4MakeOrtho(-1.0, 1.0, -1.0, 1.0, -1.0, 1.0);
    
    
    //4. Transform the model-world-view space to the projection space
    modelWorldViewProjectionSpace = GLKMatrix4Multiply(projectionSpace, modelSpace);

    
    //5. Assign the model-world-view-projection matrix data to the uniform location:modelviewProjectionUniformLocation
    glUniformMatrix4fv(modelViewProjectionUniformLocation, 1, 0, modelWorldViewProjectionSpace.m);

}

void Button::setButtonVertexAndUVCoords(){
    
    
    //1. set the width, height and depth for the image rectangle
    float width=buttonWidth/screenWidth;
    float height=buttonHeight/screenHeight;
    float depth=0.0;
    
    //2. Set the value for each vertex into an array
    
    //Upper-Right Corner vertex of rectangle
    buttonVertices[0]=width;
    buttonVertices[1]=height;
    buttonVertices[2]=depth;
    
    //Lower-Right corner vertex of rectangle
    buttonVertices[3]=width;
    buttonVertices[4]=-height;
    buttonVertices[5]=depth;
    
    //Lower-Left corner vertex of rectangle
    buttonVertices[6]=-width;
    buttonVertices[7]=-height;
    buttonVertices[8]=depth;
    
    //Upper-Left corner vertex of rectangle
    buttonVertices[9]=-width;
    buttonVertices[10]=height;
    buttonVertices[11]=depth;
    
    
    //3. Set the value for each uv coordinate into an array
    
    buttonUVCoords[0]=1.0;
    buttonUVCoords[1]=0.0;
    
    buttonUVCoords[2]=1.0;
    buttonUVCoords[3]=1.0;
    
    buttonUVCoords[4]=0.0;
    buttonUVCoords[5]=1.0;
    
    buttonUVCoords[6]=0.0;
    buttonUVCoords[7]=0.0;
    
    //4. set the value for each index into an array
    
    buttonIndex[0]=0;
    buttonIndex[1]=1;
    buttonIndex[2]=2;
    
    buttonIndex[3]=2;
    buttonIndex[4]=3;
    buttonIndex[5]=0;
    
}

bool Button::getButtonIsPress(){
    
    //return the state of the button
    return isPressed;

}

bool Button::convertImageToRawImage(const char *uTexture){
    
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



void Button::loadShaders(const char* uVertexShaderProgram, const char* uFragmentShaderProgram){
    
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

bool Button::loadShaderFile(const char *szFile, GLuint shader)
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
void Button::loadShaderSrc(const char *szShaderSrc, GLuint shader)
{
    GLchar *fsStringPtr[1];
    
    fsStringPtr[0] = (GLchar *)szShaderSrc;
    glShaderSource(shader, 1, (const GLchar **)fsStringPtr, NULL);
}

#pragma mark - Tear down of OpenGL
void Button::teadDownOpenGL(){
    
    glDeleteBuffers(1, &vertexBufferObject);
    glDeleteVertexArraysOES(1, &vertexArrayObject);
    
    
    if (programObject) {
        glDeleteProgram(programObject);
        programObject = 0;
        
    }
    
}