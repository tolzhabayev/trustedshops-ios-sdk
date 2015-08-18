#import "NSNumberFormatter+TRSFormatter.h"

@implementation NSNumberFormatter (TRSFormatter)

+ (NSNumberFormatter *)trs_trustbadgeRatingFormatter {
    NSNumberFormatter *decimalFormatter = [[NSNumberFormatter alloc] init];
    decimalFormatter.minimumIntegerDigits = 1;
    decimalFormatter.minimumFractionDigits = 2;
    decimalFormatter.maximumFractionDigits = 2;
    decimalFormatter.locale = [NSLocale currentLocale];

    return decimalFormatter;
}

@end
