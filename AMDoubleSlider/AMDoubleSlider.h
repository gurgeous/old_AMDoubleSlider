//
//  AMDoubleSlider.h
//
//  Created by Adam Doppelt on 07/25/13.
//  Copyright (c) 2013 Adam Doppelt. All rights reserved.
//

typedef NSString *(^Labeler)(float value);
typedef float (^Rounder)(float value);

@interface AMDoubleSlider : UIControl

// the current value (min)
@property float min;

// the current value (max)
@property float max;

// the minimum value allowed by the slider
@property float boundsMin;

// the maximum value allowed by the slider
@property float boundsMax;

// a block that turns values into strings for display
@property (copy) Labeler labeler;

// A block that rounds raw values before setting min/max or calling labeler. Use
// this if you want to deal with discrete values instead of raw floats.
@property (copy) Rounder rounder;

@end
