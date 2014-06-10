//
//  DiceGame.m
//  Liar's Dice
//
//  Created by Miller Tinkerhess on 10/4/11.
//  Copyright (c) 2012 University of Michigan. All rights reserved.
//

#import "DiceGame.h"

#import "ApplicationDelegate.h"
#import "DiceAction.h"
#import "PlayerState.h"
#import "PlayGame.h"
#import "DiceDatabase.h"
#import "GameRecord.h"
#import "HistoryItem.h"
#import "PlayGameView.h"
#import "SoarPlayer.h"

@implementation DiceGame

@synthesize gameState, players, appDelegate, gameView, started, deferNotification;

- (id)initWithAppDelegate:(ApplicationDelegate*)anAppDelegate
{
    self = [super init];

	if (self)
	{
		self.appDelegate = anAppDelegate;
		self.gameState = nil;
		started = NO;

		time = [DiceDatabase getCurrentGameTime];
		nextID = 0;

		self.players = [[NSArray alloc] init];

		shouldNotifyOfNewRound = NO;
	}

    return self;
}

- (void) dealloc
{
	NSLog(@"%@ deallocated", self.class);
}

-(DiceGame*)init
{
	return [self initWithAppDelegate:nil];
}

-(NSString*)gameNameString
{
	NSString* name = @"";

	for (id<Player> player in players)
	{
		if (![player isKindOfClass:SoarPlayer.class])
			name = [name stringByAppendingFormat:@"%@ vs ", [player getName]];
	}

	if ([name length] > 4)
		name = [name substringToIndex:[name length] - 4];

	return name;
}

-(NSString*)AINameString
{
	int AICount = 0;

	for (id<Player> player in players)
	{
		if ([player isKindOfClass:SoarPlayer.class])
			AICount++;
	}

	if (AICount > 0)
		return [NSString stringWithFormat:@"%i AIs", AICount];

	return [NSString string];
}

-(NSString*)lastTurnInfo
{
	return [[gameState lastHistoryItem] state];
}

// Encoding
-(id)initWithCoder:(NSCoder*)decoder
{
	self = [super init];

	if (self)
	{
		self.started = [decoder decodeBoolForKey:@"DiceGame:started"];
		self.deferNotification = [decoder decodeBoolForKey:@"DiceGame:deferNotification"];

		time.day = [decoder decodeIntForKey:@"DiceGame:time:day"];
		time.hour = [decoder decodeIntForKey:@"DiceGame:time:hour"];
		time.minute = [decoder decodeIntForKey:@"DiceGame:time:minute"];
		time.month = [decoder decodeIntForKey:@"DiceGame:time:month"];
		time.second = [decoder decodeIntForKey:@"DiceGame:time:second"];
		time.year = [decoder decodeIntForKey:@"DiceGame:time:year"];

		nextID = [decoder decodeIntForKey:@"DiceGame:nextID"];

		self.gameState = [decoder decodeObjectForKey:@"DiceGame:gameState"];
		self.gameState.game = self;

		if ([decoder containsValueForKey:@"NewRound"])
			shouldNotifyOfNewRound = YES;
	}

	return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeBool:started forKey:@"DiceGame:started"];
	[encoder encodeBool:deferNotification forKey:@"DiceGame:deferNotification"];
	[encoder encodeInt:time.day forKey:@"DiceGame:time:day"];
	[encoder encodeInt:time.hour forKey:@"DiceGame:time:hour"];
	[encoder encodeInt:time.minute forKey:@"DiceGame:time:minute"];
	[encoder encodeInt:time.month forKey:@"DiceGame:time:month"];
	[encoder encodeInt:time.second forKey:@"DiceGame:time:second"];
	[encoder encodeInt:time.year forKey:@"DiceGame:time:year"];

	[encoder encodeInt:nextID forKey:@"DiceGame:nextID"];

	[encoder encodeObject:gameState forKey:@"DiceGame:gameState"];

	if (gameState.lastHistoryItem.actionType == ACTION_CHALLENGE_BID ||
		gameState.lastHistoryItem.actionType == ACTION_CHALLENGE_PASS ||
		gameState.lastHistoryItem.actionType == ACTION_EXACT)
	{
		[encoder encodeBool:YES forKey:@"NewRound"];
	}
}

- (void)updateGame:(DiceGame *)remote
{
	if (!remote)
		return;

	shouldNotifyOfNewRound = remote->shouldNotifyOfNewRound;

	if (remote.players)
		self.players = [NSArray arrayWithArray:remote.players];

	id remoteAppDelegate = remote.appDelegate;
	if (remoteAppDelegate)
		appDelegate = remoteAppDelegate;

	id remoteGameView = remote.gameView;
	if (remoteGameView)
		gameView = remoteGameView;

	started = remote.started;
	deferNotification = remote.deferNotification;
	time = remote->time;
	nextID = remote->nextID;

	BOOL didAdvanceTurns = NO;

	if (remote.gameState)
	{
		if (remote.gameState.currentTurn != self.gameState.currentTurn)
			didAdvanceTurns = YES;

		if ([remote.gameState.history count] == 1 &&
			((HistoryItem*)[remote.gameState.history objectAtIndex:0]).historyType == metaHistoryItem &&
			[self.gameState.history count] > 1)
		{
			// Round over
			for (id <NewRoundListener> listener in self.gameState.theNewRoundListeners)
				[listener roundEnding];
		}

		self.gameState = remote.gameState;

		if (players)
			self.gameState.players = players;
	}

	[self publishState];

	if (didAdvanceTurns && ![[self.gameState getCurrentPlayer] isKindOfClass:DiceRemotePlayer.class])
		[self notifyCurrentPlayer];
}

- (void) setGameView:(PlayGameView*)aGameView
{
    gameView = aGameView;
    for (id <Player> player in self.players)
    {
        if ([player isKindOfClass:[DiceLocalPlayer class]])
        {
            ((DiceLocalPlayer*)player).gameView = self.gameView;
        }
    }
}

- (id <PlayGame>) gameView
{
    return gameView;
}

-(void)addPlayer:(id <Player>)player
{
    assert(!started);
    assert(players != nil);
    if ([player isKindOfClass:[DiceLocalPlayer class]])
    {
        ((DiceLocalPlayer*)player).gameView = self.gameView;
    }
    
    NSMutableArray *mut = [[NSMutableArray alloc] initWithArray:self.players];
    [mut addObject:player];
    self.players = [[NSArray alloc] initWithArray:mut];
    [player setID:[self getNextID]];
}

-(int)getNextID {
    return nextID++;
}

-(void)startGame
{
    if (self.started)
	{
		[self publishState];
		return;
	}

    self.started = YES;
    self.gameState = [[DiceGameState alloc] initWithPlayers:self.players numberOfDice:5 game:self];
		
    [self publishState];
    [self notifyCurrentPlayer];
}

-(void)publishState
{
    for (id <Player> player in players)
    {
        [player updateState:[gameState getPlayerState:[player getID]]];
    }

	if (shouldNotifyOfNewRound && self.gameView)
	{
		for (id <NewRoundListener> listener in self.gameState.theNewRoundListeners)
			[listener roundEnding];
		
		shouldNotifyOfNewRound = NO;
	}
}

-(void) notifyCurrentPlayer
{
    if ([self.gameState hasAPlayerWonTheGame]) {
            NSLog(@"Game over, no need to notify player");
        return;
    }
    NSLog(@"Notifying current player %@", [[gameState getCurrentPlayer] getName]);
    [[gameState getCurrentPlayer] itsYourTurn];
}

-(NSInteger)getNumberOfPlayers
{
    return [self.players count];
}

-(id <Player>)getPlayerAtIndex:(int)index
{
    return [self.players objectAtIndex:index];
}

-(void)handleAction:(DiceAction*)action
{
    NSLog(@"Handling action: %i", action.actionType);
    self.deferNotification = NO;

	self.gameState.game = self;

    switch (action.actionType)
    {
        case ACTION_BID:
        {
            NSString *playerName = [self.gameState getPlayerState:action.playerID].playerName;
            Bid *bid = [[Bid alloc] initWithPlayerID:action.playerID name:playerName dice:action.count rank:action.face];
            [gameState handleBid:action.playerID withBid:bid];
            [gameState handlePush:action.playerID withPush:action.push];
            break;
        }
        case ACTION_PASS:
        {
            [gameState handlePass:action.playerID andPushingDice:([action.push count] > 0)];
            [gameState handlePush:action.playerID withPush:action.push];
            break;
        }
        case ACTION_EXACT:
        {
            BOOL wasRight;
            [gameState handleExact:action.playerID andWasTheExactRight:&wasRight];
            break;
        }
        case ACTION_CHALLENGE_BID:
        case ACTION_CHALLENGE_PASS:
        {
            BOOL wonChallenge;
            [gameState handleChallenge:action.playerID againstTarget:action.targetID withFirstPlayerWonOrNot:&wonChallenge];
            break;
        }   
        case ACTION_PUSH:
        {
            [gameState handlePush:action.playerID withPush:action.push];
            break;
        }
        default:
        {
            return;
        }
    }
    [self publishState];
    if (!deferNotification) {
        [self notifyCurrentPlayer];
    }
}

- (void) end
{
    int numPlayers = (int)self.players.count; // Safe conversion due to player count being non-zero and never greater than 2 million something
    NSMutableArray *losers = self.gameState.losers;

    int places[] = {-1, -1, -1, -1, -1, -1, -1, -1};
	
	for (NSInteger i = [losers count];i > 0;i--)
	{
		NSNumber *loser = [losers objectAtIndex:i-1];
		places[i] = [loser intValue];
	}
	
    id <Player> winner = [gameState gameWinner];
    if (winner != nil) {
        places[0] = [winner getID];
    }
	
    GameRecord *record = [[GameRecord alloc]
                          initWithGameTime:time
                          NumPlayers:numPlayers
                          firstPlace:places[0]
                          secondPlace:places[1]
                          thirdPlace:places[2]
                          fourthPlace:places[3]];
    
    DiceDatabase *database = [[DiceDatabase alloc] init];
    [database addGameRecord:record];
    
    for (id <Player> player in self.players) {
        [player end];
    }
}

@end
