//
//  ViewController.m
//  finnBlockCalls
//
//  Created by Austin Wells on 10/25/15.
//  Copyright © 2015 Austin Wells. All rights reserved.
//

/*#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // Do any additional setup after loading the view, typically from a nib.
    NSString *guid = @"fb79bed6-669b-4967-b92b-2539e241ff22";
    NSString *password = @"Awdsefdrg123!%40%23";
    NSString *destination_address = @"147cKUErQ7bTnRf9xc5XqXgZm4tCvLb894";
    int bitcoinAmount = 0.0034;
    int satoshiAmount = bitcoinAmount * 100000000; // satoshi scale
    NSString *amount = [NSString stringWithFormat:@"%d",satoshiAmount];
    
    // **** TRANSFER BITCOIN ******
    //NSString *response = [self transferBitcoin:guid with_password:password to_address:destination_address of_amount:amount];
    //NSLog(@"Response from server: %@", response);
    
    NSString *merchandise = @"office+365";
    NSString *overstock_website = @"http://www.overstock.com/search?keywords=%@&SearchType=Header";
    NSString *microsoft_website =  @"http://www.microsoftstore.com/store?keywords=%@&SiteID=msusa&Locale=en_US&Action=DisplayProductSearchResultsPage&result=&sortby=score%%20descending&filters=";
    
    // **** LOAD WEBSITE  ******
    //[self loadWebsite:overstock_website with_merchandise:merchandise];
    
    // **** ANSWER QUESTION ****
    NSString *question1 = @"Can you send raymond 10 bitcoin";
    NSString *question2 = @"Where can I buy a laptop?";
    NSString *question3 = @"I want to purchase a car.";
    NSString *question4 = @"What is bitcoin?";
    [self determineAction:question1];
    [self determineAction:question2];
    [self determineAction:question3];
    [self determineAction:question4];
    
    
}

- (NSString *) determineCategory:(NSString *)request from_categories:(NSArray *)categories requiring_keywords:(NSMutableArray *)keywords {
    return @"Not implemented";
};

- (void) determineAction:(NSString *)request {
    NSArray *actions = @[@"transfer",
                         @"merchandise",
                         @"merchandise",
                         @"question"];
    
    NSMutableArray *keywordCategories = [[NSMutableArray alloc] initWithCapacity: 4];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"send", @"bitcoin", nil] atIndex: 0];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"buy", nil] atIndex: 1];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"purchase", nil] atIndex: 2];
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
        [self renderTransferModal];
    } else if(location == 1 || location == 2) {
        [self renderMerchandiseModal:request];
    } else {
        [self renderQuestionModal:request];
    }
}

- (void) renderTransferModal{
    NSLog(@"doing transfer things");
};

- (void) renderMerchandiseModal:(NSString *)merchandiseRequest{
    NSLog(@"doing merchandise things");
    NSMutableArray *keywordCategories = [[NSMutableArray alloc] initWithCapacity: 6];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"software", nil] atIndex: 0];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"game", nil] atIndex: 1];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"tech", nil] atIndex: 2];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"laptop", nil] atIndex: 3];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"computer", nil] atIndex: 4];
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
                item = @"your item";
            NSString *note = [NSString stringWithFormat:@"The best place to get (a) %@ is at %@", item,merchant];
            NSLog(@"The best place to get (a) %@ is at %@", item,merchant);
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:note forKey:@"note"];
            [defaults setObject:merchant forKey:@"merchant"];
            [defaults synchronize];
            break;
        } else {
            location += 1;
        }
    }
    NSString *overstock_website = @"http://www.overstock.com/search?keywords=%@&SearchType=Header";
    NSString *microsoft_website =  @"http://www.microsoftstore.com/store?keywords=%@&SiteID=msusa&Locale=en_US&Action=DisplayProductSearchResultsPage&result=&sortby=score%%20descending&filters=";
};

- (void) renderQuestionModal: (NSString *)question{
    NSLog(@"doing question things");
    NSMutableArray *keywordCategories = [[NSMutableArray alloc] initWithCapacity: 9];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"what", @"bitcoin", nil] atIndex: 0];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"who", @"created", nil] atIndex: 1];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"controls", nil] atIndex: 2];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"how",@"work", nil] atIndex: 3];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"used", nil] atIndex: 4];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"get", nil] atIndex: 5];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"legal", nil] atIndex: 6];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"illegal", nil] atIndex: 7];
    [keywordCategories insertObject: [NSArray arrayWithObjects: @"mining", nil] atIndex: 8];
    [keywordCategories insertObject: [NSArray arrayWithObjects: nil] atIndex: 3];
    
    NSArray *questions = @[@"What is Bitcoin?",
                           @"Who created Bitcoin?",
                           @"Who controls the Bitcoin network?",
                           @"How does Bitcoin work?",
                           @"Is Bitcoin really used by people?",
                           @"How does one acquire bitcoins?",
                           @"Is Bitcoin legal?",
                           @"Is Bitcoin seful for illegal activites?"
                           @"What is Bitcoin mining?"
                           @"Where can I find out more about bitcoin?"];
    
    NSArray *answers = @[
                         @"Bitcoin is a consensus network that enables a new    payment system and a completely digital money. It is the first decentralized peer-to-peer payment network that is powered by its users with no central authority or middlemen. From a user perspective, Bitcoin is pretty much like cash for the Internet. Bitcoin can also be seen as the most prominent triple entry bookkeeping system in existence.",
                         @"Bitcoin is the first implementation of a concept called 'cryptocurrency', which was first described in 1998 by Wei Dai on the cypherpunks mailing list, suggesting the idea of a new form of money that uses cryptography to control its creation and transactions, rather than a central authority. The first Bitcoin specification and proof of concept was published in 2009 in a cryptography mailing list by Satoshi Nakamoto. Satoshi left the project in late 2010 without revealing much about himself. The community has since grown exponentially with many developers working on Bitcoin.",
                         @"Nobody owns the Bitcoin network much like no one owns the technology behind email. Bitcoin is controlled by all Bitcoin users around the world. While developers are improving the software, they can't force a change in the Bitcoin protocol because all users are free to choose what software and version they use. In order to stay compatible with each other, all users need to use software complying with the same rules. Bitcoin can only work correctly with a complete consensus among all users. Therefore, all users and developers have a strong incentive to protect this consensus.",
                         @"From a user perspective, Bitcoin is nothing more than a mobile app or computer program that provides a personal Bitcoin wallet and allows a user to send and receive bitcoins with them. This is how Bitcoin works for most users.",
                         @"Yes. There is a growing number of businesses and individuals using Bitcoin. This includes brick and mortar businesses like restaurants, apartments, law firms, and popular online services such as Namecheap, WordPress, and Reddit. While Bitcoin remains a relatively new phenomenon, it is growing fast. At the end of August 2013, the value of all bitcoins in circulation exceeded US$ 1.5 billion with millions of dollars worth of bitcoins exchanged daily.",
                         @"As payment for goods or services. Purchase bitcoins at a Bitcoin exchange. Exchange bitcoins with someone near you. Earn bitcoins through competitive mining.",
                         @"To the best of our knowledge, Bitcoin has not been made illegal by legislation in most jurisdictions. However, some jurisdictions (such as Argentina and Russia) severely restrict or ban foreign currencies. Other jurisdictions (such as Thailand) may limit the licensing of certain entities such as Bitcoin exchanges.",
                         @"Bitcoin is money, and money has always been used both for legal and illegal purposes. Cash, credit cards and current banking systems widely surpass Bitcoin in terms of their use to finance crime. Bitcoin can bring significant innovation in payment systems and the benefits of such innovation are often considered to be far beyond their potential drawbacks.",
                         @"Mining is the process of spending computing power to process transactions, secure the network, and keep everyone in the system synchronized together. It can be perceived like the Bitcoin data center except that it has been designed to be fully decentralized with miners operating in all countries and no individual having control over the network. This process is referred to as 'mining' as an analogy to gold mining because it is also a temporary mechanism used to issue new bitcoins. Unlike gold mining, however, Bitcoin mining provides a reward in exchange for useful services required to operate a secure payment network. Mining will still be required after the last bitcoin is issued.",
                         @"You can find out about bitcoin at the bitcoin FAQ!"];
    
    
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
    
}

- (void) loadWebsite:(NSString *)merchant with_merchandise:(NSString *)merchandise {
    NSString *url = [NSString stringWithFormat: merchant, merchandise];
    [self getToWebsite:url];
    
}

- (NSString *) transferBitcoin:(NSString *)guid
                 with_password:(NSString *)password
                    to_address:(NSString *)dest_address
                     of_amount:(NSString *) amount {
    NSString *url = [NSString stringWithFormat:@"https://blockchain.info/merchant/%@/payment?password=%@&to=%@&amount=%@", guid, password, dest_address, amount];
    return [self getRequest:url];
}

- (NSString *) getRequest:(NSString *)url{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"GET"];
    [request setURL:[NSURL URLWithString:url]];
    
    NSError *error = [[NSError alloc] init];
    NSHTTPURLResponse *responseCode = nil;
    
    NSData *oResponseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseCode error:&error];
    
    return [[NSString alloc] initWithData:oResponseData encoding:NSUTF8StringEncoding];
}

- (void) getToWebsite:(NSString *)website{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:website]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end*/
