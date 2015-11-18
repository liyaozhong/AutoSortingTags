//
//  OrderViewController.m
//  test
//
//  Created by joshuali on 15/11/17.
//  Copyright © 2015年 aixuehuisi. All rights reserved.
//

#import "OrderViewController.h"
#import "TagItem.h"

#define COLUM_NUM  4
#define ROW_NUM    5

@interface OrderViewController ()
{
    CGFloat gap;
    CGFloat itemWidth;
    TagItem * curDraggingTag;
    TagItem * detectingTag;
    CGPoint startDraggingOrigin;
    NSInteger curIndex;
    NSInteger detectingIndex;
}
@property (nonatomic, strong) NSMutableArray * tags;
@end

@implementation OrderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.tags = [NSMutableArray array];
    gap = 20;
    itemWidth = ([UIScreen mainScreen].bounds.size.width - 50 - 20 * (COLUM_NUM - 1)) / COLUM_NUM;
    for(int i = 0 ; i < ROW_NUM ; i ++){
        for(int j = 0 ; j < COLUM_NUM ; j ++){
            TagItem * tag = [TagItem new];
            tag.desOrigin = CGPointMake(25 + (gap + itemWidth) * j, 50 + (gap + itemWidth) * i);
            tag.center = CGPointMake(tag.desOrigin.x + itemWidth/2, tag.desOrigin.y + itemWidth/2);
            tag.view = [[UILabel alloc] initWithFrame:CGRectMake(tag.desOrigin.x, tag.desOrigin.y, itemWidth, itemWidth)];
            tag.view.backgroundColor = [UIColor colorWithRed: 20 * (i + 1) * (j + 1) / 255.0f green:20 * (ROW_NUM-i) * (COLUM_NUM-j) / 255.0f blue:20 * (i + 1) * (j + 1) / 255.0f alpha:1];
            [self.tags addObject:tag];
            [self.view addSubview:tag.view];
            tag.view.font = [UIFont systemFontOfSize:17];
            tag.view.text = [NSString stringWithFormat:@"%i", i * COLUM_NUM + j];
            tag.view.textAlignment = NSTextAlignmentCenter;
            tag.view.layer.cornerRadius = itemWidth/2;
            tag.view.layer.masksToBounds = YES;
        }
    }
}

CGFloat distanceBetweenPoints (CGPoint first, CGPoint second) {
    CGFloat deltaX = second.x - first.x;
    CGFloat deltaY = second.y - first.y;
    return sqrt(deltaX*deltaX + deltaY*deltaY );
};

- (void) startOrderAnim : (TagItem *) targetTag index : (NSInteger) targetIndex
{
    CGPoint tmpPoint = CGPointMake(targetTag.center.x, targetTag.center.y);
    curDraggingTag.center = CGPointMake(tmpPoint.x, tmpPoint.y);
    
    BOOL forward = curIndex > targetIndex;
    NSMutableArray * tags = [NSMutableArray arrayWithArray:[self.tags subarrayWithRange:NSMakeRange(forward ? targetIndex : curIndex, labs(targetIndex - curIndex) + 1)]];
    if(forward){
        id cur = [tags lastObject];
        [tags insertObject:cur atIndex:0];
        [tags removeLastObject];
    }else{
        id cur = [tags firstObject];
        [tags addObject:cur];
        [tags removeObjectAtIndex:0];
    }
    [self.tags replaceObjectsInRange:NSMakeRange(forward ? targetIndex : curIndex, labs(targetIndex - curIndex) + 1) withObjectsFromArray:tags];
    NSInteger tmpCurIndex = curIndex;
    curIndex = targetIndex;
        for(NSInteger i = MIN(tmpCurIndex, targetIndex); i <= MAX(tmpCurIndex, targetIndex); i ++){
            if(i == curIndex){
                continue;
            }
            [UIView animateWithDuration:ANIM_DURATION animations:^{
                [UIView setAnimationDelay:ANIM_DURATION / (MAX(tmpCurIndex, targetIndex) - MIN(tmpCurIndex, targetIndex)) * (forward ? MAX(tmpCurIndex, targetIndex) - i : i - MIN(tmpCurIndex, targetIndex))];
                TagItem * tag = [self.tags objectAtIndex:i];
                tag.desOrigin = CGPointMake(25 + (gap + itemWidth) * (i % COLUM_NUM), 50 + (gap + itemWidth) * (i / COLUM_NUM));
                tag.center = CGPointMake(tag.desOrigin.x + itemWidth/2, tag.desOrigin.y + itemWidth/2);
                tag.view.frame = CGRectMake(tag.desOrigin.x, tag.desOrigin.y, itemWidth, itemWidth);
                tag.view.text = [NSString stringWithFormat:@"%li", (long)i];
            }
            completion:^(BOOL finished) {
                             }];
    }
}

- (void) detectHanging
{
    if(distanceBetweenPoints(detectingTag.center, curDraggingTag.view.center) < itemWidth / 2){
        [self startOrderAnim:detectingTag index:detectingIndex];
    }
    detectingTag = nil;
}

- (void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    startDraggingOrigin = [touch locationInView:self.view];
    for(NSInteger i = 0 ; i < self.tags.count ; i ++){
        TagItem * tag = [self.tags objectAtIndex:i];
        if(CGRectContainsPoint(tag.view.frame, startDraggingOrigin)){
            curDraggingTag = tag;
            curIndex = i;
            break;
        }
    }
    if(curDraggingTag){
        [self.view bringSubviewToFront:curDraggingTag.view];
    }
}

- (void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if(curDraggingTag){
        UITouch *touch = [touches anyObject];
        CGPoint point = [touch locationInView:self.view];
        curDraggingTag.view.frame = CGRectMake(curDraggingTag.desOrigin.x + point.x - startDraggingOrigin.x, curDraggingTag.desOrigin.y + point.y - startDraggingOrigin.y, itemWidth, itemWidth);
        
        BOOL outside = YES;
        for(NSInteger i = 0 ; i < self.tags.count ; i ++){
            TagItem * tag = [self.tags objectAtIndex:i];
            CGFloat distance = distanceBetweenPoints(tag.center, curDraggingTag.view.center);
            if(distance < itemWidth){
                outside = NO;
            }
            if(curDraggingTag == tag || detectingTag == tag){
                continue;
            }
            if(distance < itemWidth / 2){
                detectingTag = tag;
                detectingIndex = i;
                [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(detectHanging) object:nil];
                [self performSelector:@selector(detectHanging) withObject:nil afterDelay:DETECTING_DURATION];
                break;
            }
        }
        if(outside){
            [self startOrderAnim:[self.tags objectAtIndex:self.tags.count - 1] index:self.tags.count - 1];
        }
    }
}

- (void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(detectHanging) object:nil];
    if(curDraggingTag){
        curDraggingTag.desOrigin = CGPointMake(curDraggingTag.center.x - itemWidth / 2, curDraggingTag.center.y - itemWidth / 2);
        [UIView animateWithDuration:ANIM_DURATION animations:^{
            curDraggingTag.view.frame = CGRectMake(curDraggingTag.desOrigin.x, curDraggingTag.desOrigin.y, itemWidth, itemWidth);
            curDraggingTag.view.text = [NSString stringWithFormat:@"%li", (long)curIndex];
        } completion:^(BOOL finished) {
        }];
        curDraggingTag = nil;
    }
}

- (void) touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(detectHanging) object:nil];
    if(curDraggingTag){
        curDraggingTag.desOrigin = CGPointMake(curDraggingTag.center.x - itemWidth / 2, curDraggingTag.center.y - itemWidth / 2);
        [UIView animateWithDuration:ANIM_DURATION animations:^{
            curDraggingTag.view.frame = CGRectMake(curDraggingTag.desOrigin.x, curDraggingTag.desOrigin.y, itemWidth, itemWidth);
            curDraggingTag.view.text = [NSString stringWithFormat:@"%li", (long)curIndex];
        } completion:^(BOOL finished) {
        }];
        curDraggingTag = nil;
    }
}

@end