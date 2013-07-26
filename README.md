# Welcome to AMDoubleSlider

AMDoubleSlider is a two-headed slider similar to UISlider. It looks
just like a UISlider, but with two heads. Features:

* similar to UISlider
* displays a label above each handle
* the labels never overlap and the handles never cross
* can round to discrete values

AMDoubleSlider is an extraction from [Dwellable](http://dwellable.com).

![Screenshot](https://raw.github.com/gurgeous/AMDoubleSlider/master/screenshot.jpg)

## Install

Add AMDoubleSlider.h, AMDoubleSlider.m and AMDoubleSlider.bundle to your project.

## Example Usage

Check out [AppDelegate.m](https://github.com/gurgeous/AMDoubleSlider/blob/master/Demo/Demo/AppDelegate.m) in the Demo app. In the meantime, here's an example:

```objc
NSArray *data = @[ @"XS", @"S", @"M", @"L", @"XL", @"XXL" ];
AMDoubleSlider *sizes = [[AMDoubleSlider alloc] initWithFrame:CGRectMake(0, 0, 240, 60)];
sizes.boundsMin = 0;
sizes.boundsMax = data.count - 1;
sizes.labeler = ^NSString *(float value) {
    return data[(int)value];
};
sizes.rounder = ^(float value) {
    return roundf(value);
};
```

## Details

### Min and Max

The moving part of the slider is called the "handle". AMDoubleSlider has two handles, naturally. The value of each handle is a float between `boundsMin` and `boundsMax`. The left handle is called `min` and the right handle is called `max`.

### Rounding

Min and max are always floats, though often you want discrete values. For example, you might want to pick values between one and ten, or t-shirt sizes, etc. To map from floats to discrete values, specify a `rounder` block. If you specify a rounder, `min` and `max` will always be rounded when you access them. Examples:

```objc
// round to nearest ints
slider.rounder = ^(float value) {
    return roundf(value);
};

// multiples of fifty
slider.rounder = ^(float value) {
    return roundf(value / 50) * 50;
};
```

### Labeling

AMDoubleSlider draws a label above each handle so the user knows what's happening. Use the `labeler` property to map from values to labels. Note that the value passed into labeler is always rounded (via `rounder`) first. Examples:

```objc
// currency
slider.labeler = ^NSString *(float value) {
    return [NSString stringWithFormat:@"$%d", (int)value];
};

// show decimals
slider.labeler = ^NSString *(float value) {
    return [NSString stringWithFormat:@"%.1f", value];
};

// lookup from an array
slider.labeler = ^NSString *(float value) {
    return mylabels[(int)value];
};
```
