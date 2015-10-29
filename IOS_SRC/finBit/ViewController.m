//  ViewController.m
//  OpenEarsSampleApp
//
//  ViewController.m demonstrates the use of the OpenEars framework.
//
//  Copyright Politepix UG (haftungsbeschränkt) 2014. All rights reserved.
//  http://www.politepix.com
//  Contact at http://www.politepix.com/contact
//
//  This file is licensed under the Politepix Shared Source license found in the root of the source distribution.

// **************************************************************************************************************************************************************
// **************************************************************************************************************************************************************
// **************************************************************************************************************************************************************
// IMPORTANT NOTE: Audio driver and hardware behavior is completely different between the Simulator and a real device. It is not informative to test OpenEars' accuracy on the Simulator, and please do not report Simulator-only bugs since I only actively support
// the device driver. Please only do testing/bug reporting based on results on a real device such as an iPhone or iPod Touch. Thanks!
// **************************************************************************************************************************************************************
// **************************************************************************************************************************************************************
// **************************************************************************************************************************************************************

#import "ViewController.h"
#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OEFliteController.h>
#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OELogging.h>
#import <OpenEars/OEAcousticModel.h>
#import <Slt/Slt.h>

@interface ViewController()

// Example for reading out the input audio levels without locking the UI using an NSTimer

- (void) startDisplayingLevels;
- (void) stopDisplayingLevels;

// These three are the important OpenEars objects that this class demonstrates the use of.
@property (nonatomic, strong) Slt *slt;

@property (nonatomic, strong) OEEventsObserver *openEarsEventsObserver;
@property (nonatomic, strong) OEPocketsphinxController *pocketsphinxController;
@property (weak, nonatomic) IBOutlet UITextField *question;
@property (nonatomic, strong) OEFliteController *fliteController;

// Some UI, not specifically related to OpenEars.
@property (nonatomic, assign) BOOL usingStartingLanguageModel;
@property (nonatomic, assign) int restartAttemptsDueToPermissionRequests;
@property (nonatomic, assign) BOOL startupFailedDueToLackOfPermissions;
@property (nonatomic, assign) BOOL animating;
- (IBAction)detect:(id)sender;
- (IBAction)submit:(id)sender;

// Things which help us show off the dynamic language features.
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToFirstDynamicallyGeneratedDictionary;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedLanguageModel;
@property (nonatomic, copy) NSString *pathToSecondDynamicallyGeneratedDictionary;
@property (weak, nonatomic) IBOutlet UILabel *indicator;

// Our NSTimer that will help us read and display the input and output levels without locking the UI
@property (nonatomic, strong) 	NSTimer *uiUpdateTimer;

@end

@implementation ViewController

#define kLevelUpdatesPerSecond 18 // We'll have the ui update 18 times a second to show some fluidity without hitting the CPU too hard.

//#define kGetNbest // Uncomment this if you want to try out nbest
#pragma mark -
#pragma mark Memory Management

- (void)dealloc {
    [self stopDisplayingLevels];
}

#pragma mark -
#pragma mark View Lifecycle


- (void)detect:(id)sender{
    if(self.animating == false){
        [UIView animateWithDuration:0.3
                              delay:0.0
                            options: (UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat) // reverse back to original value
                         animations:^{
                             // scale up 10%
                             _indicator.transform = CGAffineTransformMakeScale(1.3, 1.3);
                         } completion:^(BOOL finished) {
                             // restore the non-scaled state
                             _indicator.transform = CGAffineTransformIdentity;
                         }];
        self.animating = true;
    }else{
        [self.indicator.layer removeAllAnimations];
        self.animating = false;
    }
}

- (IBAction)submit:(id)sender {
    [self determineAction: [self.question.text uppercaseString]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.fliteController = [[OEFliteController alloc] init];
    self.openEarsEventsObserver = [[OEEventsObserver alloc] init];
    self.openEarsEventsObserver.delegate = self;
    self.slt = [[Slt alloc] init];
    self.animating = false;
    
    self.restartAttemptsDueToPermissionRequests = 0;
    self.startupFailedDueToLackOfPermissions = FALSE;
    
    // [OELogging startOpenEarsLogging]; // Uncomment me for OELogging, which is verbose logging about internal OpenEars operations such as audio settings. If you have issues, show this logging in the forums.
    //[OEPocketsphinxController sharedInstance].verbosePocketSphinx = TRUE; // Uncomment this for much more verbose speech recognition engine output. If you have issues, show this logging in the forums.
    
    [self.openEarsEventsObserver setDelegate:self]; // Make this class the delegate of OpenEarsObserver so we can get all of the messages about what OpenEars is doing.
    
    [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil]; // Call this before setting any OEPocketsphinxController characteristics
    
    // This is the language model we're going to start up with. The only reason I'm making it a class property is that I reuse it a bunch of times in this example,
    // but you can pass the string contents directly to OEPocketsphinxController:startListeningWithLanguageModelAtPath:dictionaryAtPath:languageModelIsJSGF:
    
    NSArray *firstLanguageArray = @[@"SEND A BITCOIN", @"BUY", @"TRANSFER", @"IS BITCOIN", @"IS THE BITCOIN EXCHANGE RATE", @"BITCOIN"];
    
    OELanguageModelGenerator *languageModelGenerator = [[OELanguageModelGenerator alloc] init];
    
    // languageModelGenerator.verboseLanguageModelGenerator = TRUE; // Uncomment me for verbose language model generator debug output.
    
    NSError *error = [languageModelGenerator generateLanguageModelFromArray:firstLanguageArray withFilesNamed:@"FirstOpenEarsDynamicLanguageModel" forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" in order to create a language model for Spanish recognition instead of English.
    
    
    if(error) {
        NSLog(@"Dynamic language generator reported error %@", [error description]);
    } else {
        self.pathToFirstDynamicallyGeneratedLanguageModel = [languageModelGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:@"FirstOpenEarsDynamicLanguageModel"];
        self.pathToFirstDynamicallyGeneratedDictionary = [languageModelGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:@"FirstOpenEarsDynamicLanguageModel"];
    }
    
    [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil]; // Call this once before setting properties of the OEPocketsphinxController instance.
    
    //   [OEPocketsphinxController sharedInstance].pathToTestFile = [[NSBundle mainBundle] pathForResource:@"change_model_short" ofType:@"wav"];  // This is how you could use a test WAV (mono/16-bit/16k) rather than live recognition. Don't forget to add your WAV to your app bundle.
    
    if(![OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't already listening.
    }
}

#pragma mark -
#pragma mark OEEventsObserver delegate methods

// What follows are all of the delegate methods you can optionally use once you've instantiated an OEEventsObserver and set its delegate to self.
// I've provided some pretty granular information about the exact phase of the Pocketsphinx listening loop, the Audio Session, and Flite, but I'd expect
// that the ones that will really be needed by most projects are the following:
//
//- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID;
//- (void) audioSessionInterruptionDidBegin;
//- (void) audioSessionInterruptionDidEnd;
//- (void) audioRouteDidChangeToRoute:(NSString *)newRoute;
//- (void) pocketsphinxDidStartListening;
//- (void) pocketsphinxDidStopListening;
//
// It isn't necessary to have a OEPocketsphinxController or a OEFliteController instantiated in order to use these methods.  If there isn't anything instantiated that will
// send messages to an OEEventsObserver, all that will happen is that these methods will never fire.  You also do not have to create a OEEventsObserver in
// the same class or view controller in which you are doing things with a OEPocketsphinxController or OEFliteController; you can receive updates from those objects in
// any class in which you instantiate an OEEventsObserver and set its delegate to self.


// This is an optional delegate method of OEEventsObserver which delivers the text of speech that Pocketsphinx heard and analyzed, along with its accuracy score and utterance ID.
- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {
    
    NSLog(@"Local callback: The received hypothesis is %@ with a score of %@ and an ID of %@", hypothesis, recognitionScore, utteranceID); // Log it.
    if([hypothesis isEqualToString:@"CHANGE MODEL"]) { // If the user says "CHANGE MODEL", we will switch to the alternate model (which happens to be the dynamically generated model).
        
        // Here is an example of language model switching in OpenEars. Deciding on what logical basis to switch models is your responsibility.
        // For instance, when you call a customer service line and get a response tree that takes you through different options depending on what you say to it,
        // the models are being switched as you progress through it so that only relevant choices can be understood. The construction of that logical branching and
        // how to react to it is your job; OpenEars just lets you send the signal to switch the language model when you've decided it's the right time to do so.
        
        if(self.usingStartingLanguageModel) { // If we're on the starting model, switch to the dynamically generated one.
            
            [[OEPocketsphinxController sharedInstance] changeLanguageModelToFile:self.pathToSecondDynamicallyGeneratedLanguageModel withDictionary:self.pathToSecondDynamicallyGeneratedDictionary];
            self.usingStartingLanguageModel = FALSE;
            
        } else { // If we're on the dynamically generated model, switch to the start model (this is an example of a trigger and method for switching models).
            
            [[OEPocketsphinxController sharedInstance] changeLanguageModelToFile:self.pathToFirstDynamicallyGeneratedLanguageModel withDictionary:self.pathToFirstDynamicallyGeneratedDictionary];
            self.usingStartingLanguageModel = TRUE;
        }
    }
    
    NSLog([NSString stringWithFormat:@"\"%@\"", hypothesis]);

    if(self.animating == true){
        [self determineAction: [NSString stringWithFormat:@"\"%@\"", hypothesis]];
    }
    
    
    //self.textLabel.text = [NSString stringWithFormat:@"\"%@\"", hypothesis];
}

- (void) determineAction:(NSString *)request {
    NSArray *actions = @[@"transfer",
                         @"merchandise",
                         @"merchandise",
                         @"question"];
    
    NSMutableArray *keywordCategories = [[NSMutableArray alloc] initWithCapacity: 4];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"SEND", @"BITCOIN", nil] atIndex: 0];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"BUY", nil] atIndex: 1];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"PURCHASE", nil] atIndex: 2];
    [keywordCategories insertObject: [NSArray arrayWithObjects: nil] atIndex: 3];
    // for keyword categories
    int location = 0;
    for (NSArray *keywords in keywordCategories) {
        bool keyword_match = true;
        for (NSString *keyword in keywords){
            if ([request rangeOfString:keyword].location == NSNotFound) {
                keyword_match = false;
                break;
            }
        }
        if (keyword_match) {
            NSLog(@"The request %@ is a %@",request,[actions objectAtIndex:location]);
            break;
        } else {
            location += 1;
        }
    }
    
    if(location == 0) {
        [self performSegueWithIdentifier:@"send" sender: self];
    } else if(location == 1 || location == 2) {
        [self renderMerchandiseModal: request];
        //[self performSegueWithIdentifier:@"buy" sender: self];
    } else {
        [self renderQuestionModal:request];
        
        //[self performSegueWithIdentifier:@"about" sender: self];
    }
}

- (void) renderMerchandiseModal:(NSString *)merchandiseRequest{
    
    NSLog(@"doing merchandise things");
    NSMutableArray *keywordCategories = [[NSMutableArray alloc] initWithCapacity: 6];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"SOFTWARE", nil] atIndex: 0];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"GAME", nil] atIndex: 1];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"TECH", nil] atIndex: 2];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"LAPTOP", nil] atIndex: 3];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"COMPUTER", nil] atIndex: 4];
    [keywordCategories insertObject: [NSArray arrayWithObjects: nil] atIndex: 5];
    
    NSArray *company = @[@"microsoft",
                         @"microsoft",
                         @"microsoft",
                         @"microsoft",
                         @"microsoft",
                         @"overstock"];
    int location = 0;
    NSString *item = @"";
    for (NSArray *keywords in keywordCategories) {
        bool keyword_match = true;
        for (NSString *keyword in keywords){
            if ([merchandiseRequest rangeOfString:keyword].location == NSNotFound) {
                keyword_match = false;
                break;
            } else {
                item = keyword;
            }
        }
        if (keyword_match) {
            NSString *merchant = [company objectAtIndex:location];
            if (location == 5)
                item = @"";
            NSString *note = [NSString stringWithFormat:@"The best place to get (a) %@ is at %@", item,merchant];
            NSLog(@"The best place to get (a) %@ is at %@", item,merchant);
            NSString *overstock_website = [NSString stringWithFormat:@"http://www.overstock.com/search?keywords=%@&SearchType=Header", item];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:overstock_website forKey:@"URL"];
            [defaults setObject:item forKey:@"item"];
            [defaults synchronize];
            break;
        } else {
            location += 1;
        }
    }
    
    [self performSegueWithIdentifier:@"buy" sender: self];
}

- (void) renderQuestionModal: (NSString *)question{
    NSLog(@"doing question things");
    NSMutableArray *keywordCategories = [[NSMutableArray alloc] initWithCapacity: 11];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"WHAT", @"BITCOIN", nil] atIndex: 0];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"WHO", @"created", nil] atIndex: 1];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"CONTROLS", nil] atIndex: 2];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"HOW",@"WORK", nil] atIndex: 3];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"USED", nil] atIndex: 4];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"RATE", nil] atIndex: 5];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"LEGAL", nil] atIndex: 6];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"ILLEGAL", nil] atIndex: 7];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"MINING", nil] atIndex: 8];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"GET", nil] atIndex: 9];
    [keywordCategories insertObject: [NSArray arrayWithObjects: nil] atIndex: 10];
    
    NSArray *questions = @[@"What is Bitcoin?",
                           @"Who created Bitcoin?",
                           @"Who controls the Bitcoin network?",
                           @"How does Bitcoin work?",
                           @"Is Bitcoin really used by people?",
                           @"What is the current exchange rate?",
                           @"Is Bitcoin legal?",
                           @"Is Bitcoin seful for illegal activites?",
                           @"What is Bitcoin mining?",
                           @"Where can I find out more about bitcoin?",
                           @"How does one acquire bitcoins?",
                          ];
    
    NSArray *answers = @[
                         @"Bitcoin is a consensus network that enables a new    payment system and a completely digital money. It is the first decentralized peer-to-peer payment network that is powered by its users with no central authority or middlemen. From a user perspective, Bitcoin is pretty much like cash for the Internet. Bitcoin can also be seen as the most prominent triple entry bookkeeping system in existence.",
                         @"Bitcoin is the first implementation of a concept called 'cryptocurrency', which was first described in 1998 by Wei Dai on the cypherpunks mailing list, suggesting the idea of a new form of money that uses cryptography to control its creation and transactions, rather than a central authority. The first Bitcoin specification and proof of concept was published in 2009 in a cryptography mailing list by Satoshi Nakamoto. Satoshi left the project in late 2010 without revealing much about himself. The community has since grown exponentially with many developers working on Bitcoin.",
                         @"Nobody owns the Bitcoin network much like no one owns the technology behind email. Bitcoin is controlled by all Bitcoin users around the world. While developers are improving the software, they can't force a change in the Bitcoin protocol because all users are free to choose what software and version they use. In order to stay compatible with each other, all users need to use software complying with the same rules. Bitcoin can only work correctly with a complete consensus among all users. Therefore, all users and developers have a strong incentive to protect this consensus.",
                         @"From a user perspective, Bitcoin is nothing more than a mobile app or computer program that provides a personal Bitcoin wallet and allows a user to send and receive bitcoins with them. This is how Bitcoin works for most users.",
                         @"As payment for goods or services. Purchase bitcoins at a Bitcoin exchange. Exchange bitcoins with someone near you. Earn bitcoins through competitive mining.",
                         @"The current exchange rate is $293.95 to one bitcoin",
                         @"To the best of our knowledge, Bitcoin has not been made illegal by legislation in most jurisdictions. However, some jurisdictions (such as Argentina and Russia) severely restrict or ban foreign currencies. Other jurisdictions (such as Thailand) may limit the licensing of certain entities such as Bitcoin exchanges.",
                         @"Bitcoin is money, and money has always been used both for legal and illegal purposes. Cash, credit cards and current banking systems widely surpass Bitcoin in terms of their use to finance crime. Bitcoin can bring significant innovation in payment systems and the benefits of such innovation are often considered to be far beyond their potential drawbacks.",
                         @"Mining is the process of spending computing power to process transactions, secure the network, and keep everyone in the system synchronized together. It can be perceived like the Bitcoin data center except that it has been designed to be fully decentralized with miners operating in all countries and no individual having control over the network. This process is referred to as 'mining' as an analogy to gold mining because it is also a temporary mechanism used to issue new bitcoins. Unlike gold mining, however, Bitcoin mining provides a reward in exchange for useful services required to operate a secure payment network. Mining will still be required after the last bitcoin is issued.",
                         @"You can find out about bitcoin at the bitcoin FAQ!",
                         @"Yes. There is a growing number of businesses and individuals using Bitcoin. This includes brick and mortar businesses like restaurants, apartments, law firms, and popular online services such as Namecheap, WordPress, and Reddit. While Bitcoin remains a relatively new phenomenon, it is growing fast. At the end of August 2013, the value of all bitcoins in circulation exceeded US$ 1.5 billion with millions of dollars worth of bitcoins exchanged daily."
                         ];
    
    
    int location = 0;
    for (NSArray *keywords in keywordCategories) {
        bool keyword_match = true;
        for (NSString *keyword in keywords){
            if ([question rangeOfString:keyword].location == NSNotFound) {
                keyword_match = false;
                break;
            }
        }
        if (keyword_match) {
            NSLog(@"The answer to %@ is a %@",[questions objectAtIndex:location],[answers objectAtIndex:location]);
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:[questions objectAtIndex:location] forKey:@"question"];
            [defaults setObject:[answers objectAtIndex:location] forKey:@"answer"];
            [defaults synchronize];
            break;
        } else {
            location += 1;
        }
    }
    
    
    [self performSegueWithIdentifier:@"about" sender: self];
    
}


#ifdef kGetNbest
- (void) pocketsphinxDidReceiveNBestHypothesisArray:(NSArray *)hypothesisArray { // Pocketsphinx has an n-best hypothesis dictionary.
    NSLog(@"Local callback:  hypothesisArray is %@",hypothesisArray);
}
#endif
// An optional delegate method of OEEventsObserver which informs that there was an interruption to the audio session (e.g. an incoming phone call).
- (void) audioSessionInterruptionDidBegin {
    NSLog(@"Local callback:  AudioSession interruption began."); // Log it.
    NSError *error = nil;
    if([OEPocketsphinxController sharedInstance].isListening) {
        error = [[OEPocketsphinxController sharedInstance] stopListening]; // React to it by telling Pocketsphinx to stop listening (if it is listening) since it will need to restart its loop after an interruption.
        if(error) NSLog(@"Error while stopping listening in audioSessionInterruptionDidBegin: %@", error);
    }
}

// An optional delegate method of OEEventsObserver which informs that the interruption to the audio session ended.
- (void) audioSessionInterruptionDidEnd {
    NSLog(@"Local callback:  AudioSession interruption ended."); // Log it.
    // We're restarting the previously-stopped listening loop.
    if(![OEPocketsphinxController sharedInstance].isListening){
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't currently listening.
    }
}

// An optional delegate method of OEEventsObserver which informs that the audio input became unavailable.
- (void) audioInputDidBecomeUnavailable {
    NSLog(@"Local callback:  The audio input has become unavailable"); // Log it.
    NSError *error = nil;
    if([OEPocketsphinxController sharedInstance].isListening){
        error = [[OEPocketsphinxController sharedInstance] stopListening]; // React to it by telling Pocketsphinx to stop listening since there is no available input (but only if we are listening).
        if(error) NSLog(@"Error while stopping listening in audioInputDidBecomeUnavailable: %@", error);
    }
}

// An optional delegate method of OEEventsObserver which informs that the unavailable audio input became available again.
- (void) audioInputDidBecomeAvailable {
    NSLog(@"Local callback: The audio input is available"); // Log it.
    if(![OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition, but only if we aren't already listening.
    }
}
// An optional delegate method of OEEventsObserver which informs that there was a change to the audio route (e.g. headphones were plugged in or unplugged).
- (void) audioRouteDidChangeToRoute:(NSString *)newRoute {
    NSLog(@"Local callback: Audio route change. The new audio route is %@", newRoute); // Log it.
    
    NSError *error = [[OEPocketsphinxController sharedInstance] stopListening]; // React to it by telling the Pocketsphinx loop to shut down and then start listening again on the new route
    
    if(error)NSLog(@"Local callback: error while stopping listening in audioRouteDidChangeToRoute: %@",error);
    
    if(![OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't already listening.
    }
}

// An optional delegate method of OEEventsObserver which informs that the Pocketsphinx recognition loop has entered its actual loop.
// This might be useful in debugging a conflict between another sound class and Pocketsphinx.
- (void) pocketsphinxRecognitionLoopDidStart {
    
    NSLog(@"Local callback: Pocketsphinx started."); // Log it.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is now listening for speech.
- (void) pocketsphinxDidStartListening {
    
    NSLog(@"Local callback: Pocketsphinx is now listening."); // Log it.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected speech and is starting to process it.
- (void) pocketsphinxDidDetectSpeech {
    NSLog(@"Local callback: Pocketsphinx has detected speech."); // Log it.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx detected a second of silence, indicating the end of an utterance.
// This was added because developers requested being able to time the recognition speed without the speech time. The processing time is the time between
// this method being called and the hypothesis being returned.
- (void) pocketsphinxDidDetectFinishedSpeech {
    NSLog(@"Local callback: Pocketsphinx has detected a second of silence, concluding an utterance."); // Log it.
}


// An optional delegate method of OEEventsObserver which informs that Pocketsphinx has exited its recognition loop, most
// likely in response to the OEPocketsphinxController being told to stop listening via the stopListening method.
- (void) pocketsphinxDidStopListening {
    NSLog(@"Local callback: Pocketsphinx has stopped listening."); // Log it.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop but it is not
// Going to react to speech until listening is resumed.  This can happen as a result of Flite speech being
// in progress on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the OEPocketsphinxController being told to suspend recognition via the suspendRecognition method.
- (void) pocketsphinxDidSuspendRecognition {
    NSLog(@"Local callback: Pocketsphinx has suspended recognition."); // Log it.
}

// An optional delegate method of OEEventsObserver which informs that Pocketsphinx is still in its listening loop and after recognition
// having been suspended it is now resuming.  This can happen as a result of Flite speech completing
// on an audio route that doesn't support simultaneous Flite speech and Pocketsphinx recognition,
// or as a result of the OEPocketsphinxController being told to resume recognition via the resumeRecognition method.
- (void) pocketsphinxDidResumeRecognition {
    NSLog(@"Local callback: Pocketsphinx has resumed recognition."); // Log it.
}

// An optional delegate method which informs that Pocketsphinx switched over to a new language model at the given URL in the course of
// recognition. This does not imply that it is a valid file or that recognition will be successful using the file.
- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
    NSLog(@"Local callback: Pocketsphinx is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
}

// An optional delegate method of OEEventsObserver which informs that Flite is speaking, most likely to be useful if debugging a
// complex interaction between sound classes. You don't have to do anything yourself in order to prevent Pocketsphinx from listening to Flite talk and trying to recognize the speech.
- (void) fliteDidStartSpeaking {
    NSLog(@"Local callback: Flite has started speaking"); // Log it.
}

// An optional delegate method of OEEventsObserver which informs that Flite is finished speaking, most likely to be useful if debugging a
// complex interaction between sound classes.
- (void) fliteDidFinishSpeaking {
    NSLog(@"Local callback: Flite has finished speaking"); // Log it.
}

- (void) pocketSphinxContinuousSetupDidFailWithReason:(NSString *)reasonForFailure { // This can let you know that something went wrong with the recognition loop startup. Turn on [OELogging startOpenEarsLogging] to learn why.
    NSLog(@"Local callback: Setting up the continuous recognition loop has failed for the reason %@, please turn on [OELogging startOpenEarsLogging] to learn more.", reasonForFailure); // Log it.
}

- (void) pocketSphinxContinuousTeardownDidFailWithReason:(NSString *)reasonForFailure { // This can let you know that something went wrong with the recognition loop startup. Turn on [OELogging startOpenEarsLogging] to learn why.
    NSLog(@"Local callback: Tearing down the continuous recognition loop has failed for the reason %@, please turn on [OELogging startOpenEarsLogging] to learn more.", reasonForFailure); // Log it.
}

- (void) testRecognitionCompleted { // A test file which was submitted for direct recognition via the audio driver is done.
    NSLog(@"Local callback: A test file which was submitted for direct recognition via the audio driver is done."); // Log it.
    NSError *error = nil;
    if([OEPocketsphinxController sharedInstance].isListening) { // If we're listening, stop listening.
        error = [[OEPocketsphinxController sharedInstance] stopListening];
        if(error) NSLog(@"Error while stopping listening in testRecognitionCompleted: %@", error);
    }
    
}












/** Pocketsphinx couldn't start because it has no mic permissions (will only be returned on iOS7 or later).*/
- (void) pocketsphinxFailedNoMicPermissions {
    NSLog(@"Local callback: The user has never set mic permissions or denied permission to this app's mic, so listening will not start.");
    self.startupFailedDueToLackOfPermissions = TRUE;
    if([OEPocketsphinxController sharedInstance].isListening){
        NSError *error = [[OEPocketsphinxController sharedInstance] stopListening]; // Stop listening if we are listening.
        if(error) NSLog(@"Error while stopping listening in micPermissionCheckCompleted: %@", error);
    }
}

/** The user prompt to get mic permissions, or a check of the mic permissions, has completed with a TRUE or a FALSE result  (will only be returned on iOS7 or later).*/
- (void) micPermissionCheckCompleted:(BOOL)result {
    if(result) {
        self.restartAttemptsDueToPermissionRequests++;
        if(self.restartAttemptsDueToPermissionRequests == 1 && self.startupFailedDueToLackOfPermissions) { // If we get here because there was an attempt to start which failed due to lack of permissions, and now permissions have been requested and they returned true, we restart exactly once with the new permissions.
            
            if(![OEPocketsphinxController sharedInstance].isListening) { // If there was no error and we aren't listening, start listening.
                [[OEPocketsphinxController sharedInstance]
                 startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel
                 dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary
                 acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]
                 languageModelIsJSGF:FALSE]; // Start speech recognition.
                
                self.startupFailedDueToLackOfPermissions = FALSE;
            }
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}


/*#pragma mark -
#pragma mark UI

// This is not OpenEars-specific stuff, just some UI behavior

- (IBAction) suspendListeningButtonAction { // This is the action for the button which suspends listening without ending the recognition loop
    [[OEPocketsphinxController sharedInstance] suspendRecognition];
    
    self.startButton.hidden = TRUE;
    self.stopButton.hidden = FALSE;
    self.suspendListeningButton.hidden = TRUE;
    self.resumeListeningButton.hidden = FALSE;
}

- (IBAction) resumeListeningButtonAction { // This is the action for the button which resumes listening if it has been suspended
    [[OEPocketsphinxController sharedInstance] resumeRecognition];
    
    self.startButton.hidden = TRUE;
    self.stopButton.hidden = FALSE;
    self.suspendListeningButton.hidden = FALSE;
    self.resumeListeningButton.hidden = TRUE;
}


- (IBAction) stopButtonAction { // This is the action for the button which shuts down the recognition loop.
    NSError *error = nil;
    if([OEPocketsphinxController sharedInstance].isListening) { // Stop if we are currently listening.
        error = [[OEPocketsphinxController sharedInstance] stopListening];
        if(error)NSLog(@"Error stopping listening in stopButtonAction: %@", error);
    }
    self.startButton.hidden = FALSE;
    self.stopButton.hidden = TRUE;
    self.suspendListeningButton.hidden = TRUE;
    self.resumeListeningButton.hidden = TRUE;
}

- (IBAction) startButtonAction { // This is the action for the button which starts up the recognition loop again if it has been shut down.
    if(![OEPocketsphinxController sharedInstance].isListening) {
        [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:self.pathToFirstDynamicallyGeneratedLanguageModel dictionaryAtPath:self.pathToFirstDynamicallyGeneratedDictionary acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:FALSE]; // Start speech recognition if we aren't already listening.
    }
    self.startButton.hidden = TRUE;
    self.stopButton.hidden = FALSE;
    self.suspendListeningButton.hidden = FALSE;
    self.resumeListeningButton.hidden = TRUE;
}*/



- (void) updateLevelsUI {
    //update circle here
}

-(void)dismissKeyboard {
    //[aTextField resignFirstResponder];
}


- (void) aboutPop{
    [self performSegueWithIdentifier:@"about" sender: self];
}

@end
