/**
 * Copyright (c) 2015-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTLocalAssetImageLoader.h"

#import <stdatomic.h>
#import <React/RCTUtils.h>


@interface RCTLocalAssetImageLoader ()
@property (nonatomic, retain) NSCache *imagesCache;
@end


@implementation RCTLocalAssetImageLoader

RCT_EXPORT_MODULE()

- (BOOL)canLoadImageURL:(NSURL *)requestURL
{
  return RCTIsLocalAssetURL(requestURL);
}

- (BOOL)requiresScheduling
{
  // Don't schedule this loader on the URL queue so we can load the
  // local assets synchronously to avoid flickers.
  return NO;
}

- (BOOL)shouldCacheLoadedImages
{
  // UIImage imageNamed handles the caching automatically so we don't want
  // to add it to the image cache.
  return NO;
}

 - (RCTImageLoaderCancellationBlock)loadImageForURL:(NSURL *)imageURL
                                               size:(CGSize)size
                                              scale:(CGFloat)scale
                                         resizeMode:(RCTResizeMode)resizeMode
                                    progressHandler:(RCTImageLoaderProgressBlock)progressHandler
                                 partialLoadHandler:(RCTImageLoaderPartialLoadBlock)partialLoadHandler
                                  completionHandler:(RCTImageLoaderCompletionBlock)completionHandler
{
  __block atomic_bool cancelled = ATOMIC_VAR_INIT(NO);
  RCTExecuteOnMainQueue(^{
    if (atomic_load(&cancelled)) {
      return;
    }

    
    NSString *imageFilename = RCTImageFilenameFromLocalAssetURL(imageURL);
    UIImage *image;
    
    if (imageFilename) {
      image = [self imageForKey:imageFilename];
    }
    
    if (!image) {
      //NOTE: This should be optimized for not needing this second call.
      image = RCTImageFromLocalAssetURL(imageURL);
    }
    
    
    //UIImage *image = RCTImageFromLocalAssetURL(imageURL);
    if (image) {
      if (progressHandler) {
        progressHandler(1, 1);
      }
      completionHandler(nil, image);
    } else {
      NSString *message = [NSString stringWithFormat:@"Could not find image %@", imageURL];
      RCTLogWarn(@"%@", message);
      completionHandler(RCTErrorWithMessage(message), nil);
    }
  });

  return ^{
    atomic_store(&cancelled, YES);
  };
}



- (UIImage *)imageForKey:(NSString *)key {
  UIImage *image;
  
  if (self.imagesCache != nil) {
    image = [self.imagesCache objectForKey:key];
  } else {
    self.imagesCache = [NSCache new];
  }
  
  if (!image) {
    image = [UIImage imageNamed:key];
    [self.imagesCache setObject:image forKey:key];
  }
  
  return image;
}


@end
