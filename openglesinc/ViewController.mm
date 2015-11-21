//
//  ViewController.m
//  openglesinc
//
//  Created by Harold Serrano on 2/9/15.
//  Copyright (c) 2015 www.haroldserrano.com. All rights reserved.
//

#import "ViewController.h"
#include "FontLoader.h"
#include "Font.h"
#include <string>

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //1, Allocate a EAGLContext object and initialize a context with a specific version.
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    //2. Check if the context was successful
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    //3. Set the view's context to the newly created context
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    glViewport(0, 0, view.frame.size.height, view.frame.size.width);
    
    //4. This will call the rendering method glkView 60 Frames per second
    view.enableSetNeedsDisplay=60.0;
    
    //5. Make the newly created context the current context.
    [EAGLContext setCurrentContext:self.context];
    

    //6. Create Font Loader instance
    FontLoader *fontLoader=new FontLoader();
    fontLoader->loadFontAssetFile("ArialFont.xml","ArialFont.png");
    
    //7. Create Font instance
    font=new Font(fontLoader,100,200,view.frame.size.height,view.frame.size.width);
    
    font->setFont();
    
    //8. Set text to show
    font->setText("Aa");
    
  
    
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
   
    
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    //1. Clear the color to black
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    
    //2. Clear the color buffer and depth buffer
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    
    font->drawText();
    
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    for (UITouch *myTouch in touches) {
        CGPoint touchPosition = [myTouch locationInView: [myTouch view]];
        
        touchBegan=true;
       
        float xPoint=(touchPosition.x-self.view.bounds.size.width/2)/(self.view.bounds.size.width/2);
        float yPoint=(self.view.bounds.size.height/2-touchPosition.y)/(self.view.bounds.size.height/2);
        
        currentXTouchPoint=xPoint;
        currentYTouchPoint=yPoint;
        
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
    for (UITouch *myTouch in touches) {
        CGPoint touchPosition = [myTouch locationInView: [myTouch view]];
        
        touchBegan=false;
        currentXTouchPoint=0.0;
        currentYTouchPoint=0.0;
        
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    for (UITouch *myTouch in touches) {
        CGPoint touchPosition = [myTouch locationInView: [myTouch view]];
        
        currentXTouchPoint=touchPosition.x;
        currentYTouchPoint=touchPosition.y;
        
    }
}

- (void)dealloc
{
    //call teardown
    font->teadDownOpenGL();
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    [_context release];
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        //call teardown
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
    
    // Dispose of any resources that can be recreated.
}



@end
