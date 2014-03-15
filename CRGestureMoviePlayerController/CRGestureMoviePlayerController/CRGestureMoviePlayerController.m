//
//  CRGestureMoviePlayerController.m
//  CRGestureMoviePlayerController
//
//  Created by croath on 3/15/14.
//  Copyright (c) 2014 Croath. All rights reserved.
//

#import "CRGestureMoviePlayerController.h"

@interface CRGestureMoviePlayerController(){
    BOOL _inFullScreen;
    UIPanGestureRecognizer *_pan;
    
    CGPoint _lastPoint;
    BOOL _startChange;
    BOOL _changeVolume;
}

@end

@implementation CRGestureMoviePlayerController

- (id)initWithContentURL:(NSURL *)url{
    self =[super initWithContentURL:url];
    if (self) {
        
        self.view.backgroundColor = [UIColor clearColor];
        self.initialPlaybackTime = -1;
        self.endPlaybackTime = -1;
        [self prepareToPlay];
        [self play];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterFullScreen:)
                                                     name:MPMoviePlayerWillEnterFullscreenNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(leaveFullScreen:)
                                                     name:MPMoviePlayerWillExitFullscreenNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - full screen controller

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    return YES;
}

- (void)handlePan:(UIPanGestureRecognizer*)rec{
    if (_inFullScreen) {
        if (rec.state == UIGestureRecognizerStateBegan) {
            _lastPoint = [rec locationInView:self.view];
        } else if (rec.state == UIGestureRecognizerStateChanged) {
            CGPoint nowPoint = [rec locationInView:self.view];
            
            if (_startChange == NO) {
                if (fabs(nowPoint.y - _lastPoint.y) > fabs(nowPoint.x - _lastPoint.x)) {
                    _changeVolume = NO;
                } else {
                    _changeVolume = YES;
                }
                _startChange = YES;
            } else {
                if (_changeVolume) {
                    //change volume
                    float volume = [[MPMusicPlayerController applicationMusicPlayer] volume];
                    float newVolume = volume;
                    
                    if (nowPoint.x == _lastPoint.x) {
                        
                    } else {
                        if (nowPoint.x < _lastPoint.x) {
                            newVolume += 0.01;
                        } else {
                            newVolume -= 0.01;
                        }
                    }
                    
                    if (newVolume < 0) {
                        newVolume = 0;
                    } else if (newVolume > 1.0) {
                        newVolume = 1.0;
                    }
                    
                    [[MPMusicPlayerController applicationMusicPlayer] setVolume:newVolume];
                } else {
                    //change playback state
                    if (self.playbackState != MPMoviePlaybackStateSeekingForward &&
                        self.playbackState != MPMoviePlaybackStateSeekingBackward) {
                        if (nowPoint.y == _lastPoint.y) {
                            
                        } else {
                            if (nowPoint.y < _lastPoint.y) {
                                [self beginSeekingForward];
                            } else {
                                [self beginSeekingBackward];
                            }
                        }
                        _lastPoint = nowPoint;
                    }
                }
                
            }
            
        } else if (rec.state == UIGestureRecognizerStateCancelled ||
                   rec.state == UIGestureRecognizerStateEnded ||
                   rec.state == UIGestureRecognizerStateFailed){
            _startChange = NO;
            [self endSeeking];
        }
    }
}

- (void)enterFullScreen:(NSNotification*)notification{
    _inFullScreen = YES;
    
    _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _pan.delegate = self;
    
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] addGestureRecognizer:_pan];
}

- (void)leaveFullScreen:(NSNotification*)notification{
    _inFullScreen = NO;
    [[[[UIApplication sharedApplication] windows] objectAtIndex:0] removeGestureRecognizer:_pan];
}
@end
