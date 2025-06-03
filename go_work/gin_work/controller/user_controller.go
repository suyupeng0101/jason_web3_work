package controller

import (
	"gin_work/models"
	"gin_work/response"
	"gin_work/toolkit"
	"github.com/gin-gonic/gin"
)

//用户注册

func UserRegisterHandler(c *gin.Context) {
	//根据 json信息绑定结构体
	var user models.User
	err := c.BindJSON(&user)
	if err != nil {
		return
	}
	//创建用户
	err = models.CreateUser(&user)
	if err != nil {
		response.FailWithMsg(c, "user already exists")
	} else {
		response.OkWithMsg(c, "register successfully")
	}
	return
}

//用户登录

func UserLoginHandler(c *gin.Context) {
	var user models.User
	err := c.BindJSON(&user)
	if err != nil {
		return
	}
	//校验用户信息
	err = models.GetUserBy(&user)
	if err != nil {
		response.FailWithMsg(c, "user not found")
		return
	}

	//生成JWT
	token, err := toolkit.GenerateToken(user.UserName)
	if err != nil {
		response.FailWithMsg(c, "token generate failed")
		return
	}
	response.OkWithData(c, token)
}
