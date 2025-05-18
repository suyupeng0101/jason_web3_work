package task_one

// 控制流程,
// 只出现一次的数字：给定一个非空整数数组，除了某个元素只出现一次以外，
// 其余每个元素均出现两次。找出那个只出现了一次的元素。可以使用 for 循环遍历数组，
// 结合 if 条件判断和 map 数据结构来解决，例如通过 map 记录每个元素出现的次数，
// 然后再遍历 map 找到出现次数为1的元素。,
func singleNumber(nums []int) int {

	var nmap = make(map[int]int)

	for i := 0; i < len(nums); i++ {
		val, exsit := nmap[nums[i]]
		if !exsit {
			nmap[nums[i]] = 1
		} else {
			nmap[nums[i]] = val + 1
		}
	}
	for k, v := range nmap {
		if v == 1 {
			return k
		}
	}
	return -1
}

// 回文数,
//
// 考察：数字操作、条件判断
// 题目：判断一个整数是否是回文数
func isPalindrome(x int) bool {
	if x < 0 || (x%10 == 0 && x != 0) {
		return false
	}
	revertedNumber := 0
	for x > revertedNumber {
		revertedNumber = revertedNumber*10 + x%10
		x /= 10
	}
	return x == revertedNumber || x == revertedNumber/10
}
