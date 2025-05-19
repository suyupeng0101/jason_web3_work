package task_one

// 字符串,
// 有效的括号 ,
//
// 考察：字符串处理、栈的使用
// 题目：给定一个只包括 '('，')'，'{'，'}'，'['，']' 的字符串，判断字符串是否有效
func isValid(s string) bool {
	stack := []rune{}       // 使用rune切片作为栈，存储左括号
	pairs := map[rune]rune{ // 定义右括号到左括号的映射
		')': '(',
		']': '[',
		'}': '{',
	}

	for _, char := range s { // 遍历每个字符
		if char == '(' || char == '[' || char == '{' { // 左括号入栈
			stack = append(stack, char)
		} else { // 处理右括号
			if len(stack) == 0 { // 栈空说明不匹配
				return false
			}
			top := stack[len(stack)-1]   // 取出栈顶元素
			stack = stack[:len(stack)-1] // 弹出栈顶

			if pairs[char] != top { // 检查括号类型是否匹配
				return false
			}
		}
	}
	return len(stack) == 0 // 最后检查栈是否为空
}

// 最长公共前缀,
//
// 考察：字符串处理、循环嵌套
//
// 题目：查找字符串数组中的最长公共前缀
func longestCommonPrefix(strs []string) string {

	m := len(strs)
	if m == 0 {
		return ""
	}
	for i := 0; i < len(strs[0]); i++ {
		for j := 1; j < len(strs); j++ {
			if i == len(strs[j]) || strs[j][i] != strs[0][i] {
				return strs[0][:i]
			}
		}
	}

	return strs[0]
}
