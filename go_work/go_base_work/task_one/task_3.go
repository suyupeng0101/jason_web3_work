package task_one

//基本值类型,
//删除排序数组中的重复项 ,
//考察：数组/切片操作
//题目：给定一个排序数组，你需要在原地删除重复出现的元素

func plusOne(digits []int) []int {
	n := len(digits)
	for i := n - 1; i >= 0; i-- {
		digits[i] = (digits[i] + 1) % 10
		if digits[i] != 0 {
			return digits
		}
	}

	// digits 中所有的元素均为 9
	digits = make([]int, n+1)
	digits[0] = 1
	return digits
}

//加一 ,
//考察：数组操作、进位处理
//题目：给定一个由整数组成的非空数组所表示的非负整数，在该数的基础上加一
