//
//  TRSTrustcard.m
//  Pods
//
//  Created by Gero Herkenrath on 14.03.16.
//
//

static NSString * const TRSCertLocalFallback = @"trustcardfallback";
static NSString * const TRSCertHTMLName = @"trustinfos";
// http://shared.taxi-rechner.de/ts-sdk/trustinfos.php?color_highlights=36CB76

#import "TRSTrustcard.h"
#import "TRSTrustbadge.h"
#import "TRSTrustbadgeSDKPrivate.h"
#import "NSURL+TRSURLExtensions.h"
#import "UIColor+TRSColors.h"
@import CoreText;
//@import WebKit;

@interface TRSTrustcard ()


@property (weak, nonatomic) IBOutlet UIButton *certButton;
@property (weak, nonatomic) IBOutlet UIButton *okButton;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
// TODO: switch to the newer WKWebView class, but beware of Interface Builder when doing so

@property (weak, nonatomic) TRSTrustbadge *displayedTrustbadge;
// this is weak to avoid a retain cycle (it's our owner), used for temporary stuff

@end

@implementation TRSTrustcard

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	NSURL *cardURL;
	if (self.remoteCertLocationFolder) {
		NSString *colorString = @"";
		if (self.themeColor) {
			colorString = [[self.themeColor hexString] capitalizedString];
		}
		NSString *urlString = [NSString stringWithFormat:@"%@/%@.php?color_highlights=%@",
							   self.remoteCertLocationFolder, TRSCertHTMLName, colorString];
		cardURL = [NSURL URLWithString:urlString];
	}
	if (!cardURL) { // fallback, color is ignored here for now...
		cardURL = [TRSTrustbadgeBundle() URLForResource:TRSCertHTMLName
										  withExtension:@"html"
										   subdirectory:TRSCertLocalFallback];
	}
	NSMutableURLRequest *myrequest = [[NSMutableURLRequest alloc] initWithURL:cardURL
																  cachePolicy:NSURLRequestUseProtocolCachePolicy
															  timeoutInterval:10.0];
	[self.webView loadRequest:myrequest];
	// TODO: ensure the caching works as expected, even for app-restart etc.

	// set the color of the buttons
	if (self.themeColor) {
		[self.okButton setTitleColor:self.themeColor forState:UIControlStateNormal];
		[self.certButton setTitleColor:self.themeColor forState:UIControlStateNormal];
	}
}

- (IBAction)buttonTapped:(id)sender {
	if ([sender tag] == 1 && self.displayedTrustbadge) { // the tag is set in Interface Builder, it's the certButton
		NSURL *targetURL = [NSURL profileURLForShop:self.displayedTrustbadge.shop];
		[[UIApplication sharedApplication] openURL:targetURL];
	}
	// this does nothing unless the view is modally presented (otherwise presenting VC is nil)
	[self.presentingViewController dismissViewControllerAnimated:YES completion:^{
		self.displayedTrustbadge = nil; // not necessary, but we wanna be nice & cleaned up
	}];
}

- (void)showInLightboxForTrustbadge:(TRSTrustbadge *)trustbadge {	
	// this is always there, but what happens if I have more than one? multi screen apps? test that somehow...
	UIWindow *mainWindow = [[UIApplication sharedApplication] keyWindow];
	
	self.displayedTrustbadge = trustbadge;
	self.modalPresentationStyle = UIModalPresentationPageSheet;
	UIViewController *rootVC = mainWindow.rootViewController;
	// TODO: check what happens if there is no root VC. work that out
	[rootVC presentViewController:self animated:YES completion:nil];
}

#pragma mark Font helper methods

// note, these are currently not used with the webView, but we will keep them for now.
// also, the font asset will be used by the webview, probably
+ (UIFont *)openFontAwesomeWithSize:(CGFloat)size
{
	NSString *fontName = @"fontawesome";
	UIFont *font = [UIFont fontWithName:fontName size:size];
	if (!font) {
		[[self class] dynamicallyLoadFontNamed:fontName];
		font = [UIFont fontWithName:fontName size:size];
		
		// safe fallback
		if (!font) font = [UIFont systemFontOfSize:size];
	}
	
	return font;
}

+ (void)dynamicallyLoadFontNamed:(NSString *)name
{
	NSURL *url = [TRSTrustbadgeBundle() URLForResource:name withExtension:@"ttf"];
	NSData *fontData = [NSData dataWithContentsOfURL:url];
	if (fontData) {
		CFErrorRef error;
		CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)fontData);
		CGFontRef font = CGFontCreateWithDataProvider(provider);
		if (! CTFontManagerRegisterGraphicsFont(font, &error)) {
			CFStringRef errorDescription = CFErrorCopyDescription(error);
			NSLog(@"Failed to load font: %@", errorDescription);
			CFRelease(errorDescription);
		}
		CFRelease(font);
		CFRelease(provider);
	}
}


@end
