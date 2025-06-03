package dao

import (
	"fmt"
	"gin_work/setting"
	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/mysql"
)

var (
	DB            *gorm.DB
	MySQLUser     string
	MySQLPassword string
	MySQLHost     string
	MySQLPort     int
	MySQLDb       string
)

func InitMySQL(cfg *setting.MySQLConfig) (err error) {
	// 首先配置数据库连接设置
	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=utf8mb4&parseTime=True&loc=Local",
		cfg.User, cfg.Password, cfg.Host, cfg.Port, cfg.DB)
	// 连接数据库
	DB, err = gorm.Open("mysql", dsn)
	if err != nil {
		fmt.Printf("err :%v\n", err)
		return
	}
	// 返回数据库连接信息
	return DB.DB().Ping()
}

func Close() {
	err := DB.Close()
	if err != nil {
		return
	}
}
