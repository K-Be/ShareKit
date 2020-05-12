//
//  SHKImgurOAuthView.m
//  ShareKit
//
//  Created by Andrew Shu on 3/21/14.
//
//

#import "SHKOAuth2View.h"

#import "Debug.h"
#import "SHK.h"

@implementation SHKOAuth2View

 
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	if ([navigationAction.request.URL.absoluteString rangeOfString:[self.delegate authorizeCallbackURL].absoluteString options:NSCaseInsensitiveSearch].location != NSNotFound)
	 {
		 NSMutableDictionary *queryParams = nil;
		 if ([navigationAction.request.URL.absoluteString rangeOfString:@"redirect"].location != NSNotFound)
				 {
					 //if user authenticates via 3rd party service (Google, Facebook etc)
					 decisionHandler(WKNavigationActionPolicyAllow);
				 }
		 else if (navigationAction.request.URL.fragment != nil)
		 {
			 // Get fragment instead of query, since OAuth 2.0 response_type=token
						 queryParams = [NSMutableDictionary dictionaryWithCapacity:0];
			 NSArray *vars = [navigationAction.request.URL.fragment componentsSeparatedByString:@"&"];
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
				 // cancel
				 [self.delegate tokenAuthorizeCancelledView:self];
				 [[SHK currentHelper] hideCurrentViewControllerAnimated:YES];
		 }
 
		 self.delegate = nil;
		 decisionHandler(WKNavigationActionPolicyCancel);
	 }
	else {
		decisionHandler(WKNavigationActionPolicyAllow);
	}
}

@end
