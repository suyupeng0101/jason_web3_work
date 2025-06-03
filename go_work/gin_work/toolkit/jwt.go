package toolkit

import (
	"gin_work/response"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v4"
	"time"
)

// 设置密钥

var jwtKey = []byte("secret_key")

//Claims 是一个结构体，继承jwt.StandardClaim

type Claims struct {
	Username string `json:"username"`
	jwt.RegisteredClaims
}

// 生成JWT
func GenerateToken(username string) (string, error) {
	//设置令牌过期时间
	expirationTime := time.Now().Add(24 * time.Hour)

	claims := &Claims{
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
		},
	}

	//加密身份
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(jwtKey)
	return tokenString, err
}

// TokenAuthMiddleware 设置中间件验证请求头中的令牌

func TokenAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取验证请求头中的信息
		tokenString := c.GetHeader("Authorization")

		claims := &Claims{}
		token, err := jwt.ParseWithClaims(tokenString, claims, func(token *jwt.Token) (interface{}, error) {
			return jwtKey, nil
		})

		// 如果有错误或者token无效
		if err != nil || !token.Valid {
			response.FailWithMsg(c, "Unauthorized")
			c.Abort()
			return
		}

		c.Set("Username", claims.Username)
		c.Next()
	}
}
