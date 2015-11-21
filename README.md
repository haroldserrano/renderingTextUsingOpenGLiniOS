# Rendering Text using OpenGL ES 2.0 in iOS

## Introduction

In any graphics application, you need a method to communicate with the user. The common method is through text. Unfortunately, OpenGL does not provide any method that makes rendering _text_ simple. 

A common way of rendering _text_ is through the use of bitmaps. Bitmaps are 2D images. By representing a letter with an image, text can be rendered on a screen.

##### Figure 1 Rendering Text on a mobile device
![font in iphone](https://dl.dropboxusercontent.com/u/107789379/CGDemy/blogimages/fontIphone.png)

## Bitmap Font Generator

To render text, we must convert each letter to an image. There is a really awesome tool which does this. It is called [Glyph Designer](https://71squared.com/glyphdesigner). 

##### Figure 2 Glyph Designer

![glyph designer](https://dl.dropboxusercontent.com/u/107789379/CGDemy/blogimages/glyphdesigner.png)

Glyph Designer creates an image for each letter. Each letter is exported to a single image file as a _texture_ atlas. During _export_ a .png file (figure 1) and a _xml_ file (figure 2) is produced. 

##### Figure 3 Glyph Designer Texture Atlas

![Sample Output](https://dl.dropboxusercontent.com/u/107789379/CGDemy/blogimages/sampleFont.png)

The _xml_ file contains the following data for each letter:

* x-y coordinates
* width
* height
* x and y offset


##### Figure 4 Glyph Designer XML file

![xml output](https://dl.dropboxusercontent.com/u/107789379/CGDemy/blogimages/glyphdesignerOutput.png)

We are going to use these two files to render text on a mobile device using OpenGL ES. The image file is going to be loaded as a texture object. The OpenGL Shaders will use the coordinates specified in the _xml_ file to find the letter and render it on the screen.

## Loading Font Information

The first thing we need to do is to load the xml file and load the font information in a C++ structure. We are going to call this structure _FontData_.

#####Listing 1
<pre>
<code class="language-c">typedef struct{

    int ID;
    float x;
    float y;
    float width;  //width of character
    float height; //height of character
    float xoffset;
    float yoffset;
    float xadvance;
    int infoFontSize; //size of whole fonts
    const char *letter;

}FontData;

</code>
</pre>

The xml file will be loaded with a library called [tinyxml2](http://www.grinninglizard.com/tinyxml2/). It is an xml parser that is easily integrated in any C\++ program.

*tinyxml2* allows us to parse all the information in the xml file by iterating through each element. 

Let's create a class called *fontLoader*. This class will be responsible for loading and parsing the *xml* file.

This class will have a method called *loadFont()*. Its responsibility is to parse the XML file and load each letter's information into a vector of type *FontData*.

Listing 2 shows the implementation of this method. This method is found in the *FontLoader.mm* file.

#####Listing 2.

<pre>
<code class="language-c">
void FontLoader::loadFont(){
    
    //1. Created root node element
    XMLNode* font = doc.FirstChildElement("font");
    
    //&ltinfo face="ArialMT" size="64" bold="0" italic="0" chasrset="" unicode="0" stretchH="100" smooth="1" aa="1" padding="0,0,0,0" spacing="2,2"/>
    
    //2. Get every child element
    
    XMLElement* infoElem = font->FirstChildElement("info");
    const char* infoFontSize=infoElem->Attribute("size");
    
    //&ltcommon lineHeight="72" base="58" scaleW="512" scaleH="512" pages="1" packed="0"/>
    
    XMLElement* commonElem = font->FirstChildElement("common");
    const char* lineHeight=commonElem->Attribute("lineHeight");
    const char* base=commonElem->Attribute("base");
    const char* atlasWidth=commonElem->Attribute("scaleW");
    const char* atlasHeight=commonElem->Attribute("scaleH");
    
    float lineHeightValue=atof(lineHeight);
    float baseValue=atof(base);
    
    float yOffsetReScale=lineHeightValue-baseValue;
    
    fontAtlasWidth=atof(atlasWidth);
    fontAtlasHeight=atof(atlasHeight);
    
    //&ltpages>&ltpage id="0" file="testfont.png"/>&lt/pages>
    XMLElement* pagesElem = font->FirstChildElement("pages");
    XMLElement* pageElem=pagesElem->FirstChildElement("page");
    
    //uImageName=pageElem->Attribute("file");
    
    XMLElement* elem = font->FirstChildElement("chars");
    
    for(XMLElement* subElem = elem->FirstChildElement("char"); subElem != NULL; subElem = subElem->NextSiblingElement("char"))
    {
        
        //set up the fontData
        FontData ufontData;
        
        const char* ID = subElem->Attribute("id");
        ufontData.ID=atoi(ID);
        
        const char* x=subElem->Attribute("x");
        ufontData.x=atof(x);
        
        const char* y=subElem->Attribute("y");
        ufontData.y=atof(y);
        
        const char* width=subElem->Attribute("width");
        ufontData.width=atof(width);
        
        const char* height=subElem->Attribute("height");
        ufontData.height=atof(height);
        
        const char* xoffset=subElem->Attribute("xoffset");
        ufontData.xoffset=atof(xoffset);
        
        const char* yoffset=subElem->Attribute("yoffset");
        ufontData.yoffset=atof(yoffset);
        
        
        const char* xadvance=subElem->Attribute("xadvance");
        ufontData.xadvance=atof(xadvance);
        
        ufontData.infoFontSize=atoi(infoFontSize);
        
        if (strcmp(subElem->Attribute("letter"), "space") == 0) {
            
            ufontData.letter=" ";
            
        }
        else{
            
            ufontData.letter=subElem->Attribute("letter");
            
            if (strcmp(ufontData.letter,"y")==0||strcmp(ufontData.letter,"p")==0||strcmp(ufontData.letter,"g")==0||strcmp(ufontData.letter,"q")==0||strcmp(ufontData.letter,"j")==0) {
                
                ufontData.yoffset=yOffsetReScale+ufontData.yoffset;
                
            }
        }
        
        
        fontData.push_back(ufontData);
    }
    
}
</code>
</pre>

If you take a look at the XML produced by **Glyph Designer**, you will see that it contains several elements. These elements contains information about each letter, such as width, height and x-y coordinates. The method above goes through each of these elements and stores this information in a vector of type *FontData*.

##Creating a Font Class
Our next task is to create a class called *Font*. This class will be responsible for loading the font atlas image, parsing and rendering the text on the screen. 

### Loading the Texture Atlas Image
The atlas image produced by *Glyph Designer* will be loaded into a texture object. By now you should know how this is accomplished. Even though I won't go into detail on how a 2D image is loaded as a texture, I do present the code in listing 3.

#####Listing 3
<pre>
<code class="language-c">
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
    
    //18
   FontTextureUniformLocation=glGetUniformLocation(programObject, "FontTextureAtlasMap");
   
    //19. Offset uniform
   OffsetFontUniformLocation=glGetUniformLocation(programObject, "Offset");
    
    //25. Unbind the VAO
    glBindVertexArrayOES(0);
    
    //26. Sets the transformation
    setTransformation();
    
}
</code>
</pre>

The method *setupOpenGL()* is found in the *Font.mm* file. 

The method to load the font-atlas image is identical to loading any other 2D image. The only addition is the declaration of an *uniform* called *Offset* (line 19). This uniform will be used by the shaders to know the location of the letter.

### Parsing Text
The class *Font* contains a method called *setText()*. This method accepts as a parameter the string that will be rendered. When this method is called, it parses the string and retrieves the width, height and x-y coordinates of each letter. It then stores each letter of the string in a vector, *textContainer*, of type *TextData*.

The *setText()* is found in the *Font.mm* file and is shown in listing 4.

#####Listing 4
<pre>
<code class="language-c">
void Font::setText(const char* uText){
    
    text=uText;
    textContainer.clear(); //clear the text container
    
    //1. Parse the text and store the information into a vector
    for (int i=0; i&ltstrlen(text); i++) {
        
        for (int j=0; j&ltfontLoader->fontData.size(); j++) {
            
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
</code>
</pre>


### Rendering Text
Rendering the *text* is accomplished in the *drawText()* method found in *Font.mm*. For every letter in the *textContainer* vector, its information is retrieved. Aside from the width, height, the x-y coordinates are also retrieved. These coordinates are sent to the shader. It informs the shader where the letter resides in the atlas image. 

Listing 5 shows the *drawText()* method.

#####Listing 5
<pre>
<code class="language-c">

void Font::drawText(){


float lastTextYOffset=0.0;
float currentTextYOffset=0.0;
float lastTextXAdvance=0.0;

GLKMatrix4 initPosition=modelSpace;

//1. For every letter in the word, look for its information such as width, height, and coordinates and render it.
for (int i=0; i&lttextContainer.size(); i++) {

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
</code>
</pre>

An important method that is called during the rendering process is the *updateVertexObjectBuffer()*. Since each letter has different width and height, we need to update the vertex and UV buffers with the correct data. 

These data changes constantly, thus we use *glSubBufferData* to change its content.

Listing 6 shows the implementation of the *updateVertexObjectBuffer()* method.

#####Listing 6
<pre>
<code class="language-c">

void Font::updateVertexObjectBuffer(){

glBindVertexArrayOES(vertexArrayObject);

glBindBuffer(GL_ARRAY_BUFFER, vertexBufferObject);

glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(fontVertices), fontVertices);

glBufferSubData(GL_ARRAY_BUFFER, sizeof(fontVertices), sizeof(fontUVCoords), fontUVCoords);

}

</code>
</pre>

##Shaders
The shaders are simple. The only addition is the *Offset* uniform in the *vertex* shader. 

This offset is used to locate the letter in the font-atlas image.

Listing 7 shows the implementation of the *vertex* shader.

#####Listing 7

<pre>
<code class="language-c">

void main()
{
    
//4. recall that attributes can't be declared in fragment shaders. Nonetheless, we need the texture coordinates in the fragment shader. So we copy the information of "texCoord" to "vTexCoordinates", a varying type.

vTexCoordinates=vec2(texCoord.x+Offset.x,texCoord.y+Offset.y);

//5. transform every position vertex by the model-view-projection matrix
gl_Position = modelViewProjectionMatrix * position;

}

</code>
</pre>

##Running the code
Finally, create an instance of the *FontLoader* class. The constructor of this class requires the name of the image and xml file. Then create an instance of the *Font* class, call the *setFont()* method and provide a string text to the *setText()* method.

Listing 8 shows the method *(void)viewDidLoad* in the *ViewController.mm* file where this is implemented.

#####Listing 8
<pre>
<code class="language-c">
(void)viewDidLoad{

//...

 //6. Create Font Loader instance
    FontLoader *fontLoader=new FontLoader();
    fontLoader->loadFontAssetFile("ArialFont.xml","ArialFont.png");
    
    //7. Create Font instance
    font=new Font(fontLoader,100,200,view.frame.size.height,view.frame.size.width);
    
    font->setFont();
    
    //8. Set text to show
    font->setText("Aa");

}
</code>
</pre>

Run the code and you should see the letters *Aa* show up on the screen.

##### Figure 5 Rendering Text on a mobile device
![font in iphone](https://dl.dropboxusercontent.com/u/107789379/CGDemy/blogimages/fontIphone.png)


###Credits
[Harold Serrano](http://www.haroldserrano.com) Author of this repository and post

###Questions
If you have any questions about this repository, feel free to contact me at http://www.haroldserrano.com/contact/
