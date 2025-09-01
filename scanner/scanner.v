module scanner

import token

pub struct Scanner {
	text   string
pub mut:
	last_nl_pos int
	line_nr int
	pos     int
	lit     string
	had_str_inter bool // Flag to indicate if the last scanned string contained interpolation
}

pub fn new_scanner(text string) &Scanner {
	return &Scanner{
		line_nr: 1
		text: text
		had_str_inter: false
	}
}

pub struct Token{
	kind token.Token
	lit string
	line_nr int
	pos int
}

// NOTE: scan/scan0 was split in case i choose to cache all tokens / peek
pub fn (mut s Scanner) scan() token.Token {
	s.whitespace()
	// start_pos := s.pos // Marked as unused, commented out
	tok := s.scan0()
	// s.tokens << Token{
	// 	kind: tok,
	// 	lit: s.lit,
	// 	line_nr: s.line_nr
	// 	pos: start_pos
	// }
	return tok
}

pub fn (mut s Scanner) scan0() token.Token {
	if s.pos == s.text.len {
		s.lit = ''
		return .eof
	}
	
	c := s.text[s.pos]
	start_pos := s.pos
	
	// comments
	if c == `/` {
		s.comment()
		s.lit = s.text[start_pos..s.pos]
		return .comment
	}
	// number
	else if c >= `0` && c <= `9` {
		s.number()
		s.lit = s.text[start_pos..s.pos]
		return .number
	}
	// name/keyword/none
	else if (c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || c == `_` {
		s.name()
		s.lit = s.text[start_pos..s.pos]
		tok := token.key_tokens[s.lit]
		if tok != .unknown {
			return tok
		}
		// Check for 'none' keyword specifically if not in key_tokens (though it should be)
		// This is a safeguard.
		if s.lit == 'none' {
			return .key_none
		}
		return .name
	}
	// string
	else if c == `"` {
		s.string_literal()
		s.lit = s.text[start_pos..s.pos]
		if s.had_str_inter {
			s.had_str_inter = false // Reset flag
			return .str_inter
		}
		return .string
	}
	// raw string
	else if c == `r` && s.pos+1 < s.text.len && (s.text[s.pos+1] == `"` || s.text[s.pos+1] == `'`) {
		s.raw_string_literal()
		s.lit = s.text[start_pos..s.pos]
		return .str_raw
	}
	// rune
	else if c == `'` {
		s.rune_literal()
		s.lit = s.text[start_pos..s.pos]
		return .rune
	}
	// byte (char) `a`
	else if c == `\`` {
		s.pos++
		for s.text[s.pos] != c {
			s.pos++
		}
		s.pos++
		s.lit = s.text[start_pos..s.pos]
		return .chartoken
	}
	
	s.lit = ''
	s.pos++
	match c {
		`.` {
			if s.text[s.pos] == `.` {
				s.pos++
				if s.text[s.pos] == `.` {
					s.pos++
					return .ellipsis
				}
				return .dotdot
			}
			return .dot
		}
		`:` {
			if s.text[s.pos] == `=` {
				s.pos++
				return .decl_assign
			}
			return .colon
		}
		`!` {
			if s.text[s.pos] == `=` {
				s.pos++
				return .ne
			}
			else if s.text[s.pos..s.pos+2] == 'in' {
				s.pos+=2
				return .not_in
			}
			return .not
		}
		`=` {
			c2 := s.text[s.pos]
			if c2 == `=` {
				s.pos++
				return .eq
			}
			else if c2 == `>` {
				s.pos++
				return .arrow
			}
			return .assign
		}
		`+` {
			c2 := s.text[s.pos]
			if c2 == `+` {
				s.pos++
				return .inc
			}
			else if c2 == `=` {
				s.pos++
				return .plus_assign
			}
			return .plus
		}
		`-` {
			c2 := s.text[s.pos]
			if c2 == `-` {
				s.pos++
				return .dec
			}
			else if c2 == `=` {
				s.pos++
				return .minus_assign
			}
			return .minus
		}
		`%` {
			if s.text[s.pos] == `=` {
				s.pos++
				return .mod_assign
			}
			return .mod
		}
		`*` {
			if s.text[s.pos] == `=` {
				s.pos++
				return .mult_assign
			}
			return .mul
		}
		`/` {
			if s.text[s.pos] == `=` {
				s.pos++
				return .div_assign
			}
			return .div
		}
		`^` {
			if s.text[s.pos] == `=` {
				s.pos++
				return .xor_assign
			}
			return .xor
		}
		`&` {
			c2 := s.text[s.pos]
			if c2 == `&` {
				s.pos++
				return .and
			}
			else if c2 == `=` {
				s.pos++
				return .and_assign
			}
			return .amp
		}
		`|` {
			c2 := s.text[s.pos]
			if c2 == `|` {
				s.pos++
				return .logical_or
			}
			else if c2 == `=` {
				s.pos++
				return .or_assign
			}
			return .pipe
		}
		`<` {
			c2 := s.text[s.pos]
			if c2 == `<` {
				s.pos++
				if s.text[s.pos] == `=` {
					s.pos++
					return .left_shift_assign
				}
				return .left_shift
			}
			else if c2 == `=` {
				s.pos++
				return .le
			}
			return .lt
		}
		`>` {
			c2 := s.text[s.pos]
			if c2 == `>` {
				s.pos++
				if s.text[s.pos] == `=` {
					s.pos++
					return .right_shift_assign
				}
				return .right_shift
			}
			else if c2 == `=` {
				s.pos++
				return .ge
			}
			return .gt
		}
		`#` { return .hash }
		`,` { return .comma }
		`@` { return .at }
		`;` { return .semicolon }
		`{` { return .lcbr }
		`}` { return .rcbr }
		`(` { return .lpar }
		`)` { return .rpar }
		`[` { return .lsbr }
		`]` { return .rsbr }
		`?` { return .question }
		else { return .unknown }
	}
}

// skip whitespace
fn (mut s Scanner) whitespace() {
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if c == `\r` && s.text[s.pos+1] == `\n` {
			s.last_nl_pos = s.pos
			s.line_nr++
			s.pos+=2
			continue
		}
		else if c in [` `, `\t`, `\n`] {
			if c == `\n` {
				s.last_nl_pos = s.pos
				s.line_nr++
			}
			s.pos++
			continue
		}
		break
	}
}

fn(mut s Scanner) comment() {
	s.pos++
	match s.text[s.pos] {
		// single line
		`/` {
			for s.pos < s.text.len {
				if s.text[s.pos] == `\r` && s.text[s.pos+2] == `\n` {
					break
				}
				else if s.text[s.pos] == `\n` {
					break
				}
				s.pos++
			}
		}
		// multi line
		`*` {
			for s.pos < s.text.len {
				if s.text[s.pos] == `\r` && s.text[s.pos+1] == `\n` {
					s.last_nl_pos = s.pos
					s.line_nr++
					s.pos+=2
					continue
				}
				else if s.text[s.pos] == `\n` {
					s.last_nl_pos = s.pos
					s.line_nr++
					s.pos++
					continue
				}
				if s.text[s.pos]== `*` && s.text[s.pos+1] == `/` {
					s.pos+=2
					break
				}
				s.pos++
			}
		}
		else {}
	}
}

// Helper function to scan string interpolation parts
fn (mut s Scanner) scan_interpolation(end_char rune) bool {
	// Check for $ which starts interpolation
	if s.pos < s.text.len && s.text[s.pos] == `$` {
		s.pos++
		// Simple case: $name
		if s.pos < s.text.len && ((s.text[s.pos] >= `a` && s.text[s.pos] <= `z`) || 
								  (s.text[s.pos] >= `A` && s.text[s.pos] <= `Z`) || 
								  s.text[s.pos] == `_`) {
			s.name() // Advance past the identifier
			return true
		}
		// Complex case: ${...}
		if s.pos < s.text.len && s.text[s.pos] == `{` {
			s.pos++ // Skip '{'
			mut brace_count := 1
			for s.pos < s.text.len && brace_count > 0 {
				if s.text[s.pos] == `{` {
					brace_count++
				} else if s.text[s.pos] == `}` {
					brace_count--
				}
				// Handle nested strings or chars that might contain { or }
				else if s.text[s.pos] == '"' || s.text[s.pos] == ''' || s.text[s.pos] == '`' {
					str_end := s.text[s.pos]
					s.pos++
					for s.pos < s.text.len && s.text[s.pos] != str_end {
						if s.text[s.pos] == `\\` && s.pos+1 < s.text.len {
							s.pos++ // Skip escaped character
						}
						s.pos++
					}
					if s.pos < s.text.len { // Skip closing quote
						s.pos++
					}
					continue
				}
				s.pos++
			}
			// If we exited loop with brace_count > 0, it means unclosed '{'
			// For now, we'll treat it as end of string or error later
			return true
		}
		// If '$' is not followed by a name or '{', it's just a literal '$'
		// For simplicity in this scanner, we'll just continue scanning normally
		// The parser can deal with invalid interpolations
	}
	return false
}

fn (mut s Scanner) string_literal() {
	c := s.text[s.pos]
	s.pos++
	mut had_interpolation := false
	
	for s.pos < s.text.len {
		// Handle escape sequences
		if s.text[s.pos] == `\\` {
			s.pos += 2
			continue
		}
		
		// Check for end of string
		if s.text[s.pos] == c {
			s.pos++
			break
		}
		
		// Check for interpolation start
		if s.text[s.pos] == `$` {
			// Attempt to scan interpolation
			if s.scan_interpolation(c) {
				had_interpolation = true
				// After scanning interpolation, we might be at the end of string
				// or need to continue scanning the rest of the string
				continue
			}
			// If scan_interpolation returned false, '$' was not start of valid interpolation
			// Treat it as a literal character and continue
		}
		
		s.pos++
	}
	
	// Set the flag to indicate if this string had interpolation
	// The caller (scan0) will check this flag and return the appropriate token
	s.had_str_inter = had_interpolation
}

fn (mut s Scanner) raw_string_literal() {
	// Expect to be called when s.pos is at 'r' and s.pos+1 is the quote character
	if s.pos+1 >= s.text.len {
		// Malformed raw string, just advance
		s.pos++
		return
	}
	quote_char := s.text[s.pos+1]
	s.pos += 2 // Skip 'r' and the opening quote
	
	for s.pos < s.text.len {
		if s.text[s.pos] == quote_char {
			s.pos++
			break
		}
		s.pos++
	}
	// No escape sequences or interpolation in raw strings
}

fn (mut s Scanner) number() {
	// Check for special number formats (0b, 0x, 0o)
	if s.text[s.pos] == `0` {
		s.pos++
		if s.pos >= s.text.len {
			return // Just "0"
		}
		c := s.text[s.pos]
		// 0b (binary)
		if c in [`b`, `B`] {
			s.pos++
			for s.pos < s.text.len && s.text[s.pos] in [`0`, `1`] {
				s.pos++
			}
			return
		}
		// 0x (hex)
		else if c in [`x`, `X`] {
			s.pos++
			for s.pos < s.text.len {
				c2 := s.text[s.pos]
				if (c2 >= `0` && c2 <= `9`) || (c2 >= `a` && c2 <= `z`) || (c2 >= `A` && c2 <= `Z`) {
					s.pos++
					continue
				}
				return
			}
			return
		}
		// 0o (octal)
		else if c in [`o`, `O`] {
			s.pos++
			for s.pos < s.text.len {
				c2 := s.text[s.pos]
				if c2 >= `0` && c2 <= `7` {
					s.pos++
					continue
				}
				return
			}
			return
		}
		// If it's just a plain 0 followed by non-special character, continue with decimal parsing
		// We decrement pos to re-process the '0' as part of the decimal number
		s.pos--
	}
	
	// Parse integer part
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if c >= `0` && c <= `9` {
			s.pos++
			continue
		}
		break
	}
	
	// Check for fractional part
	if s.pos < s.text.len && s.text[s.pos] == `.` {
		// Make sure there's a digit after the dot to distinguish from range operator (..)
		if s.pos+1 < s.text.len && s.text[s.pos+1] >= `0` && s.text[s.pos+1] <= `9` {
			s.pos++ // skip '.'
			// Parse fractional part
			for s.pos < s.text.len {
				c := s.text[s.pos]
				if c >= `0` && c <= `9` {
					s.pos++
					continue
				}
				break
			}
		}
	}
	
	// Check for imaginary suffix
	if s.pos < s.text.len && (s.text[s.pos] == `i` || s.text[s.pos] == `I`) {
		s.pos++
	}

	// Check for exponent part
	if s.pos < s.text.len && (s.text[s.pos] == `e` || s.text[s.pos] == `E`) {
		exp_pos := s.pos
		s.pos++ // skip 'e' or 'E'
		
		// Optional sign
		if s.pos < s.text.len && (s.text[s.pos] == `+` || s.text[s.pos] == `-`) {
			s.pos++
		}
		
		// Must have at least one digit in exponent
		exponent_start := s.pos
		for s.pos < s.text.len && s.text[s.pos] >= `0` && s.text[s.pos] <= `9` {
			s.pos++
		}
		
		// If no digits were found in exponent, backtrack
		if s.pos == exponent_start {
			s.pos = exp_pos
		}
	}
	
	// Check for imaginary suffix
	if s.pos < s.text.len && (s.text[s.pos] == `i` || s.text[s.pos] == `I`) {
		s.pos++
	}
}

@[inline]
fn (mut s Scanner) name() {
	for s.pos < s.text.len {
		c := s.text[s.pos]
		if (c >= `0` && c <= `9`) || (c >= `a` && c <= `z`) || (c >= `A` && c <= `Z`) || c == `_` {
			s.pos++
			continue
		}
		break
	}
}

fn (mut s Scanner) rune_literal() {
	s.pos++ // skip opening '
	// Handle escape sequences if needed, though V runes are usually single characters
	// For simplicity, we'll just scan until the closing '
	for s.pos < s.text.len && s.text[s.pos] != `'` {
		s.pos++
	}
	if s.pos < s.text.len {
		s.pos++ // skip closing '
	}
}