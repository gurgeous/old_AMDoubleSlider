//
//  AppDelegate.m
//  Demo
//
//  Created by Adam Doppelt on 7/25/13.
//  Copyright (c) 2013 Adam Doppelt. All rights reserved.
//

#import "AppDelegate.h"
#import "AMDoubleSlider.h"

//
// a simple controller for testing the slider
//

@interface MainViewController : UIViewController
- (void)changed:(AMDoubleSlider *)slider;
@end

@implementation MainViewController

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view.backgroundColor = [UIColor whiteColor];

    //
    // XS S M L XL XXL
    //

    NSArray *data = @[ @"XS", @"S", @"M", @"L", @"XL", @"XXL" ];
    AMDoubleSlider *sizes = [[AMDoubleSlider alloc] initWithFrame:CGRectMake(40, 80, 240, 60)];
    sizes.boundsMin = 0;
    sizes.boundsMax = data.count - 1;
    sizes.rounder = ^(float value) {
        return roundf(value);
    };
    sizes.labeler = ^NSString *(float value) {
        return data[(int)value];
    };
    [self.view addSubview:sizes];

    //
    // from $100-$1000 by multiples of 50
    //

    AMDoubleSlider *dollars = [[AMDoubleSlider alloc] initWithFrame:CGRectMake(40, 180, 240, 60)];
    dollars.boundsMin = 100;
    dollars.boundsMax = 1000;
    dollars.rounder = ^(float value) {
        return roundf(value / 50) * 50;
    };
    dollars.labeler = ^NSString *(float value) {
        return [NSString stringWithFormat:@"$%d", (int)value];
    };
    [self.view addSubview:dollars];

    //
    // a raw float
    //

    AMDoubleSlider *raw = [[AMDoubleSlider alloc] initWithFrame:CGRectMake(40, 280, 240, 60)];
    [self.view addSubview:raw];

    for (UIView *i in self.view.subviews) {
        AMDoubleSlider *slider = (AMDoubleSlider *)i;
        [slider addTarget:self action:@selector(changed:) forControlEvents:UIControlEventValueChanged];
        slider.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    }
}

- (void)changed:(AMDoubleSlider *)slider
{
    NSLog(@"changed %f-%f", slider.min, slider.max);
}

@end



@interface AppDelegate () {
    UIWindow *_window;
}
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _window.rootViewController = [[MainViewController alloc] init];
    [_window makeKeyAndVisible];
    return YES;
}

@end
