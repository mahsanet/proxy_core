package main

import "C"
import (
	Sserver "segment/server"
)

//export GRPCSERVER
func GRPCSERVER() bool {
	return Sserver.StartGRPCServer()
}

//export ENFORCE_BINDING
func ENFORCE_BINDING() {
}

func main() {
	GRPCSERVER()
	Sserver.WaitForServer()
}
