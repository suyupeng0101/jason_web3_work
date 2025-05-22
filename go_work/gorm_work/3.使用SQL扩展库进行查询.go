package main

//type Employee struct {
//	ID         uint
//	Name       string
//	Department string
//	Salary     int
//}

//func main() {
//
//	//创建表
//	//DB.AutoMigrate(&Employee{})
//
//	//编写Go代码，使用Sqlx查询 employees 表中所有部门为 "技术部" 的员工信息，
//	//并将结果映射到一个自定义的 Employee 结构体切片中。
//	var emps []Employee
//	DB.Where("department = ?", "技术部").Find(&emps)
//	fmt.Println(emps)
//
//	//编写Go代码，使用Sqlx查询 employees 表中工资最高的员工信息，并将结果映射到一个 Employee 结构体中。
//
//	var emp Employee
//	DB.Order("salary desc").Limit(1).Find(&emp)
//	fmt.Println(emp)
//}
