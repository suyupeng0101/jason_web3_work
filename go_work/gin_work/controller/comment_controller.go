package controller

import (
	"gin_work/models"
	"gin_work/response"
	"github.com/gin-gonic/gin"
	"strconv"
)

// 评论新增
func CommentsAddHandler(c *gin.Context) {
	var comments models.Comment
	err := c.BindJSON(&comments)
	err = models.CreateComment(&comments)

	if err != nil {
		response.FailWithMsg(c, "增加评论失败")
	} else {
		response.OkWithMsg(c, "新增成功")
	}
}

// 获取评论列表
func CommentGetHandler(c *gin.Context) {

	blogId, ok := c.Params.Get("id")

	if !ok {
		response.FailWithMsg(c, "参数错误")
	}
	blogIdiot, _ := strconv.Atoi(blogId)
	var commentList []models.Comment
	err := models.GetComment(blogIdiot, &commentList)

	if err != nil {
		response.FailWithMsg(c, "<UNK>")
	} else {
		response.OkWithData(c, commentList)
	}
}

// 删除评论
func CommentDeleteHandler(c *gin.Context) {
	id, ok := c.Params.Get("id")

	if !ok {
		response.FailWithMsg(c, "参数错误")
	}
	idiot, _ := strconv.Atoi(id)

	err := models.DelComment(idiot)
	if err != nil {
		response.FailWithMsg(c, err.Error())
	} else {
		response.OkWithMsg(c, "删除成功")
	}
}
