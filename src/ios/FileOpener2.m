/*
The MIT License (MIT)

Copyright (c) 2013 pwlin - pwlin05@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
#import "FileOpener2.h"
#import <Cordova/CDV.h>
#import "ReaderViewController.h"

@interface FileOpener2 ()<ReaderViewControllerDelegate>
@property(nonatomic, strong) UIWebView *myWebView;
@property(nonatomic, strong) UIViewController *docViewCont;
@property(nonatomic, assign) BOOL wasOpened;
@property(nonatomic, strong) CDVInvokedUrlCommand *command;
@end

@implementation FileOpener2

- (void) open: (CDVInvokedUrlCommand*)command {

    self.command = command;
    NSString *path = [[command.arguments objectAtIndex:0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *title = [command.arguments objectAtIndex:1];
	BOOL showPreview = YES;

    
	NSArray *dotParts = [path componentsSeparatedByString:@"."];
	NSString *fileExt = [dotParts lastObject];
    
	dispatch_async(dispatch_get_main_queue(), ^{
		NSURL *fileURL = [NSURL URLWithString:path];

		localFile = fileURL.path;
        CDVPluginResult *pluginResult = nil;
	    NSLog(@"looking for file at %@", fileURL);
	    NSFileManager *fm = [NSFileManager defaultManager];
	    if(![fm fileExistsAtPath:localFile]) {
	    	NSDictionary *jsonObj = @{@"status" : @"9",
	    	@"message" : @"File does not exist"};
	    	pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:jsonObj];
	      	[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
	      	return;
    	}

        self.wasOpened = NO;
        [self openLocalReadView:localFile title:title];
//        [self initDocView:fileURL title:title];

	});
}
-(void)openLocalReadView:(NSString *)path title:(NSString *)title {
    ReaderDocument *document = [ReaderDocument withDocumentFilePath:path password:nil];
    document.customTitle = title;
    ReaderViewController *readVC = [[ReaderViewController alloc] initWithReaderDocument:document];
    readVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    readVC.modalPresentationStyle = UIModalPresentationFullScreen;
    readVC.delegate = self;
    [self.viewController presentViewController:readVC animated:YES completion:nil];
}

-(void)initDocView:(NSURL *)path title:(NSString *)title {
    _docViewCont = [[UIViewController alloc] init];
    _docViewCont.view.bounds = self.viewController.view.bounds;
    
    //导航栏
    UIView *navView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _docViewCont.view.bounds.size.width, 64)];
    navView.backgroundColor = NAV_BG_COLOR;
    [_docViewCont.view addSubview:navView];
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(5, 32, 30, 20);
    [backBtn addTarget:self action:@selector(btnClick) forControlEvents:UIControlEventTouchUpInside];
    [backBtn setImage:[[UIImage imageNamed:@"back_black"] imageWithTintColor:NAV_ICON_COLOR] forState:UIControlStateNormal];
    backBtn.imageView.contentMode=UIViewContentModeScaleAspectFit;
    [navView addSubview:backBtn];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 26, self.viewController.view.bounds.size.width-100, 30)];
    label.font = [UIFont systemFontOfSize:18.f];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = title;
    label.textColor = NAV_FONT_COLOR;
    [navView addSubview:label];
    //初始化myWebView
    _myWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 64, self.viewController.view.bounds.size.width, self.viewController.view.bounds.size.height-64)];
    _myWebView.backgroundColor = [UIColor whiteColor];
    NSURLRequest *request = [NSURLRequest requestWithURL: path];
    [_myWebView loadRequest:request];
    _myWebView.scrollView.pagingEnabled = YES;
    _myWebView.scrollView.showsHorizontalScrollIndicator = YES;
    _myWebView.scrollView.contentSize = CGSizeMake(self.viewController.view.bounds.size.width*4, self.viewController.view.bounds.size.height-64);
    NSLog(@"w:%f ----- h:%f",_myWebView.scrollView.contentSize.width,_myWebView.scrollView.contentSize.height);
    //使文档的显示范围适合UIWebView的bounds
    [_myWebView setScalesPageToFit:YES];
    [_docViewCont.view addSubview:_myWebView];
    [self.viewController presentViewController:_docViewCont animated:NO completion:^{
        self.wasOpened = true;
    }];
}
-(void)btnClick {
    CDVPluginResult *pluginResult = nil;
    if(self.wasOpened) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString: @""];
        //NSLog(@"Success");
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.command.callbackId];
    [_docViewCont dismissViewControllerAnimated:NO completion:nil];
}
-(void)close:(CDVInvokedUrlCommand *)command {
//    [_myWebView removeFromSuperview];
}

//ReaderViewControllerDelegate
- (void)dismissReaderViewController:(ReaderViewController *)viewController {
    [self.viewController dismissViewControllerAnimated:YES completion:nil];
}
@end
