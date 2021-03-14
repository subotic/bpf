package main

import (
	"bytes"
	"encoding/binary"
	"fmt"
	bpf "github.com/iovisor/gobpf/bcc"
	"os"
	"os/signal"
)

const source string = `
#include <uapi/linux/ptrace.h>

struct readline_event_t {
	u32  pid;
	char str[80];
} __attribute__((packed));

BPF_PERF_OUTPUT(readline_events);

int get_return_value(struct pt_regs *ctx) {
	struct readline_event_t event = {};
	u32 pid;
	if (!PT_REGS_RC(ctx))
		return 0;
	pid = bpf_get_current_pid_tgid();
	event.pid = pid;
	bpf_probe_read(&event.str, sizeof(event.str), (void *)PT_REGS_RC(ctx));
	readline_events.perf_submit(ctx, &event, sizeof(event));

	return 0;
}
`

type readlineEvent struct {
	Pid uint32
	Str [80]byte
}

func main() {
	m := bpf.NewModule(source, []string{})
	defer m.Close()

	readlineUretprobe, err := m.LoadUprobe("get_return_value")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to load get_return_value: %s\n", err)
		os.Exit(1)
	}

	err = m.AttachUretprobe("/bin/bash", "readline", readlineUretprobe, -1)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to attach return_value: %s\n", err)
		os.Exit(1)
	}

	table := bpf.NewTable(m.TableId("readline_events"), m)

	channel := make(chan []byte)

	perMap, err := bpf.InitPerfMap(table, channel, nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to init perf map: %s\n", err)
		os.Exit(1)
	}

	sig := make(chan os.Signal, 1)
	signal.Notify(sig, os.Interrupt, os.Kill)

	fmt.Printf("%10s\t%s\n", "PID", "COMMAND")
	go func() {
		var event readlineEvent
		for {
			data := <-channel
			err := binary.Read(bytes.NewBuffer(data), binary.LittleEndian, &event)
			if err != nil {
				fmt.Printf("failed to decode received data: %s\n", err)
				continue
			}
			// Convert C string (null-terminated) to Go string
			comm := string(event.Str[:bytes.IndexByte(event.Str[:], 0)])
			fmt.Printf("%10d\t%s\n", event.Pid, comm)
		}
	}()

	perMap.Start()
	<-sig
	perMap.Stop()
}
