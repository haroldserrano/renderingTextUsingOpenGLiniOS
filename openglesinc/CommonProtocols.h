//
//  CommonProtocols.h
//  openglesinc
//
//  Created by Harold Serrano on 5/25/15.
//  Copyright (c) 2015 cgdemy.com. All rights reserved.
//

#ifndef openglesinc_CommonProtocols_h
#define openglesinc_CommonProtocols_h

typedef struct{
    
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

typedef struct{
    
    float x;
    float y;
    float width;
    float height;
    float xOffset;
    float yOffset;
    float xAdvance;
    const char* letter;
}TextData;


#endif
