#import <Foundation/Foundation.h>

#import "mal_readline.h"
#import "types.h"
#import "reader.h"
#import "printer.h"

// read
NSObject *READ(NSString *str) {
    return read_str(str);
}

// eval
NSObject *EVAL(NSObject *ast, NSDictionary *env) {
    // NSLog(@"EVAL: %@ (%@)", _pr_str(ast, true), env);
    if ([ast isMemberOfClass:[MalSymbol class]]) {
        if ([env objectForKey:ast]) {
            return env[ast];
        } else {
            @throw [NSString stringWithFormat:@"'%@' not found", ast];
        }
    } else if ([ast isKindOfClass:[MalVector class]]) {
        NSMutableArray *newLst = [NSMutableArray array];
        for (NSObject * x in (NSArray *)ast) {
            [newLst addObject:EVAL(x, env)];
        }
        return [MalVector fromArray:newLst];
    } else if ([ast isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *newDict = [NSMutableDictionary dictionary];
        for (NSString * k in (NSDictionary *)ast) {
            newDict[k] = EVAL(((NSDictionary *)ast)[k], env);
        }
        return newDict;
    } else if (! [ast isKindOfClass:[NSArray class]]) {
        return ast;
    }

    // apply list
    NSArray * alst = (NSArray *)ast;
    if ([alst count] == 0) {
        return ast;
    }
    id el0 = EVAL(alst[0], env);
    NSObject * (^ f)(NSArray *) = el0;
    NSMutableArray * args = [NSMutableArray array];
    for (int i = 1; i < [alst count]; i++) {
        [args addObject:EVAL(alst[i], env)];
    }
    return f(args);
}

// print
NSString *PRINT(NSObject *exp) {
    return _pr_str(exp, true);
}

// REPL
NSString *REP(NSString *line, NSDictionary *env) {
    return PRINT(EVAL(READ(line), env));
}

int main () {
    NSDictionary * repl_env = @{
        @"+": ^(NSArray *args){
            return [NSNumber numberWithInt:[args[0] intValue] + [args[1] intValue]];
        },
        @"-": ^(NSArray *args){
            return [NSNumber numberWithInt:[args[0] intValue] - [args[1] intValue]];
        },
        @"*": ^(NSArray *args){
            return [NSNumber numberWithInt:[args[0] intValue] * [args[1] intValue]];
        },
        @"/": ^(NSArray *args){
            return [NSNumber numberWithInt:[args[0] intValue] / [args[1] intValue]];
        },
        };

    // Create an autorelease pool to manage the memory into the program
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    // If using automatic reference counting (ARC), use @autoreleasepool instead:
//    @autoreleasepool {

    while (true) {
        char *rawline = _readline("user> ");
        if (!rawline) { break; }
        NSString *line = [NSString stringWithUTF8String:rawline];
        if ([line length] == 0) { continue; }
        @try {
            printf("%s\n", [[REP(line, repl_env) description] UTF8String]);
        } @catch(NSString *e) {
            printf("Error: %s\n", [e UTF8String]);
        } @catch(NSException *e) {
            if ([[e name] isEqualTo:@"ReaderContinue"]) { continue; }
            printf("Exception: %s\n", [[e reason] UTF8String]);
        }
    }

    [pool drain];

//    }
}
