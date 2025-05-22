package main

import (
	"fmt"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

var mysqlLogger logger.Interface

func init() {
	username := "root"
	password := "roor"
	host := "127.0.0.1"
	port := 3306
	Dbname := "gorm"
	timeout := "10s"

	//设置日志级别
	mysqlLogger = logger.Default.LogMode(logger.Info)

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&Local&timeout=%s", username, password, host, port, Dbname, timeout)

	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		panic("连接数据库失败，error=" + err.Error())
	}

	//连接成功
	DB = db
	//打印日志
	DB = DB.Session(&gorm.Session{Logger: mysqlLogger})
}
