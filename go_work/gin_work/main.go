package main

import (
	"fmt"
	"gin_work/dao"
	"gin_work/models"
	"gin_work/routers"
	"gin_work/setting"
	"net/http"
	"os"
)

func HelloHandler(w http.ResponseWriter, r *http.Request) {
	_, err := fmt.Fprintf(w, "Hello")
	if err != nil {
		return
	}
}

// 设置基础配置
const defaultConfFile = "./conf/config.ini"

func main() {
	confFile := defaultConfFile
	if len(os.Args) > 2 {
		fmt.Println("use specified conf file: ", os.Args[1])
		confFile = os.Args[1]
	} else {
		fmt.Println("no configuration file was specified, use ./conf/config.ini")
	}
	// 加载配置文件
	if err := setting.Init(confFile); err != nil {
		fmt.Printf("load config from file failed, err:%v\n", err)
		return
	}
	// 连接数据库
	err := dao.InitMySQL(setting.Conf.MySQLConfig)
	if err != nil {
		fmt.Printf("init mysql failed,err:%v\n", err)
		return
	}
	defer dao.Close() // 程序退出关闭数据库连接
	// 根据模型创建数据库表项
	dao.DB.AutoMigrate(&models.User{}, &models.Blog{}, &models.Comment{})

	// 启动gin服务
	r := routers.SetupRouter()

	// 在指定端口上启动web服务
	if err := r.Run(fmt.Sprintf(":%d", setting.Conf.Port)); err != nil {
		fmt.Printf("server startup failed, err:%v\n", err)
	}
}
