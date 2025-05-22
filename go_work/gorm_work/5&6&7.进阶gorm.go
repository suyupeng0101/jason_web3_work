package main

import (
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type User struct {
	ID        uint
	Name      string
	PostCount int64  `gorm:"default:0"`
	Posts     []Post `gorm:"foreignKey:UserID"`
}

type Post struct {
	ID       uint
	Title    string
	UserID   uint
	Comments []Comment `gorm:"foreignKey:PostID"`
	Status   string
}

type Comment struct {
	ID      uint
	Content string
	PostID  uint
}

// 为 Post 模型添加一个钩子函数，在文章创建时自动更新用户的文章数量统计字段。
func (p *Post) AfterCreate(tx *gorm.DB) (err error) {
	//g更新用户的文章数量统计字段
	err = tx.Model(&User{}).Where("id = ?", p.UserID).UpdateColumn("post_count", gorm.Expr("post_count+1")).Error
	return
}

// 为 Comment 模型添加一个钩子函数，在评论删除时检查文章的评论数量，如果评论数量为 0，则更新文章的评论状态为 "无评论"。
func (c *Comment) AfterDelete(tx *gorm.DB) (err error) {
	println("AfterDelete", c.ID, c.Content, c.PostID)
	var count int64
	err = tx.Model(&Comment{}).
		Where("post_id = ?", c.PostID).
		Count(&count).Error
	if err != nil {
		return err
	}
	if count == 0 {
		return tx.Model(&Post{}).
			Where("id = ?", c.PostID).
			Update("status", "无评论").Error
	}
	return nil
}

func main() {
	//创建表
	//DB.AutoMigrate(&User{}, &Post{}, &Comment{})
	//插入数据
	//DB.Create(&User{
	//	Name: "王五",
	//	Posts: []Post{
	//		{
	//			Title:    "文章6",
	//			Comments: []Comment{{Content: "评论1111"}},
	//		},
	//		{
	//			Title:    "文章7",
	//			Comments: []Comment{{Content: "评论3333"}},
	//		},
	//	},
	//})
	//DB.Create(&Post{
	//	Title:  "文章7",
	//	UserID: 3,
	//})

	var comment Comment
	DB.Take(&comment, 9)
	DB.Clauses(clause.Returning{}).Delete(&comment)
	// 删除评论时使用 Returning 保留 c.PostID，使 AfterDelete 能读取

	//查询某个用户发布的所有文章及其对应的评论信息。
	//var user User
	//DB.Preload("Posts.Comments").Take(&user, 3)
	//fmt.Println(user)

	//查询评论数量最多的文章信息。
	//var post Post
	//
	//sub := DB.Model(&Comment{}).
	//	Select("post_id").
	//	Group("post_id").
	//	Order("COUNT(*) DESC").
	//	Limit(1)
	//err := DB.Preload("Comments").
	//	Where("id = (?)", sub).
	//	First(&post).Error
	//if err != nil {
	//	panic(fmt.Sprintf("method3 error: %v", err))
	//}
	//fmt.Println(post)

	//
}
