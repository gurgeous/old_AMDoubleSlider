//
//  AMDoubleSlider.m
//
//  Created by Adam Doppelt on 07/25/13.
//  Copyright (c) 2013 Adam Doppelt. All rights reserved.
//

#import "AMDoubleSlider.h"

static const float gTextHeight = 13;
static const CGSize gHandleImageSize = { 35, 35 };
static const CGSize gBarImageSize = { 3, 2 };
static const UIEdgeInsets gPadding = { 8, 0, 4, 0 };

//
// some CG helpers
//

static CGRect CGRectInsetTop(CGRect r, float inset) {
    r.origin.y    += inset;
    r.size.height -= inset;
    return r;
}
static CGRect CGRectInsetWidth(CGRect r, float inset) {
    r.origin.x += inset;
    r.size.width -= inset * 2;
    return r;
}


@interface AMDoubleSlider () {
    // our three images
    UIImage *_gray;
    UIImage *_blue;
    UIImage *_handle;

    // current handle positions (from 0..1)
    float _pos[2];

    // which handle is being pressed? 0/1, or -1 if nothing is pressed
    int _pressed;

    // where did the user start touching?
    float _touchX;

    // where was the handle when the user started touching?
    float _touchPos;
}

- (void)commonInit;
- (float)floatToBounds:(float)value;
- (float)boundsToFloat:(float)value;
@end

@implementation AMDoubleSlider

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    CGRect frame = self.frame;
    frame.size.height = gPadding.top + gTextHeight + gHandleImageSize.height + gPadding.bottom;
    self.frame = frame;
    self.backgroundColor = UIColor.clearColor;
    self.opaque = NO;

    // default to 0..1
    _boundsMin = _pos[0] = 0;
    _boundsMax = _pos[1] = 1;

    // nothing being pressed at the moment
    _pressed = -1;

    // load images
    _gray = [[UIImage imageNamed:@"AMDoubleSlider.bundle/gray.png"] stretchableImageWithLeftCapWidth:1 topCapHeight:0];
    _blue = [[UIImage imageNamed:@"AMDoubleSlider.bundle/blue.png"] stretchableImageWithLeftCapWidth:1 topCapHeight:0];
    _handle = [UIImage imageNamed:@"AMDoubleSlider.bundle/handle.png"];
    
    // default labeler
    _labeler = ^NSString *(float value) {
        return [NSString stringWithFormat:@"%.2f", value];
    };
}

- (float)floatToBounds:(float)value
{
    value = value * (_boundsMax - _boundsMin) + _boundsMin;
    if (_rounder) {
        value = _rounder(value);
    }
    return value;
}

- (float)boundsToFloat:(float)value
{
    return (value - _boundsMin) / (_boundsMax - _boundsMin);
}

//
// current values
//

- (float)min
{
    return [self floatToBounds:_pos[0]];
}

- (float)max
{
    return [self floatToBounds:_pos[1]];
}

- (void)setMin:(float)min
{
    _pos[0] = [self boundsToFloat:min];
    [self setNeedsDisplay];
}

- (void)setMax:(float)max
{
    _pos[1] = [self boundsToFloat:max];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect bounds = self.bounds;

    //
    // PADDING
    //

    CGContextTranslateCTM(context, gPadding.left, gPadding.top);
    bounds.size.width -= gPadding.left + gPadding.right;
    bounds.size.height -= gPadding.top + gPadding.bottom;

    //
    // Calculate bar left and right pixel coordinates. This corresponds to the
    // 0..1 of _pos. We have to inset HANDLE.size because the handles are
    // centered on the bar. From here on out, the origin correponds to 0 and
    // bounds.width corresponds to 1.
    //

    CGContextTranslateCTM(context, gHandleImageSize.width / 2, 0);
    bounds.size.width -= gHandleImageSize.width;

    int pixels[2];
    for (int i = 0; i <= 2; ++i) {
        pixels[i] = _pos[i] * bounds.size.width;
    }

    // the box includes the complete handles, all text, the bar, etc.
    CGRect box = CGRectInsetWidth(bounds, -gHandleImageSize.width / 2);

    //
    // labels
    //

    UIFont *font = [UIFont systemFontOfSize:10];
    NSString *strings[2];
    CGRect rects[2];
    
    // calculate strings and naive rects
    for (int i = 0; i < 2; ++i) {
        strings[i] = _labeler([self floatToBounds:_pos[i]]);
        
        CGSize size = [strings[i] sizeWithAttributes:@{NSFontAttributeName: font}];
        rects[i] = CGRectMake(pixels[i] - size.width / 2, 0, size.width, size.height);
        
        // a little hack to make currency look better
        if ([strings[i] characterAtIndex:0] == '$') {
            rects[i].origin.x -= 2;
        }
    }
    
    // adjust rectangles to not overlap
    static const int BETWEEN = 7;
    rects[0].origin.x = MAX(rects[0].origin.x, box.origin.x); // 0: left edge
    rects[1].origin.x = MAX(rects[1].origin.x, rects[0].origin.x + rects[0].size.width + BETWEEN); // 1: between
    rects[1].origin.x = MIN(rects[1].origin.x, CGRectGetMaxX(box) - rects[1].size.width); // 1: right edge
    rects[0].origin.x = MIN(rects[0].origin.x, rects[1].origin.x - rects[0].size.width - BETWEEN); // 0: right edge
    
    // now draw the labels
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    style.lineBreakMode = NSLineBreakByClipping;
    NSDictionary *attributes = @{ NSForegroundColorAttributeName: UIColor.blackColor, NSFontAttributeName: font, NSParagraphStyleAttributeName: style };
    for (int i = 0; i < 2; ++i) {
        [strings[i] drawInRect:rects[i] withAttributes:attributes];
    }

    bounds = CGRectInsetTop(bounds, gTextHeight);
    CGContextTranslateCTM(context, 0, gTextHeight);

    //
    // bar
    //
    // The gray bar actually draws full width, with a slight inset.
    //

    float y = (gHandleImageSize.height - gBarImageSize.height) / 2;
    static const int BAR_INSET = 10;
    CGRect gray = CGRectInsetWidth(box, BAR_INSET);
    [_gray drawInRect:CGRectMake(gray.origin.x, y, gray.size.width,       gBarImageSize.height)];
    [_blue drawInRect:CGRectMake(pixels[0],     y, pixels[1] - pixels[0], gBarImageSize.height)];

    //
    // handles
    //

    int onTop = (_pressed == -1) ? 1 : _pressed;
    [_handle drawAtPoint:CGPointMake(pixels[1 - onTop] - gHandleImageSize.height / 2, 0)];
    [_handle drawAtPoint:CGPointMake(pixels[onTop]     - gHandleImageSize.height / 2, 0)];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    static const float MARGIN = 40;
 
    // we're VERY generous with touches :)
    CGRect f = CGRectInset(self.bounds, -MARGIN, -MARGIN);
    return CGRectContainsPoint(f, point) == 1 ? self : nil;
}

-(BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    static const float FINGER = 50;

    // are we touching anything?
    CGPoint touchPoint = [touch locationInView:self];
    float w = self.bounds.size.width - gPadding.left - gPadding.right - gHandleImageSize.width;

    float d[2];
    for (int i = 0; i < 2; ++i) {
        d[i] = fabs((gHandleImageSize.width / 2) + (w * _pos[i]) - touchPoint.x);
    }
    int closest = (d[0] < d[1]) ? 0 : 1;
    if (d[closest] > FINGER) {
        // too far
        _pressed = -1;
        [self cancelTrackingWithEvent:event];
        return NO;
    }

    // record start of drag
    _pressed = closest;
    _touchX = touchPoint.x;
    _touchPos = _pos[_pressed];
    [self setNeedsDisplay];

    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    static const float BETWEEN = 10;

    CGPoint touchPoint = [touch locationInView:self];
    float w = self.bounds.size.width - gPadding.left - gPadding.right - gHandleImageSize.width;
    float p = _touchPos + (touchPoint.x - _touchX) / w;

    float l = _pos[0];
    float r = _pos[1];
    float between = BETWEEN / w;

    if (_pressed == 0) {
        // dragging left handle - bound
        l = MAX(p, 0);
        if (r - l < between) {
            r = MIN(l + between, 1.0f);
            l = r - between;
        }
    } else {
        // dragging right handle - bound
        r = MIN(p, 1.0f);
        if (r - l < between) {
            l = MAX(r - between, 0);
            r = l + between;
        }

    }
    _pos[0] = l;
    _pos[1] = r;

    [self setNeedsDisplay];
    return YES;
}

-(void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    _pressed = -1;
    [self setNeedsDisplay];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

@end
