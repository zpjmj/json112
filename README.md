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
	println(j_obj.typ(r'["爱好"]'))
	println(j_obj.val<string>(r'["编程技能"].js'))
	println(j_obj.val<string>(r'name'))
	println(j_obj.val<bool>(r'["追更的电视剧"]'))
	println(j_obj.val<f64>(r'age'))
}

>>> PS D:\json112> v run .\test.v
true
array
中级
112
false
18.
```
## 函数 function
1. pub fn decode(json_str string,allow_comments ...bool) ?Json112{<br>
   把一个json字符串解码为Json112对象<br>
   Decode a JSON string into a Json112 object
    * json_str:<br>
      需要解析的字符串(暂时只支持utf8 without bom 编码)<br>
      A string that needs to be parsed (for now only utF8 without BOM)
    * allow_comments:<br>
      可选参数,是否允许有注释行`//`(目前未实现注释行的解析)<br>
      Optional argument, whether comment line '//' is allowed (comment line parsing is not currently implemented)
    * ?:<br>
      解析失败时抛出异常<br>
      An exception is thrown when parsing fails
2. pub fn encode<T>(typ T,mapping map[string]string,beautify ...bool) ?string<br>
   把一个v结构体实例编码为json字符串<br>
   Encode an instance of a V structure as a JSON string
3. pub fn node(node_str string) Json112NodeIndex <br>
   把字符串格式化为Json112对象节点索引的标准格式<br>
   Format the string into the standard Json112 object node index format<br>
## Json112结构和方法 Json112 structure and method
1. struct Json112
    ```
    //Json112对象内部存储一个map,decode方法把json字符串中所有节点名字和节点值储存进map<br>
    //The Json112 object stores a map inside, and the decode method stores all the node names and node values in the JSON string into the map
    struct Json112{
        all_nodes map[string]Json112Node
    }

    ex:
    json112.decode(r'{"name":"112","age":10}') or {panic(err)}
    >>>
    Json112.all_nodes:
    {'["name"]': json112.Json112Node{
        node_typ: string
        node_val: json112.ConvertedValue{
            skip: 1689360
            string_val: '112'
            bool_val: true
            number_val: 8.346547e-318
        }
    }, '["age"]': json112.Json112Node{
        node_typ: number
        node_val: json112.ConvertedValue{
            skip: 0
            string_val: ''
            bool_val: false
            number_val: 10
        }
    }}

    ```
2. pub fn (J Json112) exist(node NodeIndex) bool<br>
   判断节点是否存在<br>
    * node:<br>
      即可以是node函数变换后的Json112NodeIndex<br>
      也可以是变换前的string(函数内部调用node函数进行自动变换)<br>

3. pub fn (J Json112) val<T>(node NodeIndex) T<br>
   获取节点的值,节点的类型只能是string number boolean<br> 
   Gets the value of the node,the type of the node must be string number Boolean<br>
   T 对应 vlang的 string f64 bool<br>
   The generic T can only be the string f64 bool of vlang<br>

4. pub fn (J Json112) typ(node NodeIndex) Json112NodeType<br>
   获取节点的类型<br>
   Gets the type of the node
   ```
    pub enum Json112NodeType{
        null
        boolean
        number
        string
        array
        object
    }
   ```


# 参考文档
1. https://datatracker.ietf.org/doc/html/rfc4627