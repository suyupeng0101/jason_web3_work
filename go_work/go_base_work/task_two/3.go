package task_two

import (
	"fmt"
	"math"
)

//面向对象,
//题目 ：定义一个 Shape 接口，包含 Area() 和 Perimeter() 两个方法。然后创建 Rectangle 和 Circle 结构体，实现 Shape 接口。在主函数中，创建这两个结构体的实例，并调用它们的 Area() 和 Perimeter() 方法。
//考察点 ：接口的定义与实现、面向对象编程风格。

type Shape interface {
	Area() float64

	Perimeter() float64
}

type Rectangle struct {
	Width  float64
	Height float64
}

type Circle struct {
	Radius float64
}

func (t *Rectangle) Area() float64 {
	return t.Height * t.Width
}

func (t *Rectangle) Perimeter() float64 {
	return 2 * (t.Width + t.Height)
}

func (c *Circle) Area() float64 {
	return math.Pi * c.Radius * c.Radius
}

func (c *Circle) Perimeter() float64 {
	return 2 * math.Pi * c.Radius
}

// 调用
func method5() {
	var rec Rectangle = Rectangle{
		Width:  10,
		Height: 20,
	}

	fmt.Printf("Rectangle area: %f\n", rec.Area())
	fmt.Printf("Rectangle perimeter: %f\n", rec.Perimeter())

	var cir Circle = Circle{
		Radius: 10,
	}

	fmt.Printf("Circle area: %f\n", cir.Area())
	fmt.Printf("Circle perimeter: %f\n", cir.Perimeter())

}

//题目 ：使用组合的方式创建一个 Person 结构体，包含 Name 和 Age 字段，再创建一个 Employee 结构体，组合 Person 结构体并添加 EmployeeID 字段。为 Employee 结构体实现一个 PrintInfo() 方法，输出员工的信息。
//考察点 ：组合的使用、方法接收者。

type Person struct {
	Name string
	Age  int
}

type Employee struct {
	Person
	EmployeeID int
}

// 为Employee实现信息打印方法
func (e *Employee) PrintInfo() {
	fmt.Printf("员工信息：\n姓名: %s\n年龄: %d\n工号: %s\n",
		e.Name, // 直接访问嵌入结构的字段
		e.Age,
		e.EmployeeID)
}

// 调用
func method6() {
	// 创建员工实例（包含完整初始化）
	emp := Employee{
		Person: Person{
			Name: "王小明",
			Age:  28,
		},
		EmployeeID: 13,
	}

	// 调用组合结构体的方法
	emp.PrintInfo()
}
