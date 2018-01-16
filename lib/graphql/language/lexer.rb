module GraphQL
module Language
module Lexer
def self.tokenize(query_string)
	run_lexer(query_string)
end

# Replace any escaped unicode or whitespace with the _actual_ characters
# To avoid allocating more strings, this modifies the string passed into it
def self.replace_escaped_characters_in_place(raw_string)
	raw_string.gsub!(ESCAPES, ESCAPES_REPLACE)
	raw_string.gsub!(UTF_8, &UTF_8_REPLACE)
	nil
end

private

class << self
	attr_accessor :_graphql_lexer_trans_keys 
	private :_graphql_lexer_trans_keys, :_graphql_lexer_trans_keys=
end
self._graphql_lexer_trans_keys = [
4, 20, 4, 20, 4, 4, 4, 4, 4, 4, 12, 13, 12, 13, 9, 13, 11, 11, 0, 45, 0, 0, 4, 20, 4, 20, 4, 4, 4, 4, 1, 1, 12, 13, 9, 26, 12, 13, 9, 26, 9, 26, 11, 11, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_char_class 
	private :_graphql_lexer_char_class, :_graphql_lexer_char_class=
end
self._graphql_lexer_char_class = [
0, 1, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 3, 4, 5, 6, 2, 2, 2, 7, 8, 2, 9, 0, 10, 11, 2, 12, 13, 13, 13, 13, 13, 13, 13, 13, 13, 14, 2, 2, 15, 2, 2, 16, 17, 17, 17, 17, 18, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 19, 20, 21, 2, 17, 2, 22, 23, 24, 25, 26, 27, 28, 29, 30, 17, 17, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 17, 17, 42, 17, 43, 44, 45, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_offsets 
	private :_graphql_lexer_index_offsets, :_graphql_lexer_index_offsets=
end
self._graphql_lexer_index_offsets = [
0, 17, 34, 35, 36, 37, 39, 41, 46, 47, 93, 94, 111, 128, 129, 130, 131, 133, 151, 153, 171, 189, 190, 221, 252, 283, 314, 345, 376, 407, 438, 469, 500, 531, 562, 593, 624, 655, 686, 717, 748, 779, 810, 841, 872, 903, 934, 965, 996, 1027, 1058, 1089, 1120, 1151, 1182, 1213, 1244, 1275, 1306, 1337, 1368, 1399, 1430, 1461, 1492, 1523, 1554, 1585, 1616, 1647, 1678, 1709, 1740, 1771, 1802, 1833, 1864, 1895, 1926, 1957, 1988, 2019, 2050, 2081, 2112, 2143, 2174, 2205, 2236, 2267, 2298, 2329, 2360, 2391, 2422, 2453, 2484, 2515, 2546, 2577, 2608, 2639, 2670, 2701, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_indicies 
	private :_graphql_lexer_indicies, :_graphql_lexer_indicies=
end
self._graphql_lexer_indicies = [
2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 6, 7, 8, 9, 9, 11, 11, 12, 12, 0, 9, 9, 14, 16, 17, 15, 18, 19, 20, 21, 22, 23, 15, 24, 25, 26, 27, 28, 29, 30, 31, 31, 32, 15, 33, 31, 31, 31, 34, 35, 36, 31, 31, 37, 31, 38, 39, 40, 31, 41, 31, 42, 43, 44, 31, 31, 45, 46, 47, 16, 50, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 5, 8, 53, 26, 27, 12, 12, 55, 9, 9, 54, 54, 54, 54, 56, 54, 54, 54, 54, 54, 54, 54, 56, 9, 9, 12, 12, 57, 11, 11, 57, 57, 57, 57, 56, 57, 57, 57, 57, 57, 57, 57, 56, 12, 12, 55, 27, 27, 54, 54, 54, 54, 56, 54, 54, 54, 54, 54, 54, 54, 56, 58, 31, 31, 0, 0, 0, 31, 31, 0, 0, 0, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 60, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 61, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 62, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 63, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 64, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 65, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 66, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 67, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 68, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 69, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 70, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 71, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 72, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 73, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 74, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 75, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 76, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 77, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 78, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 79, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 80, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 81, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 82, 83, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 84, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 85, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 86, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 87, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 88, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 89, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 90, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 91, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 92, 31, 31, 31, 93, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 94, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 95, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 96, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 97, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 98, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 99, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 100, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 101, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 102, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 103, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 104, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 105, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 106, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 107, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 108, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 109, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 110, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 111, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 112, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 113, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 114, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 115, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 116, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 117, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 118, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 119, 31, 31, 31, 31, 31, 31, 120, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 121, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 122, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 123, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 124, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 125, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 126, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 127, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 128, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 129, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 130, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 131, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 132, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 133, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 134, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 135, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 136, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 137, 31, 31, 31, 31, 138, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 139, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 140, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 141, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 142, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 143, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 144, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 145, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 59, 59, 59, 31, 31, 59, 59, 59, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 146, 31, 31, 31, 31, 31, 31, 31, 31, 31, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_defaults 
	private :_graphql_lexer_index_defaults, :_graphql_lexer_index_defaults=
end
self._graphql_lexer_index_defaults = [
1, 1, 5, 5, 5, 0, 10, 0, 13, 15, 48, 1, 1, 51, 5, 20, 49, 54, 57, 57, 54, 49, 0, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_trans_cond_spaces 
	private :_graphql_lexer_trans_cond_spaces, :_graphql_lexer_trans_cond_spaces=
end
self._graphql_lexer_trans_cond_spaces = [
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_targs 
	private :_graphql_lexer_cond_targs, :_graphql_lexer_cond_targs=
end
self._graphql_lexer_cond_targs = [
9, 0, 9, 1, 12, 2, 3, 4, 14, 18, 9, 19, 5, 9, 9, 9, 10, 9, 9, 11, 15, 9, 9, 9, 16, 21, 17, 20, 9, 9, 9, 22, 9, 9, 23, 31, 34, 44, 62, 69, 72, 73, 77, 95, 100, 9, 9, 9, 9, 9, 13, 9, 9, 9, 9, 6, 7, 9, 8, 9, 24, 25, 26, 27, 28, 29, 30, 22, 32, 33, 22, 35, 38, 36, 37, 22, 39, 40, 41, 42, 43, 22, 45, 53, 46, 47, 48, 49, 50, 51, 52, 22, 54, 56, 55, 22, 57, 58, 59, 60, 61, 22, 63, 64, 65, 66, 67, 68, 22, 70, 71, 22, 22, 74, 75, 76, 22, 78, 85, 79, 82, 80, 81, 22, 83, 84, 22, 86, 87, 88, 89, 90, 91, 92, 93, 94, 22, 96, 98, 97, 22, 99, 22, 101, 102, 103, 22, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_actions 
	private :_graphql_lexer_cond_actions, :_graphql_lexer_cond_actions=
end
self._graphql_lexer_cond_actions = [
1, 0, 2, 0, 3, 0, 0, 0, 4, 0, 5, 6, 0, 7, 8, 11, 0, 12, 13, 14, 0, 15, 16, 17, 0, 18, 19, 19, 20, 21, 22, 23, 24, 25, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 27, 28, 29, 30, 3, 31, 32, 33, 34, 0, 0, 35, 0, 36, 0, 0, 0, 0, 0, 0, 0, 37, 0, 0, 38, 0, 0, 0, 0, 39, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 42, 0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 0, 44, 0, 0, 45, 46, 0, 0, 0, 47, 0, 0, 0, 0, 0, 0, 48, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 0, 0, 0, 51, 0, 52, 0, 0, 0, 53, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions 
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions 
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_eof_trans 
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
1, 1, 1, 1, 1, 1, 11, 1, 14, 0, 49, 50, 52, 52, 53, 54, 50, 55, 58, 58, 55, 50, 1, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 60, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_nfa_targs 
	private :_graphql_lexer_nfa_targs, :_graphql_lexer_nfa_targs=
end
self._graphql_lexer_nfa_targs = [
0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_nfa_offsets 
	private :_graphql_lexer_nfa_offsets, :_graphql_lexer_nfa_offsets=
end
self._graphql_lexer_nfa_offsets = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_nfa_push_actions 
	private :_graphql_lexer_nfa_push_actions, :_graphql_lexer_nfa_push_actions=
end
self._graphql_lexer_nfa_push_actions = [
0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_nfa_pop_trans 
	private :_graphql_lexer_nfa_pop_trans, :_graphql_lexer_nfa_pop_trans=
end
self._graphql_lexer_nfa_pop_trans = [
0, 0 , 
]

class << self
	attr_accessor :graphql_lexer_start 
end
self.graphql_lexer_start  = 9;

class << self
	attr_accessor :graphql_lexer_first_final 
end
self.graphql_lexer_first_final  = 9;

class << self
	attr_accessor :graphql_lexer_error 
end
self.graphql_lexer_error  = -1;

class << self
	attr_accessor :graphql_lexer_en_main 
end
self.graphql_lexer_en_main  = 9;

def self.run_lexer(query_string)
	data = query_string.unpack("c*")
	eof = data.length
	
	# Since `Lexer` is a module, store all lexer state
	# in this local variable:
	meta = {
	line: 1,
	col: 1,
	data: data,
	tokens: [],
	previous_token: nil,
	}
	
	p ||= 0
	pe ||= data.length
	
	begin
		cs = graphql_lexer_start;
		ts = 0;
		te = 0;
		act = 0;
		
	end
	begin
		_trans = 0;
		_have = 0;
		_cont = 1;
		_keys = 0;
		_inds = 0;
		while ( _cont == 1  )
			begin
				_have = 0;
				if ( p == pe  )
					begin
						if ( p == eof  )
							begin
								if ( _graphql_lexer_eof_trans[cs] > 0  )
									begin
										_trans = _graphql_lexer_eof_trans[cs] - 1;
										_have = 1;
										
									end
									
								end
								if ( _have == 0  )
									begin
									
									end
									
								end
								
							end
							
						end
						if ( _have == 0  )
							_cont = 0;
							
						end
						
					end
					
				end
				if ( _cont == 1  )
					begin
						if ( _have == 0  )
							begin
								case  _graphql_lexer_from_state_actions[cs]  
								when -2 then
								begin
								end
								when 10  then
								begin
									begin
										begin
											ts = p;
											
										end
										
									end
									
									
								end
							end
							_keys = (cs<<1) ;
							_inds = _graphql_lexer_index_offsets[cs] ;
							if ( ( data[p ].ord) <= 125 && ( data[p ].ord) >= 9  )
								begin
									_ic = _graphql_lexer_char_class[( data[p ].ord) - 9];
									if ( _ic <= _graphql_lexer_trans_keys[_keys+1 ]&& _ic >= _graphql_lexer_trans_keys[_keys ] )
										_trans = _graphql_lexer_indicies[_inds + ( _ic - _graphql_lexer_trans_keys[_keys ])  ];
										
										else
										_trans = _graphql_lexer_index_defaults[cs];
										
									end
									
								end
								
								else
								begin
									_trans = _graphql_lexer_index_defaults[cs];
									
								end
								
							end
							
						end
						
					end
					if ( _cont == 1  )
						begin
							cs = _graphql_lexer_cond_targs[_trans];
							case  _graphql_lexer_cond_actions[_trans]  
							when -2 then
							begin
							end
							when 18  then
							begin
								begin
									begin
										te = p+1;
										
									end
									
								end
								
							end
							when 28  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:RCURLY, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 26  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:LCURLY, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 17  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:RPAREN, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 16  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:LPAREN, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 25  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:RBRACKET, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 24  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:LBRACKET, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 20  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:COLON, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 2  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit_string(ts, te, meta, block: false) 
										end
										
									end
									
								end
								
							end
							when 15  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:VAR_SIGN, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 22  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:DIR_SIGN, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 8  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:ELLIPSIS, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 21  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:EQUALS, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 13  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:BANG, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 27  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:PIPE, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 12  then
							begin
								begin
									begin
										te = p+1;
										begin
											meta[:line] += 1
											meta[:col] = 1
											
										end
										
									end
									
								end
								
							end
							when 11  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:UNKNOWN_CHAR, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 34  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit(:INT, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 35  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit(:FLOAT, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 31  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit_string(ts, te, meta, block: false) 
										end
										
									end
									
								end
								
							end
							when 32  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit_string(ts, te, meta, block: true) 
										end
										
									end
									
								end
								
							end
							when 36  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit(:IDENTIFIER, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 33  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											record_comment(ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 29  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											meta[:col] += te - ts 
										end
										
									end
									
								end
								
							end
							when 30  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit(:UNKNOWN_CHAR, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 5  then
							begin
								begin
									begin
										p = ((te))-1;
										begin
											emit(:INT, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 7  then
							begin
								begin
									begin
										p = ((te))-1;
										begin
											emit(:UNKNOWN_CHAR, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 1  then
							begin
								begin
									begin
										case  act  
										when -2 then
										begin
										end
										when 1  then
										begin
											p = ((te))-1;
											begin
												emit(:INT, ts, te, meta) 
											end
											
										end
										when 2  then
										begin
											p = ((te))-1;
											begin
												emit(:FLOAT, ts, te, meta) 
											end
											
										end
										when 3  then
										begin
											p = ((te))-1;
											begin
												emit(:ON, ts, te, meta) 
											end
											
										end
										when 4  then
										begin
											p = ((te))-1;
											begin
												emit(:FRAGMENT, ts, te, meta) 
											end
											
										end
										when 5  then
										begin
											p = ((te))-1;
											begin
												emit(:TRUE, ts, te, meta) 
											end
											
										end
										when 6  then
										begin
											p = ((te))-1;
											begin
												emit(:FALSE, ts, te, meta) 
											end
											
										end
										when 7  then
										begin
											p = ((te))-1;
											begin
												emit(:NULL, ts, te, meta) 
											end
											
										end
										when 8  then
										begin
											p = ((te))-1;
											begin
												emit(:QUERY, ts, te, meta) 
											end
											
										end
										when 9  then
										begin
											p = ((te))-1;
											begin
												emit(:MUTATION, ts, te, meta) 
											end
											
										end
										when 10  then
										begin
											p = ((te))-1;
											begin
												emit(:SUBSCRIPTION, ts, te, meta) 
											end
											
										end
										when 11  then
										begin
											p = ((te))-1;
											begin
												emit(:SCHEMA, ts, te, meta) 
											end
											
										end
										when 12  then
										begin
											p = ((te))-1;
											begin
												emit(:SCALAR, ts, te, meta) 
											end
											
										end
										when 13  then
										begin
											p = ((te))-1;
											begin
												emit(:TYPE, ts, te, meta) 
											end
											
										end
										when 14  then
										begin
											p = ((te))-1;
											begin
												emit(:IMPLEMENTS, ts, te, meta) 
											end
											
										end
										when 15  then
										begin
											p = ((te))-1;
											begin
												emit(:INTERFACE, ts, te, meta) 
											end
											
										end
										when 16  then
										begin
											p = ((te))-1;
											begin
												emit(:UNION, ts, te, meta) 
											end
											
										end
										when 17  then
										begin
											p = ((te))-1;
											begin
												emit(:ENUM, ts, te, meta) 
											end
											
										end
										when 18  then
										begin
											p = ((te))-1;
											begin
												emit(:INPUT, ts, te, meta) 
											end
											
										end
										when 19  then
										begin
											p = ((te))-1;
											begin
												emit(:DIRECTIVE, ts, te, meta) 
											end
											
										end
										when 27  then
										begin
											p = ((te))-1;
											begin
												emit_string(ts, te, meta, block: false) 
											end
											
										end
										when 28  then
										begin
											p = ((te))-1;
											begin
												emit_string(ts, te, meta, block: true) 
											end
											
										end
										when 35  then
										begin
											p = ((te))-1;
											begin
												emit(:IDENTIFIER, ts, te, meta) 
											end
											
										end
										when 39  then
										begin
											p = ((te))-1;
											begin
												emit(:UNKNOWN_CHAR, ts, te, meta) 
											end
											
											
										end
									end
									
								end
								
								
							end
							
						end
						when 19  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 1;
									
								end
								
							end
							
						end
						when 6  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 2;
									
								end
								
							end
							
						end
						when 46  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 3;
									
								end
								
							end
							
						end
						when 40  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 4;
									
								end
								
							end
							
						end
						when 51  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 5;
									
								end
								
							end
							
						end
						when 39  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 6;
									
								end
								
							end
							
						end
						when 45  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 7;
									
								end
								
							end
							
						end
						when 47  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 8;
									
								end
								
							end
							
						end
						when 44  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 9;
									
								end
								
							end
							
						end
						when 50  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 10;
									
								end
								
							end
							
						end
						when 49  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 11;
									
								end
								
							end
							
						end
						when 48  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 12;
									
								end
								
							end
							
						end
						when 52  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 13;
									
								end
								
							end
							
						end
						when 41  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 14;
									
								end
								
							end
							
						end
						when 43  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 15;
									
								end
								
							end
							
						end
						when 53  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 16;
									
								end
								
							end
							
						end
						when 38  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 17;
									
								end
								
							end
							
						end
						when 42  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 18;
									
								end
								
							end
							
						end
						when 37  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 19;
									
								end
								
							end
							
						end
						when 3  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 27;
									
								end
								
							end
							
						end
						when 4  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 28;
									
								end
								
							end
							
						end
						when 23  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 35;
									
								end
								
							end
							
						end
						when 14  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 39;
									
								end
								
							end
							
							
						end
					end
					case  _graphql_lexer_to_state_actions[cs]  
					when -2 then
					begin
					end
					when 9  then
					begin
						begin
							begin
								ts = 0;
								
							end
							
						end
						
						
					end
				end
				if ( _cont == 1  )
					p += 1;
					
				end
				
			end
			
		end
		
	end
	
end

end

end

end
meta[:tokens]
end

def self.record_comment(ts, te, meta)
token = GraphQL::Language::Token.new(
name: :COMMENT,
value: meta[:data][ts...te].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING),
line: meta[:line],
col: meta[:col],
prev_token: meta[:previous_token],
)

meta[:previous_token] = token

meta[:col] += te - ts
end

def self.emit(token_name, ts, te, meta)
meta[:tokens] << token = GraphQL::Language::Token.new(
name: token_name,
value: meta[:data][ts...te].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING),
line: meta[:line],
col: meta[:col],
prev_token: meta[:previous_token],
)
meta[:previous_token] = token
# Bump the column counter for the next token
meta[:col] += te - ts
end

ESCAPES = /\\["\\\/bfnrt]/
ESCAPES_REPLACE = {
'\\"' => '"',
"\\\\" => "\\",
"\\/" => '/',
"\\b" => "\b",
"\\f" => "\f",
"\\n" => "\n",
"\\r" => "\r",
"\\t" => "\t",
}

UTF_8 = /\\u[\dAa-f]{4}/i
UTF_8_REPLACE = ->(m) { [m[-4..-1].to_i(16)].pack('U'.freeze) }

VALID_STRING = /\A(?:[^\\]|#{ESCAPES}|#{UTF_8})*\z/o

PACK_DIRECTIVE = "c*"
UTF_8_ENCODING = "UTF-8"

def self.emit_string(ts, te, meta, block:)
quotes_length = block ? 3 : 1
ts += quotes_length
value = meta[:data][ts...te - quotes_length].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING)
if block
value = GraphQL::Language::BlockString.trim_whitespace(value)
end
if value !~ VALID_STRING
meta[:tokens] << token = GraphQL::Language::Token.new(
name: :BAD_UNICODE_ESCAPE,
value: value,
line: meta[:line],
col: meta[:col],
prev_token: meta[:previous_token],
)
else
replace_escaped_characters_in_place(value)

meta[:tokens] << token = GraphQL::Language::Token.new(
name: :STRING,
value: value,
line: meta[:line],
col: meta[:col],
prev_token: meta[:previous_token],
)
end

meta[:previous_token] = token
meta[:col] += te - ts
end
end
end
end
