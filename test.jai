#import "Basic";
#import "Strings/v1.0.8/jai-string.onelivesleft";


main :: () {
    for word: split("Hello world", #char " ")
        print("%\n", word);
}
