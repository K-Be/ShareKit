//
//  SHKVkontakteOAuthView.m
//  ShareKit
//
//  Created by Alterplay Team on 05.12.11.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//

#import "SHKVkontakteOAuthView.h"

#import "SHKVkontakte.h"
#import "SHK.h"
#import "Debug.h"

@implementation SHKVkontakteOAuthView
@synthesize vkWebView, appID, delegate, scope;

- (void) dealloc {
	vkWebView.navigationDelegate = nil;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	
}

- (void) closeView
{
    [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

- (void) addCloseButton
{
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                           target:self
                                                                                           action:@selector(closeView)];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
	[super viewDidLoad];
	
    [self addCloseButton];
    
	if(!vkWebView)
	{
		WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
		self.vkWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
		vkWebView.navigationDelegate = self;
		self.vkWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		[self.view addSubview:vkWebView];
	}
	
	if(!appID) 
	{
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		return;
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    NSString *authLink = [NSString stringWithFormat:@"https://api.vk.com/oauth/authorize?client_id=%@&scope=%@&redirect_uri=https://api.vk.com/blank.html&display=touch&response_type=token", appID, [scope componentsJoinedByString:@","]];
    NSURL *url = [NSURL URLWithString:authLink];

    [vkWebView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[vkWebView stopLoading];
	vkWebView.navigationDelegate = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


#pragma mark WKNavigationDelegate
/*! @abstract Decides whether to allow or cancel a navigation.
 @param webView The web view invoking the delegate method.
 @param navigationAction Descriptive information about the action
 triggering the navigation request.
 @param decisionHandler The decision handler to call to allow or cancel the
 navigation. The argument is one of the constants of the enumerated type WKNavigationActionPolicy.
 @discussion If you do not implement this method, the web view will load the request or, if appropriate, forward it to another application.
 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	NSURL *URL = [navigationAction.request URL];

	if ([[URL absoluteString] isEqualToString:@"https://api.vk.com/blank.html#error=access_denied&error_reason=user_denied&error_description=User%20denied%20your%20request"]) {
		[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		decisionHandler(WKNavigationActionPolicyCancel);
	}
	else
	{
		SHKLog(@"Request: %@", [URL absoluteString]);
		decisionHandler(WKNavigationActionPolicyAllow);
	}
}

/*! @abstract Invoked when an error occurs while starting to load data for
 the main frame.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 @param error The error that occurred.
 */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
	SHKLog(@"vkWebView Error: %@", [error localizedDescription]);
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}


/*! @abstract Invoked when a main frame navigation completes.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
	[webView evaluateJavaScript:@"document.title"
						completionHandler:^(NSString* _Nullable title, NSError * _Nullable error) {
		self.title = title;
		if ([vkWebView.URL.absoluteString rangeOfString:@"access_token"].location != NSNotFound) {
			NSString *accessToken = [SHKVkontakteOAuthView stringBetweenString:@"access_token="
																							andString:@"&"
																						innerString:[[webView URL] absoluteString]];
			
			NSArray *userAr = [[[webView URL] absoluteString] componentsSeparatedByString:@"&user_id="];
			NSString *user_id = [userAr lastObject];
			SHKLog(@"User id: %@", user_id);
			if(user_id){
				[[NSUserDefaults standardUserDefaults] setObject:user_id forKey:kSHKVkonakteUserId];
			}
			
			if(accessToken){
				[[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:kSHKVkontakteAccessTokenKey];

				[[NSUserDefaults standardUserDefaults] setObject:[[NSDate date] dateByAddingTimeInterval:86400] forKey:kSHKVkontakteExpiryDateKey];
				[[NSUserDefaults standardUserDefaults] synchronize];
			}
			
			SHKLog(@"vkWebView response: %@",[[webView URL] absoluteString]);
			[(SHKVkontakte *)delegate authComplete];
			[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		} else if ([vkWebView.URL.absoluteString rangeOfString:@"error"].location != NSNotFound) {
			SHKLog(@"Error: %@", vkWebView.URL.absoluteString);
			[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		}
	}];

}

/*! @abstract Invoked when an error occurs during a committed main frame
 navigation.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 @param error The error that occurred.
 */
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
	SHKLog(@"vkWebView Error: %@", [error localizedDescription]);
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}


#pragma mark - Methods

+ (NSString*)stringBetweenString:(NSString*)start
                       andString:(NSString*)end 
                     innerString:(NSString*)str 
{
	NSScanner* scanner = [NSScanner scannerWithString:str];
	[scanner setCharactersToBeSkipped:nil];
	[scanner scanUpToString:start intoString:NULL];
	if ([scanner scanString:start intoString:NULL]) {
		NSString* result = nil;
		if ([scanner scanUpToString:end intoString:&result]) {
			return result;
		}
	}
	return nil;
}

@end
