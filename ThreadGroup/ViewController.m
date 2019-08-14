//
//  ViewController.m
//  ThreadGroup
//
//  Created by lvjianxiong on 2019/8/14.
//  Copyright © 2019 ushareit.com. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self serialBySemaphore];
    
//    [self serialByGroupWait];
    
//    [self concurrentSemaphore:5];
    
//    [self concurrentGroup:5];
    
//    [self serialSemaphore:5];
    
    [self serialGroup:5];
}



/**
 信号量semaphore（必须放在子线程 dispatch_semaphore_wait 会卡死主线程）
 */
- (void)serialBySemaphore {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        //模拟网络请求
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"先执行此，开始等3秒");
            sleep(3);
            NSLog(@"3秒结束后，开始执行第二个任务");
            dispatch_semaphore_signal(semaphore);
        });
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"开始执行第2个任务");
        });
    });
    
}


/**
 使用 GCD dispatch_group_enter/leave (task 1,2执行完之后，再执行task3，全部执行完之后，进入到notify)
 */
- (void)serialByGroupWait{
    dispatch_group_t group = dispatch_group_create();
    
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"开始执行任务1");
        sleep(3);
        NSLog(@"任务1执行完成");
        dispatch_group_leave(group);
    });
    
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"开始执行任务2");
        sleep(2);
        NSLog(@"任务2执行完成");
        dispatch_group_leave(group);
    });
    
    //1,2同时执行，1，2执行完之后，下面的任务才会执行
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLog(@"开始执行任务3");
        dispatch_group_leave(group);
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"所有任务执行完之后，执行此处");
    });
}


/**
 模拟同时网络请求，同时进行统一回调
 GCD semaphore 方式
 @param size 多少次请求
 */
- (void)concurrentSemaphore:(NSInteger)size{
    dispatch_group_t group = dispatch_group_create();
    for(int i=0;i<5;i++){
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            //模拟网络请求
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                sleep(2);
                NSLog(@"任务%d执行完成",i);
                dispatch_semaphore_signal(semaphore);
            });
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        });
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"全部搞完啦");
    });
}


/**
 模拟同时网络请求，同时进行统一回调

 @param size 网络请求量
 */
- (void)concurrentGroup:(NSInteger)size{
    dispatch_group_t group = dispatch_group_create();
    for (int i = 0; i < size; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(3);
            NSLog(@"任务%d执行完成",i);
            dispatch_group_leave(group);
        });
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"全部搞定");
    });
}



/**
 模拟顺序网络请求 GCD + semaphore

 @param size 网络请求次数
 */
- (void)serialSemaphore:(NSInteger)size{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"***开始***");
        for (int i = 0; i < size; i++) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                NSLog(@"任务%d开始",i);
                sleep(2);
                NSLog(@"任务%d结束",i);
                dispatch_semaphore_signal(semaphore);
            });
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
        NSLog(@"全部结束啦");
    });
}


/**
 模拟顺序网络请求 entry/level（严格顺序）
 
 @param size 网络请求次数
 */
- (void)serialGroup:(NSInteger)size{
    dispatch_group_t group = dispatch_group_create();
    NSLog(@"开始");
    for (int i=0; i<size; i++) {
        dispatch_group_enter(group);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSLog(@"任务%d开始",i);
            sleep(3);
            NSLog(@"任务%d结束",i);
            dispatch_group_leave(group);
        });
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER);//同步执行与顺序执行的不同点，关键就在与wait
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"全部结束啦");
    });
}

@end
