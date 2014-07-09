//
//  RoundOverView.m
//  Liars Dice
//
//  Created by Miller Tinkerhess on 3/30/12.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "RoundOverView.h"
#import "HistoryItem.h"
#import "Die.h"
#import "DiceGraphics.h"

#import "SoarPlayer.h"

@implementation RoundOverView

@synthesize game, player, playGameView;
@synthesize titleLabel;
@synthesize diceView;
@synthesize doneButton;
@synthesize transparencyLevel;

- (id) initWithGame:(DiceGame*) aGame player:(PlayerState*)aPlayer playGameView:(PlayGameView *)aPlayGameView withFinalString:(NSString*)finalString2
{
	NSString* device = [UIDevice currentDevice].model;
	device = [[[device componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]] objectAtIndex:0];

	if ([device isEqualToString:@"iPhone"])
		device = @"";

	self = [super initWithNibName:[@"RoundOverView" stringByAppendingString:device] bundle:nil];

	if (self) {
        self.game = aGame;
        self.player = aPlayer;
        self.playGameView = aPlayGameView;
		iPad = [device length] != 0;
		finalString = finalString2;
		
		previousBidImageViews = [[NSMutableArray alloc] init];

		self.accessibilityLabel = @"Round Over";
		self.accessibilityHint = @"The round is over, this screen is displaying a list of the dice your opponents had.";
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

	PlayGameView* playGameViewLocal = self.playGameView;

	UIImage* snapshot = [playGameViewLocal blurredSnapshot];
	[self.transparencyLevel setImage:snapshot];

    titleLabel.text = finalString;
	titleLabel.accessibilityLabel = [playGameViewLocal accessibleTextForString:titleLabel.text];

	NSArray* lines = [finalString componentsSeparatedByString:@"\n"];

	NSError* error = nil;
	NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"[1-6]s" options:0 error:&error];

	CGSize constrainedSize = CGSizeMake(titleLabel.frame.size.width, 9999);
	NSDictionary* attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:titleLabel.font, NSFontAttributeName, nil];

	CGFloat y2 = 0;

	if ([lines count] == 4)
		y2 += [[lines objectAtIndex:0] boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.height + 5;

	CGRect titleFrame = titleLabel.frame;

	for (int i = 0;i < [lines count];i++)
	{
		NSString* line = [lines objectAtIndex:i];

		NSArray* matches = [regex matchesInString:line options:0 range:NSMakeRange(0, [line length])];

		assert([matches count] <= 1);

		if ([matches count] == 1) // Should only ever be one!
		{
			NSTextCheckingResult* result = [matches objectAtIndex:0];
			CGFloat x = -1;

			NSString* before = [line substringToIndex:[result range].location];
			x += [before boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.width;

			int number = [line characterAtIndex:result.range.location] - '0';

			UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, y2, 20, 20)];
			[imageView setImage:[playGameViewLocal imageForDie:number]];

			[titleLabel addSubview:imageView];
		}

		y2 += [line boundingRectWithSize:constrainedSize options:NSStringDrawingUsesLineFragmentOrigin attributes:attributesDictionary context:nil].size.height;
	}

	titleFrame.size.height = y2;
	titleLabel.frame = titleFrame;

	DiceGame* gameLocal = self.game;
	PlayerState* playerLocal = self.player;

    NSArray *playerStates = gameLocal.gameState.playerStates;
    int i = -1;
    int labelHeight = 64 / 2;
    int diceHeight = 96 / 2;
    int dividerHeight = 8 / 2;
    int starSize = 64 / 2;
    int pushAmount = 0;
    int dy = labelHeight + diceHeight + dividerHeight + pushAmount;
	
	BOOL displayedPlayer = NO;
	
    for (PlayerState *playerState in playerStates)
    {
        if ([playerState.arrayOfDice count] == 0)
        {
            // continue;
        }
        ++i;
                
        int labelIndex = (displayedPlayer ? i : i + 1);

		if (playerState.playerID == playerLocal.playerID)
		{
			displayedPlayer = YES;
			labelIndex = 0;
		}
        
        int x = 0;
        int y = labelIndex * dy;
        int width = diceView.frame.size.width;
		
        CGRect dividerRect = CGRectMake(x, y, width, dividerHeight);
        UIImage *dividerImage = [self barImage];
        UIImageView *barView = [[UIImageView alloc] initWithImage:dividerImage];
        barView.frame = dividerRect;
        [diceView addSubview:barView];
        y += dividerHeight;
        
        
        CGRect nameLabelRect = CGRectMake(x + starSize, y, width - starSize, labelHeight);
        UILabel *nameLabel = [[UILabel alloc] initWithFrame:nameLabelRect];
        nameLabel.backgroundColor = [UIColor clearColor];
        nameLabel.text = [[gameLocal.players objectAtIndex:playerState.playerID] getDisplayName];
		[nameLabel setTextColor:[UIColor whiteColor]];
        [diceView addSubview:nameLabel];
        x = 0; // = x + width - starSize;
        y += labelHeight;
        CGRect diceFrame = CGRectMake(x, y, width, diceHeight + pushAmount);
        UIView *diceStrip = [[UIView alloc] initWithFrame:diceFrame];
        int dieSize = (diceStrip.frame.size.width) / 5;
        if (dieSize > diceHeight)
        {
            dieSize = diceHeight;
        }
        for (int dieIndex = 0; dieIndex < [playerState.arrayOfDice count]; ++dieIndex)
        {
            x = dieIndex * (dieSize);
            int dieY = 0;
            Die *die = [playerState getDie:dieIndex];
            if (!(die.hasBeenPushed || die.markedToPush)) {
                dieY = pushAmount;
            }
            CGRect dieFrame = CGRectMake(x, dieY, dieSize, dieSize);
            UIImage *dieImage = [playGameViewLocal imageForDie:die.dieValue];

            UIImageView *dieView = [[UIImageView alloc] initWithFrame:dieFrame];
            [dieView setImage:dieImage];

			NSString* name = nil;

			if (i == 0)
				name = @"Your";
			else
				name = [NSString stringWithFormat:@"%@'s", playerLocal.playerName];

			dieView.accessibilityLabel = [NSString stringWithFormat:@"%@ Die, Face Value of %i", name, die.dieValue];
			dieView.isAccessibilityElement = YES;

            [diceStrip addSubview:dieView];
        }
        [diceView addSubview:diceStrip];
    }

	[diceView setContentSize:CGSizeMake(diceView.frame.size.width, dy * [playerStates count])];
}

- (void)viewDidAppear:(BOOL)animated
{
	UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,
                                    self.titleLabel);
}

- (void)scrollViewDidScroll:(UIScrollView *)aScrollView
{
    [aScrollView setContentOffset: CGPointMake(0, aScrollView.contentOffset.y)];
}

- (IBAction)donePressed:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];

	PlayGameView* gameView = self.playGameView;
	if (gameView.overView)
	{
		[UIView animateWithDuration:0.25 animations:^{
			gameView.overView.view.frame = CGRectMake(gameView.overView.view.frame.origin.x,
													  gameView.overView.view.frame.size.height,
													  gameView.overView.view.frame.size.width,
													  gameView.overView.view.frame.size.height);
		}];

		[gameView.overView.view removeFromSuperview];
		gameView.overView = nil;
	}

	DiceGame* gameLocal = self.game;
	PlayerState* playerLocal = self.player;
	PlayGameView* playGameViewLocal = self.playGameView;

	gameLocal.gameState.canContinueGame = YES;

    if ([gameLocal.gameState usingSpecialRules]) {
        NSString *title = [NSString stringWithFormat:@"Special Rules!"];
        NSString *message = @"For this round: 1s aren't wild. Only players with one die may change the bid face."; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:nil
                                               cancelButtonTitle:@"Okay"
                                               otherButtonTitles:nil];
        // alert.tag = ACTION_QUIT;
        [alert show];
    }
    else if ([playerLocal hasWon]) {
        NSString *title = [NSString stringWithFormat:@"You Win!"];
        //NSString *message = @"For this round: 1s aren't wild. Only players with one die may change the bid face."; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                         message:nil
                                                        delegate:playGameViewLocal
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"Okay", nil];
        alert.tag = ACTION_QUIT;
        [alert show];
    }
    else if ([gameLocal.gameState hasAPlayerWonTheGame]) {
        NSString *title = [NSString stringWithFormat:@"%@ Wins!", [gameLocal.gameState.gameWinner getDisplayName]];
        //NSString *message = @"For this round: 1s aren't wild. Only players with one die may change the bid face."; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                         message:nil
                                                        delegate:playGameViewLocal
                                               cancelButtonTitle:nil
                                               otherButtonTitles:@"Okay", nil];
        alert.tag = ACTION_QUIT;
        [alert show];
	}
    else if ([playerLocal hasLost] && !playGameViewLocal.hasPromptedEnd) {
        playGameViewLocal.hasPromptedEnd = YES;
        NSString *title = [NSString stringWithFormat:@"You Lost the Game"];
        NSString *message = @"Quit or keep watching?"; // (push == nil || [push count] == 0) ? nil : [NSString stringWithFormat:@"And push %d dice?", [push count]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                         message:message
                                                        delegate:playGameViewLocal
                                               cancelButtonTitle:@"Watch"
                                               otherButtonTitles:@"Quit", nil];
        alert.tag = ACTION_QUIT;
        [alert show];
    }

	PlayerState* playerState = [[gameLocal.gameState lastHistoryItem] player];

	if (![[gameLocal.players objectAtIndex:[playerState playerID]] isKindOfClass:SoarPlayer.class] &&
		gameLocal.newRound == YES &&
		[playerState playerID] != [playerLocal playerID])
	{
		NSString* playerName = [[gameLocal.players objectAtIndex:[playerState playerID]] getDisplayName];
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Please Wait"
														message:[NSString stringWithFormat:@"Please wait until %@ has finished looking at the round overview.", playerName]
													   delegate:nil
											  cancelButtonTitle:@"Okay"
											  otherButtonTitles:nil];
		[alert show];
	}

//	if (gameView->shouldNotifyCurrentPlayer)
//		[gameLocal notifyCurrentPlayer];
}

- (UIImage*)barImage
{
	CGSize size = CGSizeMake(1, 1);
	UIGraphicsBeginImageContextWithOptions(size, YES, 0);
	[[UIColor whiteColor] setFill];
	UIRectFill(CGRectMake(0, 0, size.width, size.height));
	UIImage *barImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	return barImage;
}

@end
