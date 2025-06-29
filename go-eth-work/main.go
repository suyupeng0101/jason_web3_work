package main

import (
	"context"
	"crypto/ecdsa"
	"fmt"
	"github.com/ethereum/go-ethereum/accounts/abi/bind/v2"
	"github.com/ethereum/go-ethereum/common"
	"github.com/ethereum/go-ethereum/core/types"
	"github.com/ethereum/go-ethereum/crypto"
	"github.com/ethereum/go-ethereum/ethclient"
	"go-eth-work/token"
	"log"
	"math/big"
)

var rawurl = "https://sepolia.infura.io/v3/"

var privateHexKey = ""

var transferToAddress = ""

// 合约地址
const (
	contractAddr = ""
)

func main() {

	// 查询区块
	//SearchBlock()

	// 转账
	//TransferETH()

	// 操作合约
	OptContract()
}

// 操作合约

func OptContract() {
	// 连接以太坊节点
	client, err := ethclient.Dial(rawurl)
	if err != nil {
		log.Fatal(err)
	}

	// 实例化 合约绑定对象，
	counterContract, err := token.NewToken(common.HexToAddress(contractAddr), client)
	if err != nil {
		log.Fatal(err)
	}

	// 加载私钥
	privateKey, err := crypto.HexToECDSA(privateHexKey)
	if err != nil {
		log.Fatal(err)
	}
	// 构建交易签名对象
	opt := bind.NewKeyedTransactor(privateKey, big.NewInt(11155111))

	// 发送交易：调用 increment()
	tx, err := counterContract.Increment(opt)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("increment tx hash:", tx.Hash().Hex())

	// 调用只读方法：get()
	//    使用 CallOpts（不需要签名）
	val, err := counterContract.Get(&bind.CallOpts{Context: context.Background()})
	if err != nil {
		log.Fatal(err)
	}
	fmt.Println("current count:", val) // uint256 类型
}

// ETH转账

func TransferETH() {

	// 连接区块链
	client, err := ethclient.Dial(rawurl)
	if err != nil {
		log.Fatal(err)
	}

	// 获取私钥
	privateKey, err := crypto.HexToECDSA(privateHexKey)
	if err != nil {
		log.Fatal(err)
	}

	// 获取公钥
	publicKey := privateKey.Public()

	// 将公钥转为地址
	publicKeyECDSA, ok := publicKey.(*ecdsa.PublicKey)
	if !ok {
		log.Fatal("error casting public key to ECDSA")
	}

	fromAddress := crypto.PubkeyToAddress(*publicKeyECDSA)

	// 获取 nonce
	nonce, err := client.PendingNonceAt(context.Background(), fromAddress)

	// 准备转账参数
	value := big.NewInt(1000000000000000)
	gasPrice, err := client.SuggestGasPrice(context.Background())
	if err != nil {
		log.Fatal(err)
	}
	gasLimit := uint64(25999)

	// 指定交易的接受者地址
	toAddress := common.HexToAddress(transferToAddress)

	// 交易的附加数据
	data := []byte("hello world")

	// 构建交易
	tx := types.NewTransaction(nonce, toAddress, value, gasLimit, gasPrice, data)

	// 获取网络 Chain ID，用于 EIP-155 交易签名链重放保护
	chainID, err := client.NetworkID(context.Background())
	if err != nil {
		log.Fatal(err)
	}

	// 使用私钥和 EIP-155 签名器对交易进行签名
	signedTx, err := types.SignTx(tx, types.NewEIP155Signer(chainID), privateKey)
	if err != nil {
		log.Fatal(err) // 签名失败则记录错误并退出程序
	}

	// 将签名发送到网络
	err = client.SendTransaction(context.Background(), signedTx)
	if err != nil {
		log.Fatal(err)
	}

	// 打印交易哈希，用户可以用该哈希查询交易状态
	fmt.Printf("tx sent: %s", signedTx.Hash().Hex())
}

// 查询区块

func SearchBlock() {

	// 连接区块链
	client, err := ethclient.Dial(rawurl)
	if err != nil {
		log.Fatal(err)
	}

	// 指定区块高度
	blockNumber := big.NewInt(5671749)

	// 查询指定区块
	block, err := client.BlockByNumber(context.Background(), blockNumber)
	if err != nil {
		log.Fatal(err)
	}

	// 打印区块信息
	fmt.Printf("Block hash: %d\n", block.Hash().Hex())
	fmt.Printf("Block timestamp: %d\n", block.Time())

	// 获取区块交易数量
	count, err := client.TransactionCount(context.Background(), block.Hash())
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Number of transactions: %d\n", count)
}
