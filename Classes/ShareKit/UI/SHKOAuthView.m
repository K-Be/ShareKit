    //
//  SHKTwitterAuthView.m
//  ShareKit
//
//  Created by Nathan Weiner on 6/21/10.

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

#import "SHKOAuthView.h"

#import "SHK.h"
#import "SHKOAuthSharer.h"

@interface SHKOAuthView ()

@property (strong, nonatomic) NSURL *authorizeURL;

@end

@implementation SHKOAuthView

- (id)initWithURL:(NSURL *)authorizeURL delegate:(id <SHKOAuthViewDelegate>)d
{
    if ((self = [super initWithNibName:nil bundle:nil])) 
	{
		[self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																								  target:self
																								  action:@selector(cancel)] animated:NO];
		_delegate = d;
        _authorizeURL = authorizeURL;
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
	WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    WKWebView *aWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
    aWebView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    aWebView.navigationDelegate = self;
    [aWebView loadRequest:[NSURLRequest requestWithURL:self.authorizeURL]];
    self.webView = aWebView;
    [self.view addSubview:aWebView];
}


#pragma mark  WKNavigationDelegate <NSObject>
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
	if ([navigationAction.request.URL.absoluteString rangeOfString:[self.delegate authorizeCallbackURL].absoluteString options:NSCaseInsensitiveSearch].location != NSNotFound)
	{
		// Get query
		NSMutableDictionary *queryParams = nil;
		if (navigationAction.request.URL.query != nil)
		{
			queryParams = [NSMutableDictionary dictionaryWithCapacity:0];
			NSArray *vars = [navigationAction.request.URL.query componentsSeparatedByString:@"&"];
			NSArray *parts;
			for(NSString *var in vars)
			{
				parts = [var componentsSeparatedByString:@"="];
				if (parts.count == 2)
					[queryParams setObject:[parts objectAtIndex:1] forKey:[parts objectAtIndex:0]];
			}
            [self.delegate tokenAuthorizeView:self didFinishWithSuccess:YES queryParams:queryParams error:nil];
		}
        else
        {
            [self cancel];
        }
		
        self.delegate = nil;
		decisionHandler(WKNavigationActionPolicyCancel);
	}
	else {
		decisionHandler(WKNavigationActionPolicyAllow);
	}
}

/*! @abstract Invoked when a main frame navigation starts.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 */
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
	[self startSpinner];
}

/*! @abstract Invoked when a server redirect is received for the main
 frame.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 */
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
	
}

/*! @abstract Invoked when an error occurs while starting to load data for
 the main frame.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 @param error The error that occurred.
 */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
	if ([error code] != NSURLErrorCancelled && [error code] != 102 && [error code] != NSURLErrorFileDoesNotExist)
	{
		[self stopSpinner];
		[self.delegate tokenAuthorizeView:self didFinishWithSuccess:NO queryParams:nil error:error];
	}
}

/*! @abstract Invoked when content starts arriving for the main frame.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 */
- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation
{
	
}

/*! @abstract Invoked when a main frame navigation completes.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
	//some web pages do not adjust to current size of a view, but apparently size of a screen(?). This helps them to keep disciplined.
    NSString *javaFormatString = @"document.querySelector('meta[name=viewport]').setAttribute('content', 'width=%d;', false); ";
	[webView evaluateJavaScript:[NSString stringWithFormat:javaFormatString, (int)webView.bounds.size.width]
						completionHandler:^(NSString* _Nullable result, NSError * _Nullable error) {
		[self stopSpinner];
		
		// Extra sanity check for Twitter OAuth users to make sure they are using BROWSER with a callback instead of pin based auth
		if ([self.webView.URL.host isEqualToString:@"api.twitter.com"]) {
			[self.webView evaluateJavaScript:@"document.getElementById('oauth_pin').innerHTML"
										 completionHandler:^(NSString* _Nullable result, NSError * _Nullable error) {
				if ([result isKindOfClass:[NSString class]] && result.length != 0) {
					[self.delegate tokenAuthorizeView:self didFinishWithSuccess:NO queryParams:nil error:[SHK error:@"Your SHKTwitter config is incorrect.  You must set your application type to Browser and define a callback url.  See SHKConfig.h for more details"]];
				}
			}];
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
	if ([error code] != NSURLErrorCancelled && [error code] != 102 && [error code] != NSURLErrorFileDoesNotExist)
	{
		[self stopSpinner];
		[self.delegate tokenAuthorizeView:self didFinishWithSuccess:NO queryParams:nil error:error];
	}
}

/*! @abstract Invoked when the web view needs to respond to an authentication challenge.
 @param webView The web view that received the authentication challenge.
 @param challenge The authentication challenge.
 @param completionHandler The completion handler you must invoke to respond to the challenge. The
 disposition argument is one of the constants of the enumerated type
 NSURLSessionAuthChallengeDisposition. When disposition is NSURLSessionAuthChallengeUseCredential,
 the credential argument is the credential to use, or nil to indicate continuing without a
 credential.
 @discussion If you do not implement this method, the web view will respond to the authentication challenge with the NSURLSessionAuthChallengeRejectProtectionSpace disposition.
 */
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
	
}

/*! @abstract Invoked when the web view's web content process is terminated.
 @param webView The web view whose underlying web content process was terminated.
 */
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macos(10.11), ios(9.0))
{
	
}


- (void)startSpinner
{
	if (self.spinner == nil)
	{
		UIActivityIndicatorView *aSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.spinner = aSpinner;
        //self.spinner.color = self.view.tintColor;

		[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithCustomView:self.spinner] animated:NO];
		self.spinner.hidesWhenStopped = YES;
	}
	
	[self.spinner startAnimating];
}

- (void)stopSpinner
{
	[self.spinner stopAnimating];
}


#pragma mark - View Rotation
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)cancel
{
	[self.delegate tokenAuthorizeCancelledView:self];
	[[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
}

@end
