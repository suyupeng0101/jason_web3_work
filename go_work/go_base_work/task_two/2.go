package task_two

import (
	"fmt"
	"sync"
	"time"
)

//Goroutine

// 题目 ：编写一个程序，使用 go 关键字启动两个协程，一个协程打印从1到10的奇数，另一个协程打印从2到10的偶数。
// 考察点 ： go 关键字的使用、协程的并发执行。,
// @TODO 记得要增加sync.WaitGroup
func method3() {
	var wg sync.WaitGroup // WaitGroup用于等待goroutine完成
	wg.Add(2)             // WaitGroup计数器设为2（两个goroutine）

	go func() {
		defer wg.Done() // goroutine结束时通知WaitGroup计数器减1

		for i := 1; i <= 10; i += 2 { //直接遍历奇数：1,3,5,7,9
			fmt.Printf("第一个协程: %d\n", i)
		}
	}()

	go func() {
		defer wg.Done() // goroutine结束时通知WaitGroup计数器减1

		for i := 2; i <= 10; i += 2 { //直接遍历偶数：2,4,6,8,10
			fmt.Printf("第二个协程: %d\n", i)
		}
	}()

	wg.Wait() //等待所有goroutine完成再返回
}

//题目 ：设计一个任务调度器，接收一组任务（可以用函数表示），并使用协程并发执行这些任务，同时统计每个任务的执行时间。
//考察点 ：协程原理、并发任务调度。

// 定义任务类型（函数类型）
type Task func()

// 任务执行结果结构
type Result struct {
	TaskID    int
	Duration  time.Duration
	StartTime time.Time
}

// 模拟执行
func method4() {
	//创建任务集合（包括3个不同耗时的任务）
	tasks := []Task{
		func() { time.Sleep(1 * time.Second) },
		func() { time.Sleep(2 * time.Second) },
		func() { time.Sleep(1500 * time.Millisecond) },
	}

	//创建带缓冲区的结果通道（容量等于任务数量）
	resultChan := make(chan Result, len(tasks))

	var wg sync.WaitGroup

	//启动协程执行每个任务
	for taskID, task := range tasks {
		wg.Add(1)
		go func(id int, t Task) {
			defer wg.Done()
			start := time.Now()
			t() //执行任务
			resultChan <- Result{
				TaskID:    id,
				Duration:  time.Since(start),
				StartTime: start,
			}
		}(taskID, task)
	}
	// 启动监听协程关闭结果通道
	go func() {
		wg.Wait()
		close(resultChan)
	}()
	// 收集并输出结果
	fmt.Println("任务执行统计：")
	for result := range resultChan {
		fmt.Printf("任务ID: %d | 开始时间: %s | 耗时: %v\n",
			result.TaskID,
			result.StartTime.Format("15:04:05.000"),
			result.Duration.Round(time.Millisecond))
	}
}
