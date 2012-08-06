//
//  DiceApplicationDelegate.m
//  Lair's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "DiceApplicationDelegate.h"

#import "DiceMainMenu.h"

@implementation DiceApplicationDelegate
@synthesize rootViewController;

@synthesize mainMenu, window, navigationController;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void) applicationDidFinishLaunching:(UIApplication *)application
{
    self.mainMenu = [[[DiceMainMenu alloc] initWithAppDelegate:self] autorelease];
//    self.window.rootViewController = self.mainMenu;
//    [self.window makeKeyAndVisible];

    self.navigationController = [[[UINavigationController alloc] initWithRootViewController:self.rootViewController] autorelease];

    self.navigationController.navigationBarHidden = YES;
    self.rootViewController.wantsFullScreenLayout = YES;
    
    [self.navigationController pushViewController:self.mainMenu animated:NO];
    
    [self.window addSubview:self.navigationController.view];
}

- (void)dealloc {
    [super dealloc];
}

@end