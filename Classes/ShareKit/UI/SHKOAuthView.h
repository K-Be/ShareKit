//
//  SHKTwitterAuthView.h
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

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "SHKOAuthViewDelegate.h"

@interface SHKOAuthView : UIViewController <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (strong) id <SHKOAuthViewDelegate> delegate;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

- (id)initWithURL:(NSURL *)authorizeURL delegate:(id <SHKOAuthViewDelegate>)d;

- (void)startSpinner;
- (void)stopSpinner;

@end
