module json112

const (
	ws=[` `,`\t`,`\n`,`\r`]
	structural_char=[`{`,`}`,`[`,`]`,`:`,`,`]
)

struct Scanner{
	//json原始字符
	text string
	//是否扫描注释
	scan_comment bool
mut:
	//当前扫描位置
	pos int
	//已缓存的所有token
	all_tokens []Token
	//all_tokens Array的索引
	tidx int
}	

fn new_scanner(text string,scan_comment bool) &Scanner{
	mut scanner := &Scanner{
		text:text
		scan_comment:scan_comment
	}
	//初始化
	scanner.init_scanner()
	return scanner
}

//初始化扫描器 缓存所有token
fn (mut s Scanner) init_scanner() {
	for{
		tok := s.text_scan()
		s.all_tokens << tok

		if tok.kind == .eof{
			break
		}
	}
	log(s.all_tokens)
}

//获取token
fn (mut s Scanner) scan() Token{

	tok := s.all_tokens[s.tidx]
	s.tidx++

	if tok.kind == .eof{
		s.tidx--
	}

	return tok
}

fn (mut s Scanner) text_scan() Token{
	mut start := 0
	mut len := 0
	mut str := ""
	mut str_end_flg := false 

	for{
		s.skip_ws()

		if s.pos >= s.text.len{
			break
		}
		c := s.text[s.pos]

		if (c >= `0` && c <= `9`) || c == `-`{
			start = s.pos
			len = s.continue_scan()
			str = s.text[start..start + len]

			mut minus := []byte{}
			mut minus_flag := true

			mut int_ := []byte{}
			mut int_flag := false

			mut frac := []byte{}
			mut frac_flag := false 

			mut	exp_sign := []byte{}
			mut exp_sign_flag := false
			mut exp := []byte{}
			mut exp_flag := false

			mut error_flg := false

			for i,b in str{
				if minus_flag {
					if b >= `0` && b <= `9` {
						minus_flag = false
						int_flag = true
						int_ << b
						continue
					}
					if i==0 && b == `-`{
						minus << b
					}else{
						error_flg = true
					}
					continue
				}
				if int_flag {
					if b == `.`{
						int_flag = false
						frac_flag = true
						continue
					}

					if b == `e` || b == `E`{
						int_flag = false
						exp_sign_flag = true
						continue
					}
					
					if int_[0] != `0` && b >= `0` && b <= `9`{
						int_ << b
					} else {
						error_flg = true
					}
					continue
				}
				if frac_flag {
					if b == `e` || b == `E`{
						int_flag = false
						exp_sign_flag = true
						continue
					}

					if b >= `0` && b <= `9`{
						frac << b
					} else {
						error_flg = true
					}
				}
				if exp_sign_flag {
					if b == `-` || b == `+`{
						exp_sign << b
					}
					exp_sign_flag = false
					exp_flag = true
					continue
				}
				if exp_flag {
					if b >= `0` && b <= `9`{
						exp << b
					} else {
						error_flg = true
					}
					continue
				}
			}

			if error_flg {
				return s.new_token(.unknown,start,len)
			}

			return s.new_token(.number,start,len)
		}

		match c {
			`"` {
				start = s.pos
				len,str_end_flg = s.string_scan()
				str = s.text[start..start + len]
				return s.new_token(.string,start,len)
			}
			`:` {
				start = s.pos
				s.pos++
				return s.new_token(.colon,start,1)
			}
			`,` {
				start = s.pos
				s.pos++
				return s.new_token(.comma,start,1)
			}
			`{` {
				start = s.pos
				s.pos++
				return s.new_token(.begin_objec,start,1)
			}
			`}` {
				start = s.pos
				s.pos++
				return s.new_token(.end_object,start,1)
			}
			`[` {
				start = s.pos
				s.pos++
				return s.new_token(.begin_array,start,1)
			}
			`]` {
				start = s.pos
				s.pos++
				return s.new_token(.end_array,start,1)
			}
			`n`{
				start = s.pos
				len = s.continue_scan()
				str = s.text[start..start + len]

				if str == 'null' {
					return s.new_token(.null,start,len)		
				}else{
					return s.new_token(.unknown,start,len)	
				}
			}
			`t`,`f` {
				start = s.pos
				len = s.continue_scan()
				str = s.text[start..start + len]

				if str in ['true','false']{
					return s.new_token(.boolean,start,len)		
				}else{
					return s.new_token(.unknown,start,len)	
				}
			}
			else {
				start = s.pos
				len = s.continue_scan()
				return s.new_token(.unknown,start,len)
			}
		}
	}

	return s.new_token(.eof,s.pos,0)
}

fn (mut s Scanner) new_token(kind Kind,pos int,len int) Token{
	return Token{
		kind:kind
		pos:pos
		len:len
	}
}

fn (mut s Scanner) skip_ws() {
	for{
		if s.pos >= s.text.len{
			break
		}

		c := s.text[s.pos]
		if c !in ws{
			break
		}
		s.pos++
	}
}

fn (mut s Scanner) continue_scan() int{
	start_pos := s.pos
	mut last_pos := s.pos
	for{
		s.skip_ws()

		c := s.text[s.pos]
		if c in structural_char{
			break
		}

		if last_pos != s.pos {
			break
		}
		if s.pos >= s.text.len{
			break
		}
		s.pos++
		last_pos = s.pos
	}
	return last_pos - start_pos
}

fn (mut s Scanner) string_scan() (int,bool){
	mut escape_flag := false
	start_pos := s.pos
	s.pos++
	
	mut other_byte := []byte{}

	for{
		if s.pos >= s.text.len{
			return s.pos - start_pos,false
		}

		c := s.text[s.pos]

		if !escape_flag && c == `\\` {
			escape_flag = true
			s.pos++
			continue
		}

		if escape_flag {

		} else {
			if c == `"`{
				s.pos++
				break
			}
		}

		s.pos++
	}
	return s.pos - start_pos,true
}