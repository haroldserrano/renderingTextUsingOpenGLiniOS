//
//  FontLoader.h
//  openglesinc
//
//  Created by Harold Serrano on 5/25/15.
//  Copyright (c) 2015 www.haroldserrano.com. All rights reserved.
//

#ifndef __openglesinc__FontLoader__
#define __openglesinc__FontLoader__

#include <stdio.h>
#include <iostream>
#include <vector>
#include <string>
#include "CommonProtocols.h"

#include "tinyxml2.h"

using namespace std;
using namespace tinyxml2;


class FontLoader{
    
private:
    
    XMLDocument doc;
    
public:
    
    FontLoader(){};
    
    ~FontLoader(){};
    
    vector<FontData> fontData;
    
    string fontAtlasImage;
    
    float fontAtlasWidth;
    
    float fontAtlasHeight;
    
    void loadFont();
    
    void loadFontAssetFile(string uFontAtlasFile,string uFontAtlasImage);
    
};

#endif /* defined(__openglesinc__FontLoader__) */
