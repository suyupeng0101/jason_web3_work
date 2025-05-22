package main

// 定义与数据库表对应的结构体
//type Book struct {
//	ID     uint    `gorm:"primaryKey"`
//	Title  string  `gorm:"type:varchar(100)"`
//	Author string  `gorm:"type:varchar(50)"`
//	Price  float64 `gorm:"type:decimal(10,2)"`
//}
//
//func main() {
//	// 自动迁移表结构（如果表不存在则创建）
//	//DB.AutoMigrate(&Book{})
//	//编写Go代码，使用Sqlx执行一个复杂的查询，例如查询价格大于 50 元的书籍，
//	//并将结果映射到 Book 结构体切片中，确保类型安全。
//	// 执行复杂查询
//	var bookList []Book
//	DB.Model(&Book{}).Where("price > ?", 50.00).Find(&bookList)
//
//	for _, book := range bookList {
//		fmt.Printf("《%s》- %s ￥%.2f\n", book.Title, book.Author, book.Price)
//	}
//}
