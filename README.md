# json112
vlang的json动态解析模块<br>
vlang dynamic JSON parsing library

![mascot](./mascot.svg)
## Example
```
module main
import json112

fn main(){
	j_obj := json112.decode(r'{"name":"112","age":18,"爱好":["看电影",{"打游戏":"LOL"}],"是否结婚":false,"追更的电视剧":null,"编程技能":{"js":"中级","vlang":"入门级"}}') or {panic(err)}	

	println(j_obj.exist(r'name'))
	println(j_obj.typ(r'["爱好"]')?)
	println(j_obj.val<string>(r'["编程技能"].js')?)
	println(j_obj.val<string>(r'name')?)
	println(j_obj.typ(r'["追更的电视剧"]')?)
	println(j_obj.val<f64>(r'age')?)
	println('')
	println(j_obj)
	println('')
	println(j_obj.stringify(0))
}

>>> PS D:\json112> v run .\test.v
true
array
中级
112
null
18.

{
    "name": "112",
    "age": 18,
    "爱好": [
        "看电影",
        {
            "打游戏": "LOL"
        }
    ],
    "是否结婚": false,
    "追更的电视剧": null,
    "编程技能": {
        "js": "中级",
        "vlang": "入门级"
    }
}

{"name":"112","age":18,"爱好":["看电影",{"打游戏":"LOL"}],"是否结婚":false,"追更的电视剧":null,"编程技能":{"js":"中级","vlang":"入门级"}}
```

# 参考文档
1. https://datatracker.ietf.org/doc/html/rfc4627