package task_one

//基础
//两数之和 ,
//考察：数组遍历、map使用
//题目：给定一个整数数组 nums 和一个目标值 target，请你在该数组中找出和为目标值的那两个整数

func twoSum1(nums []int, target int) []int {

	for index, num := range nums {

		for j := index + 1; j < len(nums); j++ {
			if num+nums[j] == target {
				return []int{index, j}
			}
		}

	}

	return []int{}
}

// 时间复杂度小于O(n²)
// nums = [2,7,11,15], target=9
func twoSum2(nums []int, target int) []int {
	//将数组转为map
	numMap := make(map[int]int) // key: number, value: index

	for i := 0; i < len(nums); i++ {
		//转为互补
		complement := target - nums[i]
		//遍历数组元素
		if index, exists := numMap[complement]; exists {
			return []int{index, i}
		}
		numMap[nums[i]] = i
	}
	return nil // 题目保证有解，此返回仅为语法需要
}
