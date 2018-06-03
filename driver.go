package main

import (
	"errors"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"

	"github.com/amarkwalder/docker-volume-glusterfs/rest"
	"github.com/docker/go-plugins-helpers/volume"
)

type volumeName struct {
	name        string
	connections int
}

type glusterfsDriver struct {
	root       string
	restClient *rest.Client
	servers    []string
	volumes    map[string]*volumeName // store only mounted volumes
	m          *sync.Mutex
}

func newGlusterfsDriver(root, restAddress, gfsBase string, servers []string) glusterfsDriver {
	d := glusterfsDriver{
		root:    root,
		servers: servers,
		volumes: map[string]*volumeName{},
		m:       &sync.Mutex{},
	}
	if len(restAddress) > 0 {
		d.restClient = rest.NewClient(restAddress, gfsBase)
	}
	return d
}

func (d glusterfsDriver) Create(r *volume.CreateRequest) error {
	log.Printf("Creating volume %s\n", r.Name)
	d.m.Lock()
	defer d.m.Unlock()
	m := d.mountpoint(r.Name)

	if _, ok := d.volumes[m]; ok {
		return nil
	}

	if d.restClient != nil {
		exist, err := d.restClient.VolumeExist(r.Name)
		if err != nil {
			return err
		}

		if !exist {
			// TODO custom options
			if err := d.restClient.CreateVolume(r.Name, d.servers); err != nil {
				return err
			}
		}
		return nil
	} else {
		return errors.New("Creating Volume failed (no rest endpoint on glusterfs)")
	}
}

func (d glusterfsDriver) Remove(r *volume.RemoveRequest) error {
	log.Printf("Removing volume %s\n", r.Name)
	d.m.Lock()
	defer d.m.Unlock()
	m := d.mountpoint(r.Name)

	if _, ok := d.volumes[m]; !ok {
		if d.restClient != nil {
			if err := d.restClient.DeleteVolume(r.Name); err != nil {
				return err
			}
			return nil
		}
		return errors.New("Removing volume failed (no rest endpoint on glusterfs)")
	}
	return errors.New("Removing volume failed : volume in use")
}

func (d glusterfsDriver) Path(r *volume.PathRequest) (*volume.PathResponse, error) {
	return &volume.PathResponse{Mountpoint: d.mountpoint(r.Name)}, nil
}

func (d glusterfsDriver) Mount(r *volume.MountRequest) (*volume.MountResponse, error) {
	d.m.Lock()
	defer d.m.Unlock()
	m := d.mountpoint(r.Name)
	log.Printf("Mounting volume %s on %s\n", r.Name, m)

	if s, ok := d.volumes[m]; ok {
		s.connections++
		return &volume.MountResponse{Mountpoint: m}, nil
	}

	fi, err := os.Lstat(m)

	if os.IsNotExist(err) {
		if err := os.MkdirAll(m, 0755); err != nil {
			return &volume.MountResponse{}, err
		}
	} else if err != nil {
		return &volume.MountResponse{}, err
	}

	if fi != nil && !fi.IsDir() {
		return &volume.MountResponse{}, errors.New(fmt.Sprintf("%v already exist and it's not a directory", m))
	}

	if err := d.mountVolume(r.Name, m); err != nil {
		return &volume.MountResponse{}, err
	}

	d.volumes[m] = &volumeName{name: r.Name, connections: 1}

	return &volume.MountResponse{Mountpoint: m}, nil
}

func (d glusterfsDriver) Unmount(r *volume.UnmountRequest) error {
	d.m.Lock()
	defer d.m.Unlock()
	m := d.mountpoint(r.Name)
	log.Printf("Unmounting volume %s from %s\n", r.Name, m)

	if s, ok := d.volumes[m]; ok {
		s.connections--
		if s.connections == 0 {
			if err := d.unmountVolume(m); err != nil {
				return err
			}
			if err := os.RemoveAll(m); err != nil {
				return err
			}
			delete(d.volumes, m)
		}

	} else {
		return errors.New(fmt.Sprintf("Unable to find volume mounted on %s", m))
	}

	return nil
}

func (d glusterfsDriver) Get(r *volume.GetRequest) (*volume.GetResponse, error) {
	d.m.Lock()
	defer d.m.Unlock()
	m := d.mountpoint(r.Name)
	if s, ok := d.volumes[m]; ok {
		return &volume.GetResponse{Volume: &volume.Volume{Name: s.name, Mountpoint: d.mountpoint(s.name)}}, nil
	}

	if d.restClient != nil {
		exist, err := d.restClient.VolumeExist(r.Name)
		if err != nil {
			return &volume.GetResponse{}, err
		}
		if exist {
			return &volume.GetResponse{Volume: &volume.Volume{Name: r.Name}}, nil
		}
	}

	return &volume.GetResponse{}, errors.New(fmt.Sprintf("Unable to find volume mounted on %s", m))
}

func (d glusterfsDriver) List() (*volume.ListResponse, error) {
	d.m.Lock()
	defer d.m.Unlock()
	var vols []*volume.Volume

	if d.restClient != nil {
		respVolumes, err := d.restClient.Volumes()
		if err != nil {
			return &volume.ListResponse{}, err
		}
		for _, v := range respVolumes {
			vols = append(vols, &volume.Volume{Name: v.Name})
		}
	} else {
		for _, v := range d.volumes {
			vols = append(vols, &volume.Volume{Name: v.name, Mountpoint: d.mountpoint(v.name)})
		}
	}
	return &volume.ListResponse{Volumes: vols}, nil
}

func (d *glusterfsDriver) mountpoint(name string) string {
	return filepath.Join(d.root, name)
}

func (d *glusterfsDriver) mountVolume(name, destination string) error {
	var serverNodes []string
	for _, server := range d.servers {
		serverNodes = append(serverNodes, fmt.Sprintf("-s %s", server))
	}

	cmd := fmt.Sprintf("glusterfs --volfile-id=%s %s %s", name, strings.Join(serverNodes[:], " "), destination)
	if out, err := exec.Command("sh", "-c", cmd).CombinedOutput(); err != nil {
		log.Println(string(out))
		return err
	}
	return nil
}

func (d *glusterfsDriver) unmountVolume(target string) error {
	cmd := fmt.Sprintf("umount %s", target)
	if out, err := exec.Command("sh", "-c", cmd).CombinedOutput(); err != nil {
		log.Println(string(out))
		return err
	}
	return nil
}

func (d glusterfsDriver) Capabilities() *volume.CapabilitiesResponse {
	var res volume.CapabilitiesResponse
	res.Capabilities = volume.Capability{Scope: "global"}
	return &res
}
