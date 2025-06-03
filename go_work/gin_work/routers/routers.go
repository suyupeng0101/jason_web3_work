package routers

import (
	"gin_work/controller"
	"gin_work/toolkit"
	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	// 用户路由
	// 注册用户相关的注册、登录、注销的路由
	UserGroup := r.Group("user")
	{
		// 用户登录的路由
		UserGroup.POST("/login", controller.UserLoginHandler)
		// 用户注册的路由
		UserGroup.POST("/register", controller.UserRegisterHandler)
	}
	// 博客路由
	BlogGroup := r.Group("blog").Use(toolkit.TokenAuthMiddleware())
	{
		// 新建博客的路由
		BlogGroup.POST("/create", controller.CreateBlogHandler)
		// 更新博客的路由
		BlogGroup.POST("/update/id=:id", controller.UpdateBlogHandler)
		// 删除博客的路由
		BlogGroup.DELETE("/delete/id=:id", controller.DeleteBlogHandler)
		// 查看所有博客的路由
		BlogGroup.GET("/list", controller.GetAllBlogsHandler)
		// 查看单个博客的路由
		BlogGroup.GET("/list/id=:id", controller.GetBlogByIdHandler)
		// 博客关键词搜索
		BlogGroup.GET("/search/query=:query", controller.SearchBlogsHandler)
	}

	// 评论路由
	// 注册评论相关的新建、删除、查看的路由
	// 同时利用验证中间件来验证身份
	CommentGroup := r.Group("comment").Use(toolkit.TokenAuthMiddleware())
	{
		// 新建评论的路由
		CommentGroup.POST("/add", controller.CommentsAddHandler)
		// 查看指定博客所有评论的路由
		CommentGroup.GET("/list/id=:id", controller.CommentGetHandler)
		// 删除指定的评论
		CommentGroup.DELETE("/delete/id=:id", controller.CommentDeleteHandler)
	}
	return r
}
