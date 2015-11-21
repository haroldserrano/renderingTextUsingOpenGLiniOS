//
//  Shader.fsh
//  openglesinc
//
//  Created by Harold Serrano on 2/9/15.
//  Copyright (c) 2015 www.roldie.com. All rights reserved.
//
precision highp float;

//1. declare a uniform sampler2D that contains the texture data for the non-pressed button image
uniform sampler2D FontTextureAtlasMap;

//2. declare varying type which will transfer the texture coordinates from the vertex shader
varying mediump vec2 vTexCoordinates;

void main()
{
    
//3. set the output of the fragment shader to the non-pressed button image sample
gl_FragColor=texture2D(FontTextureAtlasMap,vTexCoordinates.st);
        
}