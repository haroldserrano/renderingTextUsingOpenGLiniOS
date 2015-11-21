//
//  ViewController.h
//  openglesinc
//
//  Created by Harold Serrano on 2/9/15.
//  Copyright (c) 2015 www.haroldserrano.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "Font.h"


@interface ViewController : GLKViewController{
    
    Font *font;
    
    float currentXTouchPoint;
    float currentYTouchPoint;
    
    bool touchBegan;
}

@property (strong, nonatomic) EAGLContext *context;

@end
