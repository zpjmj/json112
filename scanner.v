module json112

const ws=[` `,`\t`,`\n`,`\r`]

struct Scanner{
	//json原始字符
	text string
	//当前扫描位置
	pos int

}	

fn new_scanner(text string) Scanner{
	scanner := Scanner{
		text:text
		pos:0
	}

	return scanner
}

fn (mut s Scanner) text_scan() Token{
	for{
		c :=  s.text[s.pos]

		match c {
			`"` {
				return s.new_token(.plus, '', 1)
			}
			`:` {
				return s.new_token(.plus, '', 1)
			}
			`,` {
				return s.new_token(.plus, '', 1)
			}
			`{` {
				return s.new_token(.plus, '', 1)
			}
			`}` {
				return s.new_token(.plus, '', 1)
			}
			`[` {
				return s.new_token(.plus, '', 1)
			}
			`]` {
				return s.new_token(.plus, '', 1)
			}
			else {}
		}
	}
}