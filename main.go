package main

import (
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/docker/go-plugins-helpers/volume"
)

const glusterfsID = "_glusterfs"

var (
	version  string
	revision string
	date     string
)

var (
	pVersion     = flag.Bool("version", false, "Version of Docker Volumen GlusterFS")
	pDefaultDir  = filepath.Join(volume.DefaultDockerRootDirectory, glusterfsID)
	pServersList = flag.String("servers", "", "List of glusterfs servers")
	pRestAddress = flag.String("rest", "", "URL to glusterfsrest api")
	pGfsBase     = flag.String("gfs-base", "/mnt/gfs", "Base directory where volumes are created in the cluster")
	pRoot        = flag.String("root", pDefaultDir, "GlusterFS volumes root directory")
)

func main() {
	var Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s [options]\n", os.Args[0])
		flag.PrintDefaults()
	}

	flag.Parse()
	if *pVersion {
		banner()
		os.Exit(0)
	}
	if len(*pServersList) == 0 {
		Usage()
		os.Exit(1)
	}

	servers := strings.Split(*pServersList, ":")

	d := newGlusterfsDriver(*pRoot, *pRestAddress, *pGfsBase, servers)
	h := volume.NewHandler(d)
	fmt.Println(h.ServeUnix("glusterfs", 0))
}

func banner() {
	fmt.Println("       __           __                            __                   ")
	fmt.Println("  ____/ /___  _____/ /_____  _____   _   ______  / /_  ______ ___  ___ ")
	fmt.Println(" / __  / __ \\/ ___/ //_/ _ \\/ ___/  | | / / __ \\/ / / / / __ `__ \\/ _ \\")
	fmt.Println("/ /_/ / /_/ / /__/ ,< /  __/ /      | |/ / /_/ / / /_/ / / / / / /  __/")
	fmt.Println("\\__,_/\\____/\\___/_/|_|\\___/_/       |___/\\____/_/\\__,_/_/ /_/ /_/\\___/ ")
	fmt.Println("                       __           __            ____                 ")
	fmt.Println("                ____ _/ /_  _______/ /____  _____/ __/____             ")
	fmt.Println("               / __ `/ / / / / ___/ __/ _ \\/ ___/ /_/ ___/             ")
	fmt.Println("              / /_/ / / /_/ (__  ) /_/  __/ /  / __(__  )              ")
	fmt.Println("              \\__, /_/\\__,_/____/\\__/\\___/_/  /_/ /____/               ")
	fmt.Println("             /____/                                                    ")
	fmt.Println()
	fmt.Println("Version  : ", version)
	fmt.Println("Revision : ", revision)
	fmt.Println("Date     : ", date)
	fmt.Println()
}
