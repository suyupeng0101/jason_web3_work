package task_one

import (
	"fmt"
	"sort"
)

// 引用类型：切片
// 26. 删除有序数组中的重复项
// 给你一个有序数组 nums ，请你原地删除重复出现的元素，使每个元素只出现一次，返回删除后数组的新长度。不要使用额外的数组空间，
// 你必须在原地修改输入数组并在使用 O(1) 额外空间的条件下完成。可以使用双指针法，
// 一个慢指针 i 用于记录不重复元素的位置，一个快指针 j 用于遍历数组，当 nums[i] 与 nums[j] 不相等时，将 nums[j] 赋值给 nums[i + 1]，并将 i 后移一位。
func removeDuplicates(nums []int) int {
	lenth := len(nums)
	if lenth == 0 {
		return 0
	}
	slow := 1
	for fast := 1; fast < lenth; fast++ {
		if nums[fast] != nums[fast-1] {
			nums[slow] = nums[fast]
			slow++
		}
	}
	return slow
}

// 56. 合并区间：
// 以数组 intervals 表示若干个区间的集合，其中单个区间为 intervals[i] = [starti, endi] 。
// 请你合并所有重叠的区间，并返回一个不重叠的区间数组，该数组需恰好覆盖输入中的所有区间。可以先对区间数组按照区间的起始位置进行排序，
// 然后使用一个切片来存储合并后的区间，遍历排序后的区间数组，将当前区间与切片中最后一个区间进行比较，如果有重叠，则合并区间；如果没有重叠，则将当前区间添加到切片中。
func merge(intervals [][]int) [][]int {

	n := len(intervals)
	if n == 0 {
		return nil
	}

	// 按照区间起始进行排序
	sort.Slice(intervals, func(i, j int) bool {
		return intervals[i][0] < intervals[j][0]
	})
	fmt.Println(intervals)

	//初始化排序结果
	res := [][]int{intervals[0]}

	for _, interval := range intervals[1:] {
		//结果数组的最后一个区间
		last := res[len(res)-1]

		//当前区间的起始 <= 前一个区间的结束时间，说明重叠
		if interval[0] < last[0] {
			//合并区间，结束时间取两者较大值
			res[len(res)-1][1] = maxVal(last[1], interval[1])
		} else {
			// 无重叠，直接加入结果数组
			res = append(res, interval)
		}

	}
	return res

}

func maxVal(a, b int) int {
	if a > b {
		return a
	}
	return b
}
