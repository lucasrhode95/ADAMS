clear;
clc;

str1 = 'The Quick Brown Fox Jumps Over the Lazy Dog; Lorem ipsum;; dolor sit amet! consectetur adipiscing elit';
str2 = "The Quick Brown Fox Jumps Over the Lazy Dog; Lorem ipsum;; dolor sit amet! consectetur adipiscing elit";

%% Contains
containsTest1 = util.StringsUtil.contains(str1, 'consectetur');
containsTest2 = util.StringsUtil.contains(str1, 'Matlab');
assert(containsTest1 == true);
assert(containsTest2 == false);

containsTest1 = util.StringsUtil.contains(str2, 'consectetur');
containsTest2 = util.StringsUtil.contains(str2, 'Matlab');
assert(containsTest1 == true);
assert(containsTest2 == false);

containsTest1 = util.StringsUtil.contains(str1, "consectetur");
containsTest2 = util.StringsUtil.contains(str2, 'Matlab');
assert(containsTest1 == true);
assert(containsTest2 == false);

%% Starts with
startsWithTest1 = util.StringsUtil.startsWith(str1, 'The Quick');
startsWithTest2 = util.StringsUtil.startsWith(str1, 'The quick');
startsWithTest3 = util.StringsUtil.startsWith(str1, 'elit');
startsWithTest4 = util.StringsUtil.startsWith(str1, 'The Quick Brown Fox Jumps Over the Lazy Dog; ');
assert(startsWithTest1 == true);
assert(startsWithTest2 == false);
assert(startsWithTest3 == false);
assert(startsWithTest4 == true);

startsWithTest1 = util.StringsUtil.startsWith(str2, 'The Quick');
startsWithTest2 = util.StringsUtil.startsWith(str2, "The quick");
startsWithTest3 = util.StringsUtil.startsWith(str1, "elit");
startsWithTest4 = util.StringsUtil.startsWith(str2, 'The Quick Brown Fox Jumps Over the Lazy Dog; ');
assert(startsWithTest1 == true);
assert(startsWithTest2 == false);
assert(startsWithTest3 == false);
assert(startsWithTest4 == true);

%% Ends with
endWithTest1 = util.StringsUtil.endsWith(str1, 'adipiscing elit');
endWithTest2 = util.StringsUtil.endsWith(str1, 'adipiscing Elit');
endWithTest3 = util.StringsUtil.endsWith(str1, 'The Quick');
endWithTest4 = util.StringsUtil.endsWith(str1, '');
assert(endWithTest1 == true);
assert(endWithTest2 == false);
assert(endWithTest3 == false);
assert(endWithTest4 == false);

endWithTest1 = util.StringsUtil.endsWith(str2, 'adipiscing elit');
endWithTest2 = util.StringsUtil.endsWith(str1, "adipiscing Elit");
endWithTest3 = util.StringsUtil.endsWith(str1, "The Quick");
endWithTest4 = util.StringsUtil.endsWith(str1, "");
assert(endWithTest1 == true);
assert(endWithTest2 == false);
assert(endWithTest3 == false);
assert(endWithTest4 == false);

%% Split
splitTest1 = {'The Quick Brown Fox Jumps Over the Lazy Dog',' Lorem ipsum','',' dolor sit amet! consectetur adipiscing elit'};
splitTest1 = isempty(setdiff(splitTest1, util.StringsUtil.split(str1, ";")));

splitTest2 = {'The Quick Brown Fox Jumps Over the Lazy Dog',' Lorem ipsum','',' dolor sit amet',' consectetur adipiscing elit'};
splitTest2 = isempty(setdiff(splitTest2, util.StringsUtil.split(str2, {";", '!'})));

assert(splitTest1);
assert(splitTest2);
%%
disp('Test successful');