package response

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

var codeMap = map[int]string{
	1001: "权限错误",
	1002: "角色错误",
}

type Response struct {
	Code int    `json:"code"`
	Msg  string `json:"message"`
	Data any    `json:"data"`
}

func response(c *gin.Context, code int, msg string, data any) {
	c.JSON(http.StatusOK, Response{
		Code: code,
		Data: data,
		Msg:  msg,
	})
}

func OK(c *gin.Context, data any, msg string) {
	response(c, 200, msg, data)
}

func OkWithData(c *gin.Context, data any) {
	OK(c, data, "成功")
}

func OkWithMsg(c *gin.Context, msg string) {
	OK(c, gin.H{}, "成功")
}

func Fail(c *gin.Context, code int, data any, msg string) {
	response(c, code, msg, data)
}

func FailWithMsg(c *gin.Context, msg string) {
	response(c, 1001, msg, nil)
}

func FailWithCode(c *gin.Context, code int) {
	msg, ok := codeMap[code]
	if !ok {
		msg = "服务错误"
	}
	response(c, code, msg, nil)
}
