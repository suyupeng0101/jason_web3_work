package task_two

import (
	"fmt"
	"sync"
	"time"
)

//Channel,
//题目 ：编写一个程序，使用通道实现两个协程之间的通信。一个协程生成从1到10的整数，并将这些整数发送到通道中，另一个协程从通道中接收这些整数并打印出来。
//考察点 ：通道的基本使用、协程间通信。,

func receive(ch <-chan int) {
	for v := range ch {
		fmt.Printf("接收数据为 %d \n", v)
	}
}

func send(ch chan<- int) {
	for i := 1; i <= 10; i++ {
		ch <- i
		fmt.Printf("发送: %d\n", i)
	}
	close(ch)
}

func method7() {
	ch := make(chan int, 10)

	// 启动发送goroutine
	go send(ch)

	// 启动接收goroutine
	go receive(ch)

	// 使用select进行多路复用
	timeout := time.After(2 * time.Second)

	for {
		select {
		case v, ok := <-ch:
			if !ok {
				fmt.Println("通道已关闭")
				return
			}
			fmt.Printf("接收到的数据：%d\n", v)

		case <-timeout:
			fmt.Println("操作超时")
			return

		default:
			fmt.Println("没有数据，等待中...")
			time.Sleep(500 * time.Millisecond)
		}
	}
}

//题目 ：实现一个带有缓冲的通道，生产者协程向通道中发送100个整数，消费者协程从通道中接收这些整数并打印。
//考察点 ：通道的缓冲机制。

func method8() {
	//创建缓存通道
	ch := make(chan int, 10)
	var wg sync.WaitGroup

	//生产者协成
	wg.Add(1)
	go func() {
		defer wg.Done()
		for i := 1; i <= 100; i++ {
			ch <- i
		}
		close(ch)
	}()

	//消费者协成
	wg.Add(1)
	go func() {
		defer wg.Done()
		for num := range ch {
			fmt.Printf("接收值: %d\n", num)
		}
	}()
	// 等待所有协程完成
	wg.Wait()
	fmt.Println("所有数据处理完成")
}
