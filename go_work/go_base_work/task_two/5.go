package task_two

import (
	"fmt"
	"sync"
	"sync/atomic"
	"time"
)

//锁机制,
//题目 ：编写一个程序，使用 sync.Mutex 来保护一个共享的计数器。启动10个协程，每个协程对计数器进行1000次递增操作，最后输出计数器的值。
//考察点 ： sync.Mutex 的使用、并发数据安全。,

// 计数器
type Counter struct {
	m     sync.Mutex
	count int
}

// 计数器增加
func (c *Counter) Increment() {
	c.m.Lock()
	defer c.m.Unlock()
	c.count++
}

// 获取值
func (c *Counter) GetValue() int {
	c.m.Lock()
	defer c.m.Unlock()
	return c.count
}

func method9() {

	counter := &Counter{
		count: 0,
	}

	//启动10个协成
	for i := 0; i < 10; i++ {
		go func() {
			//进行1000次操作
			for j := 0; j < 1000; j++ {
				counter.Increment()
			}
		}()
	}

	time.Sleep(time.Second)
	// 输出最终计数
	fmt.Printf("Final count: %d\n", counter.GetValue())
}

//题目 ：使用原子操作（ sync/atomic 包）实现一个无锁的计数器。
//启动10个协程，每个协程对计数器进行1000次递增操作，最后输出计数器的值。
//考察点 ：原子操作、并发数据安全。

func method10() {

	var counter int32
	var wg sync.WaitGroup

	//启动10个生产者协成
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			// 每个协程执行1000次原子递增
			for j := 0; j < 1000; j++ {
				atomic.AddInt32(&counter, 1)
			}
		}()
	}
	wg.Wait()

	//原子获取最终值
	final := atomic.LoadInt32(&counter)
	fmt.Printf("Final count: %d\n", final)

}
