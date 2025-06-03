package models

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"gin_work/dao"
)

type User struct {
	UserId   int    `json:"userId" gorm:"PRIMARY_KEY;AUTO_INCREMENT"`
	UserName string `json:"userName" gorm:"UNIQUE"`
	Password string `json:"password"`
	Email    string `json:"email"`
}

// 新建用户
func CreateUser(user *User) (err error) {

	//根据userName判断当前用户是否存在。如果存在则不能创建

	err = dao.DB.Where("user_name = ?", user.UserName).First(user).Error
	if user.UserId != 0 {
		return errors.New("user exists")
	}
	user.Password, err = hashPassword(user.Password)
	err = dao.DB.Create(user).Error
	return nil
}

//通过username/pw获取用户

func GetUserBy(user *User) (err error) {
	var userDB User

	err = dao.DB.Where("user_name = ?", user.UserName).First(&userDB).Error
	//用户不存在
	if userDB.UserId == 0 {
		return errors.New("user not found")
	}
	//加密密码
	user.Password, err = hashPassword(user.Password)
	if userDB.Password != user.Password {
		// 重新定义错误
		return errors.New("incorrect password")
	}
	// 密码正确
	*user = userDB
	return nil
}

// 加密密码
func hashPassword(password string) (string, error) {
	// 定义一个全局的pepper，这个pepper应该来自配置文件或者环境变量，并且要保密
	pepper := "MyFixedSalt123！"
	// 将pepper添加到密码中
	passwordWithPepper := password + pepper
	hash := sha256.New()
	hash.Write([]byte(passwordWithPepper))
	hashedBytes := hash.Sum(nil)
	hashedPassword := hex.EncodeToString(hashedBytes)
	return hashedPassword, nil
}
