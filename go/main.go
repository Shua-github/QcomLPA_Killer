package main

import (
    "bytes"
    "encoding/hex"
    "flag"
    "fmt"
    "io/ioutil"
    "log"
    "os"
)

func main() {
    inputPath := flag.String("i", "", "input file path (required)")
    outputPath := flag.String("o", "", "output file path (optional)")
    hexFind := flag.String("h", "", "hex string to find (required)")
    hexPatch := flag.String("p", "", "hex string to patch (optional)")

    flag.Parse()

    if *inputPath == "" || *hexFind == "" {
        flag.Usage()
        os.Exit(1)
    }

    findBytes, err := hex.DecodeString(*hexFind)
    if err != nil {
        log.Fatalf("invalid hex string to find: %v", err)
    }

    var patchBytes []byte
    if *hexPatch != "" {
        patchBytes, err = hex.DecodeString(*hexPatch)
        if err != nil {
            log.Fatalf("invalid hex string to patch: %v", err)
        }
        if len(patchBytes) != len(findBytes) {
            log.Fatalf("patch hex length must be equal to find hex length")
        }
    }

    data, err := ioutil.ReadFile(*inputPath)
    if err != nil {
        log.Fatalf("read input file failed: %v", err)
    }

    found := bytes.Contains(data, findBytes)
    if !found {
        fmt.Println("false")
        os.Exit(1)
    }

    // 只检查，不修补
    if *outputPath == "" || *hexPatch == "" {
        fmt.Println("true")
        os.Exit(0)
    }

    // 修补替换
    replaced := replaceAll(data, findBytes, patchBytes)

    err = ioutil.WriteFile(*outputPath, replaced, 0644)
    if err != nil {
        fmt.Println("false")
        os.Exit(1)
    }

    fmt.Println("true")
}

func replaceAll(data, find, patch []byte) []byte {
    var result []byte
    index := 0

    for {
        i := bytes.Index(data[index:], find)
        if i == -1 {
            result = append(result, data[index:]...)
            break
        }
        result = append(result, data[index:index+i]...)
        result = append(result, patch...)
        index += i + len(find)
    }
    return result
}
