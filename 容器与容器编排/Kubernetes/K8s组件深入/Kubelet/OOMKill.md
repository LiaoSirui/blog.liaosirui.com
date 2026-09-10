	// runc requires cgroupv2 for unified mode
	if isCgroup2UnifiedMode() && !ptr.Deref(m.singleProcessOOMKill, true) {
		resources.Unified = map[string]string{
			// Ask the kernel to kill all processes in the container cgroup in case of OOM.
			// See memory.oom.group in https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html for
			// more info.
			"memory.oom.group": "1",
		}
	}

<https://github.com/kubernetes/kubernetes/blob/v1.33.6/pkg/kubelet/kuberuntime/kuberuntime_container_linux.go#L311-L319>

进程组（Group）级清理： 将 `memory.oom.group` 设置为 `1` 时，如果组内任一进程触发 OOM，内核会结束整个 cgroup（如一个容器）内的所有进程

```bash
# 调整前
find /sys/fs/cgroup/kubepods.slice/kubepods-podaee531bf_b09e_45c5_811e_e9f0e2b33805.slice/ \
  -name memory.oom.group \
  -exec sh -c 'echo "--- {} ---"; cat {}' \;
# --- /sys/fs/cgroup/kubepods.slice/kubepods-podaee531bf_b09e_45c5_811e_e9f0e2b33805.slice/cri-containerd-a36e4d03e1e152b90dd155abafff987b1978136e3eb923488b8e1c7155672801.scope/memory.oom.group ---
# 0
# --- /sys/fs/cgroup/kubepods.slice/kubepods-podaee531bf_b09e_45c5_811e_e9f0e2b33805.slice/cri-containerd-d4ec867f3f8ee929f1ba9466f52af2d4f99760699ee57514011c567b0eac272c.scope/memory.oom.group ---
# 0
# --- /sys/fs/cgroup/kubepods.slice/kubepods-podaee531bf_b09e_45c5_811e_e9f0e2b33805.slice/memory.oom.group ---
# 0

# 调整后
find /sys/fs/cgroup/kubepods.slice/kubepods-pod05ac998a_baee_4b63_a305_d27731dd186a.slice/ \
  -name memory.oom.group \
  -exec sh -c 'echo "--- {} ---"; cat {}' \;
# --- /sys/fs/cgroup/kubepods.slice/kubepods-pod05ac998a_baee_4b63_a305_d27731dd186a.slice/cri-containerd-6f774baa7b5bb0b77d83c42a790d7b00c2058b6f2ee9293221baa50a7dea11e0.scope/memory.oom.group ---
# 1
# --- /sys/fs/cgroup/kubepods.slice/kubepods-pod05ac998a_baee_4b63_a305_d27731dd186a.slice/memory.oom.group ---
# 0
# --- /sys/fs/cgroup/kubepods.slice/kubepods-pod05ac998a_baee_4b63_a305_d27731dd186a.slice/cri-containerd-a2d3c5ef5ac7fce22a5bdb8905b14f689ac0eabbef648bbab361ccd79d47e2a4.scope/memory.oom.group ---
# 0
```

